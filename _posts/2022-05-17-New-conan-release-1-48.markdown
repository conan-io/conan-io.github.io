---
layout: post
comments: false
title: "Conan 1.48: Improvements in CMakePresets integration, new "conan new" autotools templates, confs for bitcode, arc, visibility in Apple and Xcode, support to generate env ps1 instead of bat in Windows."
meta_title: "Version 1.48 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include Improvements in CMakePresets integration, new "conan new" autotools templates and much more..."
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
 "description": "Improvements in CMakePresets integration, new "conan new" autotools templates, confs for bitcode, arc, visibility in Apple and Xcode, support to generate env ps1 instead of bat in Windows.",
 }
</script>

We are pleased to announce that Conan 1.48 has been released and brings some significant
new features and bug fixes. We have improved the CMakePresets integration. Also we have
added new "conan new" autotools templates. We added new confs for bitcode, arc, visibility
in Apple and Xcode. This release also adds support to generate env ps1 instead of bat in
Windows.

## Improvements in CMakePresets integration

Since Conan 1.47 we started to provide support for
[CMakePresets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html). This file
is used internally in Conan to pass information like the generator and toolchain file
location from the
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
to the [CMake build
helper](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html).
Besides this, using this file also improves the developer flow experience, when working
locally with Conan and CMake. Let's see an example.


## New "conan new" autotools templates

As you know, the `conan new` command is practical to [create a
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

## New confs for bitcode, arc, visibility in Apple and Xcode

## Support to generate env ps1 instead of bat in Win


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
