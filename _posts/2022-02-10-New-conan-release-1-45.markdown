---
layout: post
comments: false
title: "Conan 1.45: New system.package_manager tools, markdown generator content updated, modern meson_lib and meson_exe templates for conan new and improvements in several build system tools."
description: "The new version includes new system.package_manager tools, markdown generator content updated, modern meson_lib and meson_exe templates for conan new and much more."
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
 "description": "Conan 1.45: New system.package_manager tools, markdown generator content updated, modern meson_lib and meson_exe templates for conan new and improvements in Meson, PkgConfig, CMake, Bazel and MSVC tools."
 }
</script>

We are pleased to announce that [Conan 1.45 is
out](https://github.com/conan-io/conan/releases/tag/1.45.0) and comes with some
significant new features and bug fixes. There is a new implementation to invoke system
package managers under
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
a library using the [Meson build system](https://mesonbuild.com/). Also, this Conan
release comes with several improvements in
[Meson](https://docs.conan.io/en/latest/reference/conanfile/tools/meson.html),
[PkgConfig](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html),
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html),
[Bazel](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html) and
[MSVC](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html) tools.

## New conan.tools.system.package_manager tools

In Conan 1.45 we added [new
helpers](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html)
to invoke system package managers in recipes to substitute the current
[SystemPackageTool](https://docs.conan.io/en/latest/reference/conanfile/methods.html#systempackagetool)
implementation. These tools provide wrappers for the most known system package managers
like: *Apt*, *Yum*, *Dnf*, *Brew*, *Pkg*, *PkgUtil*, *Chocolatey*, *PacMan* and *Zypper*.
These should be used inside the
[system_requirements()](https://docs.conan.io/en/latest/reference/conanfile/methods.html#method-system-requirements)
method of your recipe. 

You can support multiple system package managers in the same recipe, Conan will only execute
the one set with the `tools.system.package_manager:tool` [configuration
value](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html#conan-tools-system-package-manager-config)
or, in case this value is not set, will decide which one to use based on the [operating
system and
distribution](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html#conan-tools-system-package-manager).
For example, if we have a recipe with a `system_requirements()` method like this:

```python
from conan.tools.system.package_manager import Apt, Yum, PacMan, Zypper

...

def system_requirements(self):
    Apt(self).install(["libgl-dev"])
    Yum(self).install(["libglvnd-devel"])
    PacMan(self).install(["libglvnd"])
    Zypper(self).install(["Mesa-libGL-devel"])
```

If we run this example in Ubuntu Linux, Conan would execute only the `Apt.install()` call.

The signatures of these classes are very similar between them, there are three methods you can call to invoke these wrappers:

* `install(self, packages, update=False, check=False)`: install the list of packages passed as a parameter. 
* `update()`: update the system package manager database.
* `check(packages)`: check if the list of packages passed as a parameter are already installed.

Conan, by default, will never try to install any package using these wrappers unless you
set the configuration `tools.system.package_manager:mode` to value `install`. If that is
not set, it will work in `tools.system.package_manager:mode=check`, meaning that `update`
and `install` operations will never be performed. Nevertheless, in case you are calling to
`install(check=True)` with `tools.system.package_manager:mode=check`, Conan will check if
there's any package missing and in case they are all installed it will continue without
errors.

There are some slight differences between the constructors and methods between these
tools, please [check the
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/system/package_manager.html#conan-tools-system-package-manager)
for more details.

## Updated markdown generator

The markdown generator (introduced in Conan 1.24) creates a markdown `(.md)` file with
useful information about how to consume this package through different Conan generators.
Since this version, it's updated and generates this information for the new tools for
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html), [Visual
Studio](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html),
[Autotools and
Pkg-config](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html). Using it
is as simple as adding it as an argument to the `conan install` command.

```bash
conan install fmt/8.1.1@ --generator markdown
```

Then, you can check the generated `fmt.md` file and see, for example, which target names
you have to use to consume this library using `CMake` in your projects:

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2022-02-10/conan-1-45-md-generator.png" align="center" width="100%" alt="markdown for fmt"/>
</p>


## New meson templates for conan new

The `conan new` command is practical to create a template for a C++ project using Conan.
Until Conan 1.45 there were two built-in templates in Conan for CMake projects:
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


## Several improvements in Meson, PkgConfig, CMake, Bazel and MSVC tools

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
[changelog](https://docs.conan.io/en/latest/changelog.html#feb-2022) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
