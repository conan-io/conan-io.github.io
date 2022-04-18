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
 "datePublished": "2022-04-20",
 "description": "Conan 1.47: New [conf] to inject arbitrary C++ flags to packages, preliminary support for CMakePresets.json, new templates for MSBuild and Bazel, improvements in Meson support.",
 }
</script>

Conan 1.47 is out!
- New [conf] to inject arbitrary C++ flags to packages
- Meson Improvements , including Android cross-build
- Preliminar support for CMakePresets.json
- New Bazel templates
- Support for latest Xcode, iOS, etc
- New MSBuild templates

We are pleased to announce that [Conan 1.47 is
out](https://github.com/conan-io/conan/releases/tag/1.47.0) and comes with some
significant new features and bug fixes. We added new [conf] values to inject C/C++ flags
and preprocessor definitions to packages. There is also preliminary support added for
**CMakePresets.json** in
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
and [CMake build
helper](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html). We
added new templates for the command `conan new`, to generate examples of an application
and a library, one for the **Bazel** build system and another for **MSBuild**. It's also
worth noting significant improvements in Meson support, including Android cross-build.


## New [conf] to inject arbitrary C++ flags to packages


## Preliminar support for CMakePresets.json


## New Bazel and MSBuild templates for conan new

The `conan new` command is practical to create a template for a C++ project using Conan.
Until Conan 1.47 there were two built-in templates in Conan for CMake projects:
`cmake_lib` and `cmake_exe`. From this version, you can also use two new templates
to scaffold a project using [the Meson build system](https://mesonbuild.com/): `meson_lib`
and `meson_exe`.

If you have meson installed in your system, you can test it by running:

```bash
conan new hello/1.0 -m=meson_lib    
```

That will create a project with the following structure:

```bash
.
├── conanfile.py
├── meson.build
├── src
│   ├── hello.cpp
│   └── hello.h
└── test_package
    ├── conanfile.py
    ├── meson.build
    └── src
        └── example.cpp 
```

To build the project, just run:

```bash
conan create .
```
 
If you would like to see more built-in templates in Conan, please do not hesitate to
contribute them to the [GitHub repository](https://github.com/conan-io/conan). Also,
remember that you can always use your own defined templates. Please [check the
documentation](https://docs.conan.io/en/latest/extending/template_system/command_new.html)
for more information.


## Improvements in Meson support

Finally, there are a few improvements and fixes worth mentioning, like:

* Improve the
  [MesonToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesontoolchain.html)
  formatting of generated files and include some cross-building functionality.
* Document the
  [PkgConfigDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html)
  behaviour in the case that a component and the root `cpp_info` have the same name, the
  component `*.pc` will take preference and be generated instead of the root `cpp_info`
  one.
* Add `is_msvc_static_runtime()` method to `conan.tools.microsoft.visual` to identify when
  using *msvc* with static runtime and `is_msvc()` to validate if `settings.compiler` is
  *Visual Studio* with *msvc* compiler.
* Several bug fixes for the
  [Bazel](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html)
  generator.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#mar-2022) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
