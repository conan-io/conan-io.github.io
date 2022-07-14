---
layout: post
comments: false
title: "Conan 1.50: New CMakeToolchain.cache_variables, improving XCodeDeps support for components, fixes in CMake, MSBuild, XCode, many backports, minor changes, new tools, towards providing a 2.0 compatible recipe syntax."
meta_title: "Version 1.50 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include new CMakeToolchain.cache_variables, improving XCodeDeps support for components, several fixes and much more"
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.50 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.50 Conan C/C++ package manager version",
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
 "datePublished": "2022-07-14",
 "description": "New CMakeToolchain.cache_variables, improving XCodeDeps support for components, fixes in CMake, MSBuild, XCode, many backports, minor changes, new tools, towards providing a 2.0 compatible recipe syntax.",
 }
</script>

We are pleased to announce that Conan 1.50 has been released and brings some significant
new features and bug fixes. We have added the ``CMakeToolchain.cache_variables`` to
apply them via ``-D`` arguments in the build helper. Also, we have improved the XCodeDeps
support for components. Finally, we continue fixing things and porting tools so that the
recipe syntax is compatible with Conan 2.0.


## Advances in the documentation for Conan 2.0

Before describing the new features in Conan 1.50 we would like to talk a bit about Conan
2.0. As you may know the first Conan 2.0 beta is already out and it can be installed using:

```bash
$ pip install conan --pre
```

We have done an effort lately to complete the [documentation for the new Conan major
version](https://docs.conan.io/en/2.0/). Although the documentation for 2.0 is still in
"draft" state, some sections are practically complete. There are some differences in how
the Conan 1.X and Conan 2.0 documentation is structured. Let's see the most relevant
sections of the documentation for Conan 2.0:

### The tutorial section

This [new section](https://docs.conan.io/en/2.0/tutorial.html) gives a practical hands-on
introduction to the most important Conan features. The objective is learning these
features step by step. This section is divided in three sub-sections:

- Consuming packages: this part, that is already completed shows how to build your
projects using Conan to manage your dependencies starting from a simple project that uses
the Zlib library. In this section you will learn things like [using
tool_requires](https://docs.conan.io/en/2.0/tutorial/consuming_packages/use_tools_as_conan_packages.html),
what [Conan settings and
options](https://docs.conan.io/en/2.0/tutorial/consuming_packages/different_configurations.html)
are, how to consume using a
[conanfile.py](https://docs.conan.io/en/2.0/tutorial/consuming_packages/the_flexibility_of_conanfile_py.html),
and how you can
[cross-compile](https://docs.conan.io/en/2.0/tutorial/consuming_packages/cross_building_with_conan.html)
your applications with Conan using the dual profile approach. 

- Creating packages: this section is half finished and shows how to create Conan packages
  using a Conan recipe. We begin by [creating a basic Conan
  recipe](https://docs.conan.io/en/2.0/tutorial/creating_packages/create_your_first_package.html)
  to package a simple C++ library that you can scaffold using the conan new command and
  then we begin adding features to it explaining how the different methods of the Conan
  recipe work. Topics such as [how to retrieve the source
  code](https://docs.conan.io/en/2.0/tutorial/creating_packages/handle_sources_in_packages.html)
  from external repositories and apply patches, [customizing the
  toolchain](https://docs.conan.io/en/2.0/tutorial/creating_packages/preparing_the_build.html),
  how binary compatibility works and how to package the files of your Conan packages. The
  last part of the tutorial is about the peculiarities of different types of Conan
  packages like [header-only
  packages](https://docs.conan.io/en/2.0/tutorial/creating_packages/other_types_of_packages/header_only_packages.html),
  [packages for pre-built
  binaries](https://docs.conan.io/en/2.0/tutorial/creating_packages/other_types_of_packages/package_prebuilt_binaries.html)
  or [tool requires
  packages](https://docs.conan.io/en/2.0/tutorial/creating_packages/other_types_of_packages/tool_requires_packages.html).

- Versioning and Continuous Integration: this section is not written yet. We will provide
  some "best practices" for using Conan in your CI here.

### The examples section

This section collects examples of some relevant use cases for Conan features, things like:

- Creating [custom Conan
  commands](https://docs.conan.io/en/2.0/examples/extensions/commands/clean/custom_command_clean_revisions.html)
- [Using
  CMakePresets](https://docs.conan.io/en/2.0/examples/tools/cmake/cmake_toolchain/build_project_cmake_presets.html)
  to build your project.
- Best practices for [patching the source
  code](https://docs.conan.io/en/2.0/examples/tools/files/patches/patch_sources.html)
- How to [cross-build for
  Android](https://docs.conan.io/en/2.0/examples/cross_build/android/ndk.html) and
  [integrate Conan in Android
  Studio](https://docs.conan.io/en/2.0/examples/cross_build/android/android_studio.html).

### The reference section

[This section](https://docs.conan.io/en/2.0/reference.html) will collect the reference of
public classes and methods you can use in your Conan recipes. One significant section of
the reference is the one documenting the Conan API. Although the developement of this API
is still in progress and is not stable yet, we plan to document the whole Conan API for
Conan 2.0 so that you can use that in your projects. One relevant example, regarding this
is [the one that creates a Conan custom
command](https://docs.conan.io/en/2.0/examples/extensions/commands/clean/custom_command_clean_revisions.html)
to clean the Conan cache and uses some methods of this API.


## New CMakeToolchain.cache_variables


## Improvements in XCodeDeps components support


## Advances in providing a 2.0 compatible recipe syntax

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
