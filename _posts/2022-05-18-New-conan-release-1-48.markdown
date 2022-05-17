---
layout: post
comments: false
title: "Conan 1.48: Improvements in CMakePresets integration, new Autotools templates, CMakeToolchain configuration support for bitcode, arc and visibility flags in Apple, support to generate env ps1 instead of bat in Windows."
meta_title: "Version 1.48 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include Improvements in CMakePresets integration, new Autotools templates and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.48 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.48 Conan C/C++ package manager version",
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
 "datePublished": "2022-05-17",
 "description": "Improvements in CMakePresets integration, new "conan new" autotools templates, CMakeToolchain configuration support for bitcode, arc and visibility flags in Apple, support to generate env ps1 instead of bat in Windows.",
 }
</script>

We are pleased to announce that Conan 1.48 has been released and brings some significant
new features and bug fixes. We have improved the CMakePresets integration. Also we have
added new "conan new" autotools templates. We added CMakeToolchain configuration for
bitcode, arc and visibility flags in Apple. This release also adds support to generate env
**.ps1** instead of **.bat** in Windows.


## Improvements in CMakePresets integration

Since Conan 1.47 we started to provide support for
[CMakePresets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html). This file
is used internally in Conan to pass information like the generator and toolchain file
location from the
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
to the [CMake build
helper](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html).
Besides this, using this file also improves the developer flow experience, when working
locally with Conan and CMake. Let's see an example of how to use this file with Visual
Studio Code with the [CMake
Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools)
installed.

Starting with a simple consumer project with this structure that uses the Zlib library:


```txt
├── CMakeLists.txt
├── conanfile.txt
└── src
    └── main.cpp
```

Where the **conanfile.txt** is just requiring *zlib/1.2.11* and adding the **CMakeDeps**
and **CMakeToolchain** generators:

```txt
[requires]
zlib/1.2.12

[generators]
CMakeDeps
CMakeToolchain
```

And the **CMakeLists.txt** is as simple as:

```cmake
cmake_minimum_required(VERSION 3.15)
project(compressor CXX)

find_package(ZLIB REQUIRED)

add_executable(${PROJECT_NAME} src/main.cpp)
target_link_libraries(${PROJECT_NAME} ZLIB::ZLIB)
```

The **main.cpp** code will just show wether we are using Debug or Release configuration
and the version of zlib.

```cpp
#include <iostream>

#include <zlib.h>

int main(void) {
    #ifdef NDEBUG
    std::cout << "Release!" << std::endl;
    #else
    std::cout << "Debug!" << std::endl;
    #endif
    std::cout << "Zlib version: " << zlibVersion() << std::endl;
    return 0;
}
```

Run the `conan install` command to install the *Zlib* dependency for both **Release** and
**Debug** configurations:

```bash
conan install . --build=missing
conan install . -s build_type=Debug --build=missing
```

After running this, Conan will generate a *CMakePresets.json* file. This file stores
different presets that you can select in Visual Studio Code. Select Release as the
configure preset:

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2022-05-18/vscode_select_preset.png" align="center" alt="Configure CMake"/>
</p>

And run the build:

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2022-05-18/vscode_run_the_build.png" align="center" alt="Build the project"/>
</p>

Now it's easy to change between presets to launch different build configurations.


## New "conan new" autotools templates

As you know, the `conan new` command is a practical way to [create a
template](https://docs.conan.io/en/latest/extending/template_system/command_new.html) for
a C++ project using Conan. Until Conan 1.48 there were templates for CMake, Meson, Bazel
and MSBuild. Now you can also use new templates to create a project example for both a
library and an executable with Conan using Autotools.

You try it using:

```bash
conan new hello/1.0 -m=autotools_lib 
conan new app/1.0 -m=autotools_lib 
```

To build the project, just run:

```bash
conan create .
```
 
If you want more built-in templates available in Conan, please do not hesitate to
contribute them to the [GitHub repository](https://github.com/conan-io/conan). Also,
remember that you can always use your own defined templates. Please [check the
documentation](https://docs.conan.io/en/latest/extending/template_system/command_new.html)
for more information.


## CMakeToolchain configuration support for bitcode, arc and visibility flags in Apple

This version adds support in
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
for the following
[conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html)
properties:

- ``tools.build:tools.apple:enable_bitcode`` boolean value to enable/disable Bitcode
  Apple. This will set the `CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE` and
  `CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE` CMake variables when using the CMake Xcode
  generator. If other generator is used, it will add the ``-fembed-bitcode`` flag to
  ``CMAKE_CXX_FLAGS`` and ``CMAKE_C_FLAGS``.

- ``tools.build:tools.apple:enable_arc`` boolean value to enable/disable ARC Apple Clang
  flags. This will set the `CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC` CMake variable
  when using the CMake Xcode generator. If other generator is used, it will add the
  ``-fobjc-arc`` or ``-fno-objc-arc`` flag to ``CMAKE_CXX_FLAGS`` and ``CMAKE_C_FLAGS``
.

- ``tools.build:tools.apple:enable_visibility`` This will set the
  `CMAKE_XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN` CMake variable when using the CMake
  Xcode generator. If other generator is used, it will add the ``-fvisibility`` flag to
  ``CMAKE_CXX_FLAGS`` and ``CMAKE_C_FLAGS``.


## Configuration to choose between bat or powershell scripts in Windows

This version brings a new configuration option to choose between bat or powershell scripts
generation. As you know, Conan
[Environment](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html)
class saves the information in a bat file by default in Windows. Now, setting the
`tools.env.virtualenv:powershell` to `True`, you can generate powershell scripts instead.
This will also apply to the
[VirtualBuildEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualbuildenv.html)
and
[VirtualRunEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualrunenv.html)
generators as they use the `Environment` class internally.

---

<br>

Besides the items listed above,
there were some minor bug fixes you may wish to
read about. If so
please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#may-2022) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
