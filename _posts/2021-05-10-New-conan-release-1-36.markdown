---
layout: post 
comments: false 
title: "Conan 1.36 : Multiple CMake enhancements, New cpp_info property system, 
Support build_requires testing in test_package, New --build exclude syntax" 
meta_title: "Version 1.36 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.36 brings several enhancements, better CMake
integration, new property system for cpp_info, the ability to test
build_requirements, and the ability to exclude packages from build policy."
---

Conan 1.36 brings several significant enhancements, including several different
enhancements to
[`CMake`](https://docs.conan.io/en/latest/integrations/build_system/cmake.html)
integration, a new property strategy for certain values in the `cpp_info` data
structure, a first-class mechanism for testing packages which are used as
`build_requires`, and the ability to exclude specific packages from Conan
builds.

## New CMake Integration Enhancements

There were a number of `CMake`-related features in this release, but the
ordering of the notes in the changelog is somewhat random. So, here is a summary
of the all improvements and additions related to CMake integration:

### CMakeDeps

* Improved tracing by printing each declared target

### CMakeToolchain

* New extensibility model of "Blocks" replacing inheritance
* Support for setting any msvc toolset with any MSVC version
* CMake Generator now automatically deduced from Compiler settings
* Support for choosing Ninja CMake generator

The new "Blocks" extensibility model used in the `CMakeToolchain` is probably
the most significant of these changes, so we'll focus on that for this post.

Since Conan was created, there has always been a number of outstanding requests
from users to customize the outputs of generators. There have been a number of
suggestions and POCs done using various strategies to provide this capability,
but none ever made it through review until now. In this release, with the
CMakeToolchain generator, we're debuting a model in which the generator
internally builds its output as a dictionary-like data structure with named
"Blocks" of templated content.

The first outstanding group of feature requests this addresses is the common
desire to use built-in generators, but remove certain parts of the generated
content. Previously, people have used `tools.replace_in_file` or similar
approaches to surgically remove unwanted content from the generated output
before the build. This approach had many unwanted consequences. Now, the
`CMakeToolchain` class provides a first-class method for removing such blocks
**BEFORE** the generated output is written to disk.

        tc = CMakeToolchain(self)
        tc.pre_blocks.remove("generic_system")
        tc.generate()

The other major outstanding group of feature requests this approach addresses is
the desire to write much more customized generators for existing build systems,
while borrowing some of the valuable logic from the existing ones. With CMake
(more so than any other build system), the existing generators have years of
improvements and enhancements and domain knowledge from the community baked into
them, and they will continue to improve. For example, the Conan setting of
`compiler.libcxx` affects two different values which get sent to the compiler
under certain circumstances. First, it affects the `-stdlib` flag which must be
passed to some compilers (for example: `-stdlib=libstdc++`). Second, it affects
the `GLIBCXX_USE_CXX11_ABI` preprocessor definition which must be passed to some
compilers (for example: `-DGLIBCXX_USE_CXX11_ABI=1`). For Conan to handle all
compilers properly, the existing `CMakeToolchain` generator uses the following
highly-complicated logic:

    def context(self):
        libcxx = self._conanfile.settings.get_safe("compiler.libcxx")
        if not libcxx:
            return None
        compiler = self._conanfile.settings.compiler
        lib = glib = None
        if compiler == "apple-clang":
            # In apple-clang 2 only values atm are "libc++" and "libstdc++"
            lib = "-stdlib={}".format(libcxx)
        elif compiler == "clang":
            if libcxx == "libc++":
                lib = "-stdlib=libc++"
            elif libcxx == "libstdc++" or libcxx == "libstdc++11":
                lib = "-stdlib=libstdc++"
            # FIXME, something to do with the other values? Android c++_shared?
        elif compiler == "sun-cc":
            lib = {"libCstd": "Cstd",
                   "libstdcxx": "stdcxx4",
                   "libstlport": "stlport4",
                   "libstdc++": "stdcpp"
                   }.get(libcxx)
            if lib:
                lib = "-library={}".format(lib)
        elif compiler == "gcc":
            if libcxx == "libstdc++11":
                glib = "1"
            elif libcxx == "libstdc++":
                glib = "0"
        return {"set_libcxx": lib, "glibcxx": glib}

We know it is extremely common for enterprise teams to create their own `CMake`
generators which are VERY different than the built-in ones, however, it's very
likely that many of them may still want to handle the `compiler.libcxx` setting.
For those cases, we don't want anyone else to have to duplicate, maintain, test,
and/or update the logic above. So, the new blocks strategy makes it possible for
enterpise teams to just use the `GLibCXXBlock` class in Conan and obtain only
this block, without having to deal with the existing Generator at all.

Here is the complete list of blocks for the `CMakeToolchain` available at the
time of this writing.

* ``generic_system``
* ``android_system``
* ``ios_system``
* ``find_paths``
* ``fpic``
* ``rpath``
* ``arch_flags``
* ``libcxx``
* ``vs_runtime``
* ``cppstd``
* ``shared``
* ``parallel``

Please refer to the [CMakeToolchain
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html?highlight=cmake_generator_toolset#extending-and-customizing-cmaketoolchain)
for more details on what each of these blocks contains.

This "blocks" paradigm, and many many of these block names will likely be
propagated to other generators in the near future.  

## New `cpp_info` property system

The second-most significant feature in this release is certainly the new
`cpp_info` property system. Of note, this new property system does not impact
the core members of `cpp_info`, such as `includedirs`, `libdirs`, `libs`, etc.
It only affects a few values, so please refer to the [documentation of the
`cpp_info`
attribute](https://docs.conan.io/en/latest/reference/conanfile/attributes.html?highlight=cpp_info#cpp-info)
to understand the scope of this feature.

The `cpp_info` attribute of `conanfile.py` is a cornerstone of Conan, was
originally represented as a simple 2-dimensional dictionary-like object. This
had the nice characteristic of being declarative, and limited the complexity of
code in the Conan generators which would traverse it. However, in time,
as-always, it's not our programming models which determine the complexity of a
problem domain... the domain itself does. And, the complexity of dependency
information in C and C++ has gradually overcome the simplicity of a dictionary.

In time, more complex use cases came up, where recipe authors wanted to
customize the output filenames of the generators, and on a per-generator basis,
so `cpp_info` added a `filenames` member which was itself a dictionary:

    self.cpp_info.filenames["cmake_find_package"] = "MyFileName"
    self.cpp_info.filenames["cmake_find_package_multi"] = "MyFileName"

Also, recipes authors wanted to support the unique abstraction of `components`
in the `CMake` build system, so Conan extended `cpp_info` to support a similar
notation:

    self.cpp_info.components["mycomponent"].names["cmake_find_package"] = "mycomponent-name"
    self.cpp_info.components["mycomponent"].names["cmake_find_package_multi"] = "mycomponent-name"

Then came requests for a member called `build_modules`, and that also had to
support per-component definitions, resulting in this syntax:

    self.cpp_info.components["mycomponent"].build_modules.append(os.path.join("lib", "mypkg_bm.cmake"))

As the complexity of this data structure grew, it started to feel like we've
exceeded the appropriate use of the dictionary model for multiple reasons. For
example, there are multiple generators for the `CMake` build system, and we know
that development teams create their own as well. In most cases like the examples
above, authors want to set a value for "all `CMake*` generators". However, with
the dictionary model above, the key name is the generator name, so users had to
set values once for each known `CMake` generator, and that could really never
scale or work well with custom generators.

So, here is the new way to express the same information as the examples above,
but in a way which does not suffer the problem described above:

    self.cpp_info.set_property("cmake_file_name", "MyFileName")
    self.cpp_info.components["mycomponent"].set_property("cmake_target_name", "mycomponent-name")
    self.cpp_info.components["mycomponent"].set_property("cmake_build_modules", [os.path.join("lib", "mypkg_bm.cmake")])
    self.cpp_info.components["mycomponent"].set_property("custom_name", "mycomponent-name", "custom_generator")

The fundamental change is that the dictionary members for components can now
have named properties, and the generators can query those properties if/when
they need to add support for them. So, instead of defining `build_modules` once
for each possible `CMake` generator, we define a `cmake_build_modules` property
and any number of `CMake` generators can choose to add support for it, or ignore
it if appropriate.

In summary, this strategy makes the recipe more generic and less coupled to
supporting specific generators, and puts the onus on the recipe authors to
support known properties. Some built-in properties are already defined and used
in current generators, but this strategy also supports completely arbitrary
properties for custom-recipe and custom-generator use-cases. For that reason, we
think this feature will see extensive use in enterprise package environments.

## Support build_requires testing in test_package

Another long-standing request in the Conan community has been the ability to
write `test_package` logic which can properly test all the unique behaviors and
characteristics of `build_requires`.  Previously, the `test_package`
functionality was only really designed to test normal `requires`. The impact of
this limitation has grown over time. For example, in `ConanCenter`, the number
of packages used as `build_requires` has steadily increased, and because we have
not had an effective way to test them programatically, we've had more bugs with
`build_requires` packages, and had a harder time finding those bugs quickly.

Now, it's relatively trivial to create a `test_package` which validates that a
package will work properly as a `build_requires`. Simply add the following
attribute and Conan will invoke all the special behavior that it does for
`build_requirements` on the package, and test it against the `test_package`
recipe with that context.

    class MyBuildToolTestPackage(ConanFile):
        test_type = "build_requires"

That's it, just add the `test_type` attribute as shown above, and it should just
work.

## New –-build exclude syntax

The last feature we will talk about today is the new syntax for excluding
specific packages from the Conan build process. Once again, it answers some
long-outstanding feature requests, however this one is fairly simple to explain.

One of Conan's most novel features among package managers in general is the
`--build` flag. When calling `conan create` or `conan install`, callers can
specify precisely which packages in the graph they want to build from source,
and which ones they can use precompiled binaries for. Users had the following
syntactic options:

* `--build=all` or `--build`: all packages
* `--build=package_name` : a single specific package by name
* `--build=package_1 --build=package_2` : a list of specific packages
* `--build=missing` : the subset of packages which have no precompiled binaries
* `--build=pack*` : the subset of packages which match a glob expression

However, despite technically being able to handle every possible case, there was
just one situation which was still awkward. That is, specifying that you want to
build **ALL** packages **EXCEPT** one (or a few). To do this, you had to use
scripts outside of Conan to enumerate the entire list of packages in the graph
and then filter out the ones you want to exclude (which is non-trivial), and
then add each to the command-line as `--build=package_name`.

The problem is now solved. It's now trivial to specify you want to build all
packages except one (for example `zlib` as shown in the example below). You
simply prefix the pattern you want to exclude with an exclamation point just as
you would with the `exports` and `exports_sources` attributes in `conanfile.py`:

* `--build=!zlib --build=*`

This may seem like a small thing, but for those who wanted it, it will go a very
long way and eliminate a LOT of really undesirable script code outside of Conan.

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#May-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
