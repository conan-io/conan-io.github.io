---
layout: post
comments: false
title: "Conan 1.47: New [conf] to inject arbitrary C++ flags to packages, preliminary support for CMakePresets.json, new templates for MSBuild and Bazel, improvements in Meson support."
meta_title: "Version 1.47 of Conan C++ Package Manager is Released"
meta_description: "The new version includes new [conf] to inject arbitrary C++ flags to packages, preliminary support for CMakePresets.json, new templates for MSBuild and Bazel and much more."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.47 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.47 Conan C/C++ package manager version",
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
 "datePublished": "2022-04-21",
 "description": "Conan 1.47: New [conf] to inject arbitrary C++ flags to packages, preliminary support for CMakePresets.json, new templates for MSBuild and Bazel, improvements in Meson support.",
 }
</script>

We are pleased to announce that [Conan 1.47 is
out](https://github.com/conan-io/conan/releases/tag/1.47.0) and comes with some
significant new features and bug fixes. We added new [conf] values to inject C/C++ flags
and preprocessor definitions to packages. There is also preliminary support for
**CMakePresets.json** in
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
to generate necessary information for the [CMake build
helper](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html). We also 
added new templates in the `conan new` command to create examples of an application
and a library, one for the **Bazel** build system and another for **MSBuild**. It's also
worth noting significant improvements in Meson support, including Android cross-build.


## New [conf] to inject arbitrary C++ flags to packages

We added some new [conf] values to inject extra C/C++ flags and preprocessor definitions to the
build system (currently supported by
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html),
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html),
[MesonToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesontoolchain.html),
and
[XCodeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodetoolchain)).
The values you can set are:

 * `tools.build:cxxflags`: List of extra CXX flags.
 * `tools.build:cflags`: List of extra C flags.
 * `tools.build:defines`: List of extra preprocessor definitions.
 * `tools.build:sharedlinkflags`: List of flags that will be used by the linker when creating a shared library.
 * `tools.build:exelinkflags`: List of flags that will be used by the linker when creating an executable.

As with other
[configuration](https://docs.conan.io/en/latest/reference/config_files/global_conf.html)
items, their values can be set in the
[global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#global-conf)
file, in
[recipes](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#configuration-in-your-recipes),
in your
[profiles](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#configuration-in-your-profiles)
or using the `--conf` argument in the command line. In this case, the injection of values
composing profiles could be an interesting example. Imagine you create a **"sanitized"
profile** that adds some sanitizer flags to the builds to track the execution at runtime and report execution errors. That profile could look like this:

```txt
include(default)
[conf]
tools.build:cxxflags=["-fsanitize=address", "-fno-omit-frame-pointer"]
```

Then invoking Conan commands with that profile would inject these flags in every build:

```bash
conan create . -pr=./sanitized
```

## Preliminar support for CMakePresets.json

Now Conan uses a
[CMakePresets.json](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html) file
to pass certain information from the
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
to the [CMake build
helper](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html). When
the CMake build helper calls the `configure()` method, it will read this information from that file:

 * The generator to be used.
 * The path to the `conan_toolchain.cmake toolchain` toolchain file.
 * Some cache variables corresponding to the specified settings cannot work if specified in the toolchain.

It's also important to note that some IDEs like [Visual Studio and Visual Studio
Code](https://devblogs.microsoft.com/cppblog/cmake-presets-integration-in-visual-studio-and-visual-studio-code/)
and [CLion](https://www.jetbrains.com/help/clion/cmake-presets.html) have built-in support
for this file, so putting it next to your *CMakeList.txt* they will read it automatically
and know what generator and toolchain to use for building.


## New Bazel and MSBuild templates for conan new

The `conan new` command is practical to [create a
template](https://docs.conan.io/en/latest/extending/template_system/command_new.html) for
a C++ project using Conan. Until Conan 1.47 there were templates for CMake and
Meson. Now you can also use new templates to scaffold projects using [the Microsoft
Build Engine](https://docs.microsoft.com/es-es/visualstudio/msbuild/msbuild?view=vs-2022)
and [Bazel](https://bazel.build).

You can give them a try using:

```bash
# MSBuild
conan new hello/1.0 -m=msbuild_lib 
conan new app/1.0 -m=msbuild_lib 

# Bazel
conan new hello/1.0 -m=bazel_lib 
conan new app/1.0 -m=bazel_lib 
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


## Improvements in Meson support

There are a few significant improvements in Meson integration. The most important one
is adding support for cross-compilation for Android in the
[MesonToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesontoolchain.html). 

Please note that you should provide the location for your Android NDK path using the
`tools.android:ndk_path` configuration option. This path is used by the
'MesonToolchain* to point to the correct compiler and linker executables inside the
Android *NDK*. Conan will define the following variables for Meson:

 * `c`, `cpp`, `ar`: The Android *NDK* compiler executables under the `[binaries]` section.
 * `system`, `cpu_family`, `cpu`, `endian`: to define the host and build systems under the
   `[build_machine]` and `[host_machine]` sections.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#mar-2022) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
