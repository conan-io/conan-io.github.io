---
layout: post
comments: false
title: "Conan 1.45: ..."
meta_title: "Version 1.45 of Conan C++ Package Manager is Released"
meta_description: "The new version ..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.45 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.45 Conan C/C++ package manager version",
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
 "datePublished": "2022-02-10",
 "description": "...",
 }
</script>

- New "tool.system.package_manager" tools 
- Update content created by the markdown generator. 
- Modern "meson_lib" and "meson_exe" templates for "conan new".
- New "--output-folder" for install and editable
- Improvements in Meson, PkgConfig, CMake, Bazel, GNU and MSVC tools


We are pleased to announce that [Conan 1.45 is
out](https://github.com/conan-io/conan/releases/tag/1.45.0) and comes with some
significant new features and bug fixes. We added a new implementation for tools that
invoke system package managers under
[conan.tools.system.package_manager](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html)
that replaces the current
[SystemPackageTool](https://docs.conan.io/en/latest/reference/conanfile/methods.html#systempackagetool).
Also, we have updated the [markdown
generator](https://docs.conan.io/en/latest/reference/generators/markdown.html) to create
the information needed to consume packages with the new tools for
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html), [Visual
Studio](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html),
[Autotools and
Pkg-config](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html). We added
two new templates for the command `conan new`, to generate examples of an application and
a library using the [Meson build system](https://mesonbuild.com/). Also, we added `--source-folder` and `--output-folder` arguments to `conan editable` and `conan install` commands to work with [layout()](https://docs.conan.io/en/latest/developing_packages/package_layout.html#package-layout).

## New conan.tools.system.package_manager tools

In Conan 1.45 we are adding [new
helpers](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html)
to invoke system package managers in recipes meant to substitute the current
[SystemPackageTool](https://docs.conan.io/en/latest/reference/conanfile/methods.html#systempackagetool)
implementation. These tools provide wrappers for the most known system package managers
like: *Apt*, *Yum*, *Dnf*, *Brew*, *Pkg*, *PkgUtil*, *Chocolatey*, *PacMan* and *Zypper*.
These should be used inside the
[system_requirements()](https://docs.conan.io/en/latest/reference/conanfile/methods.html#method-system-requirements)
method of your recipe. 

You can add support for multiple package managers in your recipes, Conan will execute only
the one set with the `tools.system.package_manager:tool` [configuration
value](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html#conan-tools-system-package-manager-config)
or in case this value is not set will decide which one to use based on the [operating
system and
distribution](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html#conan-tools-system-package-manager).
For example, if we are have recipe with a `system_requirements()` method like this:

```python
...
from conan.tools.system.package_manager import Apt, Yum, PacMan, Zypper

def system_requirements(self):
    Apt(self).install(["libgl-dev"])
    Yum(self).install(["libglvnd-devel"])
    PacMan(self).install(["libglvnd"])
    Zypper(self).install(["Mesa-libGL-devel"])
```

If we were running this in Ubuntu Linux, Conan would execute only the `Apt.install()` call.

The signatures of these classes are very similar between them and there are three methods you can call to invoke these wrappers:

* 



## Updated markdown generator

## New meson templates for conan new

## New --source-folder and --output-folder arguments for conan editable and conan install

```python
...
class AlembicConan(ConanFile):
    name = "alembic"
    ...
    def package_info(self):
        self.cpp_info.names["cmake_find_package"] = "Alembic"
        self.cpp_info.names["cmake_find_package_multi"] = "Alembic"
        ...

```


---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#dec-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
