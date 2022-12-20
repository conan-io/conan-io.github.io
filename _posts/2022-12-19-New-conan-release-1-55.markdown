---
layout: post
comments: false
title: "Conan 1.55: CMakeDeps can now customize its dependencies target names, files and types, new tools.build:compiler_executables conf, new NMakeDeps and NMakeToolchain integration, env-vars and conf enabled for editables"
meta_title: "Version 1.55 of Conan C++ Package Manager is Released" 
meta_description: "The new version features includes CMakeDeps can now customize its dependencies target names, files and types, new tools.build:compiler_executables conf and much more..."
---

We are pleased to announce that [Conan 1.55 is
out](https://github.com/conan-io/conan/releases/tag/1.55.0) and comes with some
significant new features and bug fixes. First, CMakeDeps provides the ability to set the
properties on the consumer side. Also, we added the new `tools.build:compiler_executables`
configuration to define the compiler's executable location in CMakeToolchain,
MesonToolchain, and AutoToolsToolchain. We improved integration with
[NMAKE](https://learn.microsoft.com/en-us/cpp/build/reference/nmake-reference) using the
[NMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#nmakedeps)
and
[NMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#nmaketoolchain)
generators. Finally, we enabled environment vars and configuration for use in editable
packages.


## CMakeDeps can now customize its properties

As you may know, Conan introduced the properties model a couple of releases ago to add a
generic way of passing certain information to generators. Conan uses this model for the
[new generators](https://docs.conan.io/en/latest/reference/conanfile/tools.html),
replacing the legacy `cpp_info` attributes like `cpp_info.names` and `cpp_info.filenames`
(you can check the migration guide from the legacy model
[here](https://docs.conan.io/en/latest/migrating_to_2.0/properties.html)). Before 1.55, it
was impossible to override the values set by the dependencies. For example, if a recipe
sets the `cmake_find_mode` to `both`, Conan would generate both config and module files
for every consumer of the recipe. This behaviour could be inconvenient for the consumers
for some cases.

Starting in 1.55, Conan enables overwritting from the consumer side the following
properties for CMakeDeps: `cmake_file_name`, `cmake_target_name`, `cmake_find_mode`,
`cmake_module_file_name` and `cmake_module_target_name`. Let's see an example of a recipe
that has
[zlib](https://github.com/conan-io/conan-center-index/blob/master/recipes/zlib/all/conanfile.py)
as a dependency.

If you check, for example, the zlib recipe in Conan Center, it defines several properties
for CMakeDeps in the `package_info()` method:

```python
...

def package_info(self):
    self.cpp_info.set_property("cmake_find_mode", "both")
    self.cpp_info.set_property("cmake_file_name", "ZLIB")
    self.cpp_info.set_property("cmake_target_name", "ZLIB::ZLIB")
...

```

Imagine you have an application that consumes zlib, and you want to change these
properties because you want to generate only *config files* and also you are using a
different target name for zlib in your CMakeLists.txt. Then you could use
`CMakeDeps.set_property` in the `generate()` method to override the values set in the zlib
recipe:


```python
from conan.tools.cmake import CMakeDeps

...

class ConsumerRecipe(ConanFile):

    ...

    def generate(self):
        deps = CMakeDeps(self)
        # We want to use zlib target name instead of ZLIB::ZLIB
        deps.set_property("zlib", "cmake_target_name", "zlib")
        # We invalidate whatever value the zlib recipe sets and fallback to
        # the default for Conan
        deps.set_property("zlib", "cmake_find_mode", None)

    ...
```

You can read more about the CMakeDeps set_property method in the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html#set-property).


## New tools.build:compiler_executables conf

We added the ``tools.build:compiler_executables`` configuration to set the location to the
compiler executables. This configuration defines a dictionary, with the language as the
key and the executable location as the value. For example, you could use this in a Conan
profile:

```ini
[settings]
os=Macos
arch=x86_64

[conf]
tools.build:compiler_executables={"cpp": "path_to_my_c++_compiler", "c": "path_to_my_c_compiler"}

This configuration will work for
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html),
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html)
and
[MesonToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesontoolchain.html):

- CMakeToolchain: defines the corresponding `CMAKE_<LANG>_COMPILER` variable for CMake.
  Check the list of accepted keys [in the
  docs](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html#conf)
- AutotoolsToolchain: defines the corresponding `CMAKE_<LANG>_COMPILER` variable for
  CMake. Check the list of accepted keys [in the
  docs](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html#conf)
- MesonToolchain: defines the corresponding environment variables (like `CC` or `CXX`
  Check the list of accepted keys [in the
  docs](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html#conf)

## NMakeDeps and NMakeToolchain generators

We improved integration with
[NMAKE](https://learn.microsoft.com/en-us/cpp/build/reference/nmake-reference) via
[NMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#nmakedeps)
and
[NMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#nmaketoolchain)
generators. These generators will generate environment scripts defining environment
variables for NMAKE to use when building:

- NMakeDeps defines `CL`, `LIB` and `_LINK_` environment variables, injecting necessary flags to
  locate and link the dependencies declared in requires
- NMakeToolchain defines `CL` environment variable, injecting necessary flags deduced from
  the Conan settings like `compiler.cppstd` or the Visual Studio runtime

## Enabled environment vars and configuration for use in editable packages

We fixed the case that may happen when you are in editable mode but need information that
the recipe sets in the `package_info()` method while developing. This can happen, for
example, in a package like this in editable mode:

```python

import os
from conan import ConanFile


class ConanPackage(ConanFile):

    ...

    def package_info(self):
        # This is BROKEN if we put this package in editable mode
        self.runenv_info.define_path("MYDATA_PATH", 
                                     os.path.join(self.package_folder, "my/data/path"))
```

This breaks if we are in editable mode as there's no package yet. For these cases we can
define it in the ``layout()`` method, in the same way the ``cpp_info`` can be defined
there. The ``layouts`` object contains ``source``, ``build`` and ``package`` scopes, and
each one contains one instance of ``buildenv_info``, ``runenv_info`` and ``conf_info``:

```python
from conan import ConanFile

class SayConan(ConanFile):
    ...
    def layout(self):
        # The final path will be relative to the self.source_folder
        self.layouts.source.buildenv_info.define_path("MYDATA_PATH", "my/source/data/path")
        # The final path will be relative to the self.build_folder
        self.layouts.build.buildenv_info.define_path("MYDATA_PATH2", "my/build/data/path")
        # The final path will be relative to the self.build_folder
        self.layouts.build.conf_info.define_path("MYCONF", "my_conf_folder")
```

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#nov-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
