---
layout: post
comments: false
title: "Conan 1.55: CMakeDeps can now customize its dependencies target names, files and types, new tools.build:compiler_executables conf, new NMakeDeps and NMakeToolchain integration, env-vars and conf enabled for editables"
meta_title: "Version 1.55 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include removal of Python2 support, improved CMakePresets, new [layout] section in conanfile.txt and much more..."
---

We are pleased to announce that [Conan 1.55 is
out](https://github.com/conan-io/conan/releases/tag/1.55.0) and comes with some
significant new features and bug fixes. First, CMakeDeps provides the hability to set the
properties on the consumer side. Also, we added a new tools.build:compiler_executables to
set compilers variables in CMakeToolchain, MesonToolchain, and AutoToolsToolchain. We
added integration with NMake via the NMakeDeps and NMakeToolchain generators. Finally we
enabled environment vars and configuration for use in editable packages.


## CMakeDeps can now customize its properties

## new tools.build:compiler_executables conf

## NMakeDeps and NMakeToolchain generators

## Enabled environment vars and configuration for use in editable packages

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#nov-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
