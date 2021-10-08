---
layout: post
comments: false
title: "Conan 1.41: Better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, new cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe."
meta_title: "Version 1.41 of Conan C++ Package Manager is Released"
meta_description: "The new version features includes better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe and much more..."
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
 "datePublished": "2021-10-08",
 "description": "Better support for layout() local flows and editables, IntelOneAPI support, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe.",
 }
</script>

We are pleased to announce that Conan 1.41 is out and comes with some significant new features and
bug fixes. Local flows and editables are now easier using
[layout()](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html). Also, we
introduced support for [Intel's oneAPI Toolkits](https://www.oneapi.io/) with a new `intel-cc` compiler
setting. Also, lThe new environment supports now multi-configuration generators. We have added a new
`objects` attribute for the conanfile's
[cpp_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info) to support
object (_.obj_ and _.o_) files. Finally, from  this version, it's possible to use multiple different
toolchains like
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html),
[BazelToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html#bazeltoolchain), 
and
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
in the same recipe.

## Easier local flows and editable handling using layout()

For this release, we have fixed some issues regarding the new
[layout()](https://blog.conan.io/2021/06/10/New-conan-release-1-37.html) feature introduced in Conan
1.37. This feature makes it easier to work with packages in [editable
mode](https://docs.conan.io/en/latest/developing_packages/editable_packages.html) and also using the
[local development flow](https://docs.conan.io/en/latest/developing_packages/package_dev_flow.html).
Packages that are in editable mode make it possible for Conan to find dependencies in the local work
folder instead of in the Conan Cache, which allows faster workflows without the need of doing a ``conan create`` 
for each change in the sources of the package under development.

Imagine you are developing a package called `say` using CMake and you have this project structure:

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

Using the `layout()` feature we can describe the package contents so other projects consuming this
package can find it no matter if it's in the Conan cache or if the package is in editable mode and we
want to consume the libraries generated in the local work folder. Let's see how we set the values in
the conanfile's `layout()` method so that we can use this package. The conanfile of this package
could look like this:

```python
from conans import ConanFile
import os

class SayConan(ConanFile):
    name = "say"
    version = "0.1"
    exports_sources = "say_sources/CMakeLists.txt", "say_sources/*"
    ...
    def layout(self):
        self.folders.source = "./say_sources"
        build_type = str(self.settings.build_type).lower()
        self.folders.build = "cmake-build-{}".format(build_type)
        self.folders.generators = os.path.join(self.folders.build, "conan")

        self.cpp.package.libs = ["say"]
        self.cpp.package.includedirs = ["include"] # includedirs is already set to this value by 
                                                   # default, but declared for completion

        # self.cpp.source and self.cpp.build are used for editable mode
        # this information is relative to the source and build folders
        self.cpp.source.includedirs = ["hpp"]
        self.cpp.build.libdirs = ["."]
        self.cpp.build.bindirs = ["."]

    def build(self):
        ...
```

As we have our sources in the *say_sources* folder the `self.folders.source` is set to
`"./say_sources"`. Also, as we are using CMake for building we want to set the build folder to
`cmake-build-release` or `cmake-build-debug` depending on the `build_type`. The
`self.folders.generators` folder is where all Conan generated files will be stored so they don't
pollute the other folders.

Declaring `self.cpp.package.libs` inside the layout() method is equivalent to the classic
`self.cpp_info.libs` declaration in the `package_info()` method. Also, as you may know `self.cpp.package.includedirs` is set to
`["include"]` by default, there's no need in declaring it but we are leaving it for completion.
Setting that includedirs to `["include"]` means that consumers will try to find the `say.h` file in a
folder in the  cache that corresponds to
`/location/of/cache/data/say/0.1/_/_/package/<package_id>/include` when the package is not in editable mode 
but we don't have that structure in our local folder so we need a way to tell the `say` package consumers where to find the include
file when it's in editable mode. The way of setting that information are the `self.cpp.source` and
`self.cpp.build` attributes (that are [cpp_info objects](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info)):

- `self.cpp.source`: to set folders where the source files are (like include files) **relative to the `self.folders.source`**.
  That means that you don't have to set this to `say_sources/hpp`. The
  `self.folders.source` information will be automatically prepended to that path for consumers.
- `self.cpp.build`:  to set folders where the built files are (like libraries or binary files) **relative to the `self.folders.build`**. 
  As before, you don't have to prepend the build folder
  (`cmake-build-release` or `cmake-build-debug`).

The information set in `self.cpp.source` and `self.cpp.build` will be merged with the information set
in `self.cpp.package` so that  we don't have to declare again something like `self.cpp.build.libs = ["say"]` 
that is the same for the consumers independently of if the package is in editable mode or not.

With those declared, we could put the package in editable mode, build it and other package that
requires `say` would consume it in a completely transparent way.

Please, for a complete example on how to use editable packages and layout, check the [Conan
Examples](https://github.com/conan-io/examples/tree/master/features/editable/cmake) repository.

## Intel oneAPI support in Conan 1.41

Starting in this version you cant set the compiler setting to the `intel-cc` value to use the Intel
compilers from the Intel oneAPI toolkits. This setting has a mode sub-setting to define the actual
compiler you want to use from the [Base or HPC
Toolkits](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html#gs.d9m4rs).
It can take the following values:

- `icx`: Intel oneAPI C++ Compiler (icx/icpx)
- `dpcpp`: Intel oneAPI DPC++ Compiler (dpcpp)
- `classic`: Intel C++ Compiler Classic (icc/icpc for Linux/macOS and icl for Windows)

Check [the documentation](https://docs.conan.io/en/latest/howtos/intel_compiler.html#intel-cc) for
more information about those values and a complete explanation on how to use these tools with Conan.
Also, `IntelCC` has been added as generator for Conan. Please check more about this feature in the
[Conan documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/intel.html).

## Multi-config support for environment generators

Since [Conan 1.35](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html) [new
tools](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html) are available for managing
the environment. Now, the generated files for
[VirtualRunEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualbuildenv.html)
and
[VirtualBuildEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualrunenv.html)
take the ``build_type`` and ``arch`` settings into account for the names of the launcher files to
improve the integration with multi-configuration generators. Then, calling to ``conan install
cmake/3.20.0@ -g VirtualBuildEnv --build-require -s build_type=Release`` for example will create a
file called ``conanbuildenv-release-x86_64.sh`` and will not be overwriten for other ``build_type``
value.

Also, now it is possible to group the generated environment variables launcher scripts under
different names. By deafault they are all aggregated to the group ``build`` for
[Environment](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html) and
``VirtualeBuildEnv`` and group ``run`` for ``VirtualRunEnv`` leading to a
``conan(build/run).(sh/bat)`` script that sets all the declared enviornments. Now declaring something
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
be later consumed by packages that declare the dependency. Let's see an example:

We create a Linux package `pkg/1.0` that builds and packages one _myobject.obj_ file. The same way
you would declare the libraries that must be consumed by packages that depend on `pkg/1.0` setting
the `cpp_info.libs` attribute you can declare that this library packages some object files that the
consumers need to add. This can be done setting that information in the package_info of the
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

Then, when this package is consumed by other using the `CMakeDeps` generator, the path of that object
will added to the target so that the consumer can link against that _myobject.obj_ file.


## Use different toolchains in the same recipe

We have added the argument _namespace_ to the new tools helpers for
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html),
[Bazel](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html) and
[Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html). This arguments
provides the possibility of using more than one toolchain in the same recipe, for example, when parts
of the same package are built with different build systems. With this argument the generated
intermediate files for the toolchains helpers will not collide and will be possible to see something
like this in the recipes if necessary:

```python
  from conans import ConanFile
  from conan.tools.gnu import AutotoolsToolchain, Autotools
  from conan.tools.google import BazelToolchain, Bazel
  from conan.tools.cmake import CMakeToolchain, CMake
  class Conan(ConanFile):
      settings = "os", "arch", "compiler", "build_type"
      def generate(self):
          autotools = AutotoolsToolchain(self, namespace='autotools')
          autotools.generate()
          bazel = BazelToolchain(self, namespace='bazel')
          bazel.generate()
          cmake = CMakeToolchain(self, namespace='cmake')
          cmake.generate()

      def build(self):
          autotools = Autotools(self, namespace='autotools')
          autotools.configure()
          autotools.make()
          bazel = Bazel(self, namespace='bazel')
          bazel.configure()
          bazel.build(label="//main:hello-world")
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
