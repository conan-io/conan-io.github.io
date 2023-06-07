---
layout: post
comments: false
title: "Conan 1.41: Better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, new cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe."
description: "The new version features includes better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.41 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.41 Conan C/C++ package manager version",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Conan Team", 
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan release", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
},
 "datePublished": "2021-10-14",
 "description": "Better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe.",
 }
</script>

We are pleased to announce that [Conan 1.41 is
out](https://github.com/conan-io/conan/releases/tag/1.41.0) and comes with some significant new
features and bug fixes. Local flows and [editable
packages](https://docs.conan.io/en/latest/developing_packages/editable_packages.html) are now easier
to handle using [layout()](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html).
We introduced support for [Intel's oneAPI Toolkits](https://www.oneapi.io/) with a new
`intel-cc` compiler setting. Also, the new environment supports multi-configuration generators now.
We have added a new `objects` attribute in the conanfile's
[cpp_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info) to provide
object files (_.obj_ and _.o_) with which consumers can link. Finally, from  this version, it's
possible to use multiple different toolchains like
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html),
[BazelToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html#bazeltoolchain),
and
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
in the same recipe.

## Easier local flows and editable packages handling using layout()

For this release, we have fixed some issues regarding the new
[layout()](https://blog.conan.io/2021/06/10/New-conan-release-1-37.html) feature introduced in Conan
1.37. This feature makes it easier to work with packages in [editable
mode](https://docs.conan.io/en/latest/developing_packages/editable_packages.html) and use the [local
development flow](https://docs.conan.io/en/latest/developing_packages/package_dev_flow.html). When a
package is in editable mode, Conan looks for its contents in the local work folder instead of the
Conan local cache. That way, you can rebuild your package locally so the packages that depend on this editable
package will link with the updated package without needing a ``conan create`` command for each change
in the sources.

Let's suppose you are developing a package called `say` using CMake and you have this project structure:

```
.
├── conanfile.py
└── say_sources
    ├── CMakeLists.txt
    ├── cpp
    │   └── say.cpp
    └── hpp
        └── say.h
```

Using the `layout()` feature, we can describe the package contents so consumers of this package can
find it no matter if we are working in “regular” (find contents in Conan cache) or editable mode
(find contents in local working folder). Let's see how we set those values in the `layout()` method
so that the `say` package is found in both cases. The conanfile of this package could look like this:

```python
from conans import ConanFile
import os

class SayConan(ConanFile):
    name = "say"
    version = "0.1"
    exports_sources = "say_sources/*"
    ...
    def layout(self):
        self.folders.source = "say_sources"
        build_type = str(self.settings.build_type).lower()
        self.folders.build = "cmake-build-{}".format(build_type)
        self.folders.generators = os.path.join(self.folders.build, "conan")

        self.cpp.package.libs = ["say"]
        self.cpp.package.includedirs = ["include"] # includedirs is already set to this value by 
                                                   # default, but declared for completion

        # self.cpp.source and self.cpp.build are used for editable mode
        # this information is relative to the source and build folders
        self.cpp.source.includedirs = ["hpp"] # maps to ./say_sources/hpp
        self.cpp.build.libdirs = ["."]        # maps to ./cmake-build-<build_type>
        self.cpp.build.bindirs = ["."]        # maps to ./cmake-build-<build_type>

    def build(self):
        ...
```

We can set several attributes in the [layout()](https://docs.conan.io/en/latest/reference/conanfile/methods.html#layout) method, for example, those related to where the sources are and where we want to build the package:
  - As we have our sources in the *say_sources* folder, `self.folders.source` is set to
  `"./say_sources"`. 
  - We are using CMake for building, so we want to set the build folder to
  `cmake-build-release` or `cmake-build-debug` depending on the `build_type`. 
  - The `self.folders.generators` folder is where all files generated by Conan will be stored so they don't
  pollute the other folders.

Please, note that the values above are for a single-configuration CMake generator. To support
multi-configuration generators, such as Visual Studio, you should make some changes to this layout. For
a complete layout that supports both single-config and multi-config please check the
[cmake_layout()](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)
in the Conan documentation.

Also, we can set the information about the package that the consumers need to use by setting
the conanfile's
[cpp.package](https://docs.conan.io/en/latest/developing_packages/package_layout.html#self-cpp)
attributes values:
  - Declaring `self.cpp.package.libs` inside the `layout()` method is equivalent to the "classic"
    `self.cpp_info.libs` declaration in the `package_info()` method. 
  - Also, as you may know, `self.cpp.package.includedirs` is set to `["include"]` [by
    default](https://docs.conan.io/en/latest/reference/conanfile/attributes.html?highlight=includedirs#cpp-info),
    so there's no need in declaring it but we are leaving it here for completeness.

Setting `self.cpp.package.includedirs` to `["include"]` means that, when the package is not in
editable mode, consumers will try to find the `say.h` file in a folder in the cache that corresponds
to something similar to this:

```
/location/of/cache/data/say/0.1/_/_/package/<package_id>/include
```

As you can see, we don't have that structure in our local folder so we need a way to tell the `say` package consumers where to find the include file there when it's in editable mode. We can set that information using the conanfile's `cpp.source` and
`cpp.build` attributes (which are [cpp_info objects](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info)):

  - `self.cpp.source`: to set folders where the source files are (like include files) **relative to the `self.folders.source`**.
  In this example we are setting `self.cpp.source.includedirs = ["hpp"]`. The `self.folders.source` information will be automatically prepended to that path for consumers so Conan will try to get the include files from the `./say_sources/hpp` folder.
  - `self.cpp.build`:  to set folders where the built files are (like libraries or binary files) **relative to the `self.folders.build`**. 
  As before, you don't have to prepend the build folder (`cmake-build-release` or `cmake-build-debug`) and if we set the `self.cpp.build.libdirs` and `self.cpp.build.bindirs` to `["."]`, Conan will try to find libraries and binaries in the `./cmake-build-<build_type>` folder.

Note that the information set in `self.cpp.source` and `self.cpp.build` will be merged with the information set
in `self.cpp.package` so that  we don't have to declare again something like `self.cpp.build.libs = ["say"]` 
that is the same for the consumers independently of if the package is in editable mode or not.

With those declared, we could put the package in editable mode, build it and other packages that
require `say` would consume it in a completely transparent way.

Please, for a complete example on how to use editable packages and layout, check the [Conan
Examples](https://github.com/conan-io/examples/tree/master/features/editable/cmake) repository.

## Intel oneAPI support in Conan 1.41

Starting in this version you can set the compiler setting to the `intel-cc` value to use the Intel
compilers from the Intel oneAPI toolkits. This setting has a mode sub-setting to define the actual
compiler you want to use from the [Base or HPC
Toolkits](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html#gs.d9m4rs).
It can take the [following values](https://docs.conan.io/en/latest/howtos/intel_compiler.html#intel-cc):

- `icx`: Intel oneAPI C++ Compiler (icx/icpx)
- `dpcpp`: Intel oneAPI DPC++ Compiler (dpcpp)
- `classic`: Intel C++ Compiler Classic (icc/icpc for Linux/macOS and icl for Windows)

Also, [IntelCC](https://docs.conan.io/en/latest/reference/conanfile/tools/intel.html#intelcc) has
been added as a generator for Conan. Please check more about this feature in the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/intel.html).

## Multi-config support for environment generators

Since [Conan 1.35](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html), [new
tools](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html) are available for managing
environments. Now, the generated files for
[VirtualRunEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualbuildenv.html)
and
[VirtualBuildEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualrunenv.html)
take the ``build_type`` and ``arch`` settings into account for the names of the launcher files to
improve the integration with multi-configuration generators. So, for example, calling to ``conan
install cmake/3.20.0@ -g VirtualBuildEnv --build-require -s build_type=Release`` for example will
create a file called ``conanbuildenv-release-x86_64.sh`` and will not be overwritten for other
``build_type`` values.

Also, now it is possible to group the generated environment variables launcher scripts under
different names. By default, they are all aggregated to the group ``build`` for
[Environment](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html) and
``VirtualeBuildEnv`` and group ``run`` for ``VirtualRunEnv`` leading to a
``conan(build/run).(sh/bat)`` script that sets all the declared environments. Now declaring something
like this in the conanfile:

```python
class PkgConan(ConanFile):
    ...
    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
        env1 = Environment(self)
        env1.define("env_name", "env1")
        env1.save_script("env1_launcher", group="mygroup")
        env2 = Environment(self)
        env2.define("env_name", "env2")
        env2.save_script("env2_launcher", group="mygroup")
        env3 = Environment(self)
        env2.define("env_name", "env3")
        env2.save_script("env3_launcher")
    ...
  ```

Will create a `conanmygroup.sh` file to set both `env1` and `env2` and a default `conanbuild.sh` that will
only set `env3` variables.


## Define object files in cpp_info.objects new attribute

Starting in Conan 1.41 you can set a list of object files (_.obj_ and _.o_) in the
[cpp_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info) `objects`
attribute. This attribute is only compatible with the
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) generator
for the moment. It will add the declared objects to the generated CMake target so those objects can
be later consumed by packages that declare the dependency.

Let's suppose we create a Linux package `pkg/1.0` that builds and packages one _myobject.obj_ file. The same way
you would declare the libraries that must be consumed by packages that depend on `pkg/1.0` setting
the `cpp_info.libs` attribute, you can declare that this library packages some object files that the
consumers need to add. This can be done by setting that information in the [package_info()](https://docs.conan.io/en/latest/reference/conanfile/methods.html#method-package-info) method of the
conanfile:

```python
class Pkg(ConanFile):
    name = 'pkg'
    version = '1.0'
    ...
    def package_info(self):
        self.cpp_info.objects = ['lib/myobject.o']
    ...
```

Then, when this package is consumed by other packages using the `CMakeDeps` generator, the path of that object
will be added to the target so the consumers can link against that _myobject.obj_ file.


## Use different toolchains in the same recipe

New toolchains create a file named __conanbuild.conf__ to pass certain information to the build
helpers. The filename was the same for all the toolchains causing a collision problem when a recipe
used different build systems. Conan 1.41 provides a new argument _namespace_ to the build helpers for
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html),
[Bazel](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html), and
[Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html). This argument makes
it possible to use more than one toolchain in the same recipe, for example, when parts of the same
package build with different build systems. Set this value to append the namespace to the filename
(like __conanbuild_namespace.conf__), generating a unique name for each tool. A conanfile using this
argument for the tools could look like this:

```python
  from conans import ConanFile
  from conan.tools.gnu import AutotoolsToolchain, Autotools
  from conan.tools.google import BazelToolchain, Bazel
  from conan.tools.cmake import CMakeToolchain, CMake
  
  class Conan(ConanFile):
      settings = "os", "arch", "compiler", "build_type"
      def generate(self):
          # generates conanbuild_autotools.conf
          autotools = AutotoolsToolchain(self, namespace='autotools')
          autotools.generate() 
          
          # generates conanbuild_bazel.conf
          bazel = BazelToolchain(self, namespace='bazel')
          bazel.generate()     
          
          # generates conanbuild_cmake.conf
          cmake = CMakeToolchain(self, namespace='cmake')
          cmake.generate()     

      def build(self):
          # reads conanbuild_autotools.conf
          autotools = Autotools(self, namespace='autotools')
          autotools.configure() 
          autotools.make()
          
          # reads conanbuild_bazel.conf
          bazel = Bazel(self, namespace='bazel')
          bazel.configure()    
          bazel.build(label="//main:hello-world")
          
          # reads conanbuild_bazel.conf
          cmake = CMake(self, namespace='cmake')
          cmake.configure()   
          cmake.build()
  ```

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#oct-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
