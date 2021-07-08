---
layout: post 
comments: false 
title: "Conan 1.38 : new PkgConfigDeps, new self.dependencies model for access to dependencies data,
new [conf] cli support, new cmake_layout(), support for jinja2 syntax in conan
profiles."
meta_title: "Version 1.38 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.38 : new PkgConfigDeps, new self.dependencies model for access to
dependencies data, new [conf] cli support, new cmake_layout(), support for jinja2
syntax in conan profiles." 
---

Conan 1.38 is already here and comes with lots of new features and some bug fixes. As we have
explained in previous posts we are paving the way to Conan 2.0, so most of the new features have to
do with that. We have added a new `PkgConfigDeps` generator that will replace the existing
`pkg_config` generator. Also, we have added a new `conanfile.dependencies` model, using a dictionary
that will return information about the dependencies and may be used both directly in recipe or
indirectly to create custom build integrations and generators. There is also a new `--conf` argument
to provide command line support for the new
[conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html) system. We have added
a new `cmake_layout()` layout helper to define a multi-platform CMake layout that will work for
different generators (ninja, xcode, visual, unix), and is multi-config.  Finally, now conan profiles
support `jinja2` syntax which provides the abilities of reading environment variables, using platform
information and much more.

## New `PkgConfigDeps` generator

## New `conanfile.dependencies` model

## Configuration `[conf]` support from the command line

## New `cmake_layout()` layout helper

## Support for `jinja2` syntax in conan profiles


-----------
<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2021) for the
complete list.  

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
