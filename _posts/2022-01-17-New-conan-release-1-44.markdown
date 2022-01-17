---
layout: post
comments: false
title: "Conan 1.44: Introduced tool_requires attribute to replace generic build_requires, new tools to explicitly handle symlinks, CMakeToolchain can now apply several user toolchains, added vars to CMakeDeps for better upstream match."
meta_title: "Version 1.44 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include Introduced tool_requires attribute to replace generic build_requires, new tools to explicitly handle symlinks and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.44 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.44 Conan C/C++ package manager version",
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
 "datePublished": "2022-01-17",
 "description": "New tool_requires attribute, explicitly handle symlinks, several user toolchains in CMakeToolchain, added vars to CMakeDeps.",
 }
</script>


We are pleased to announce that Conan 1.44 has been released and brings some significant
new features and bug fixes. We have added a
[tool_requires](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#tool-requires)
attribute to provide a compatible way to migrate to Conan 2.0. Also, this version comes
with several functions under `conan.tools.files.symlinks` to help manage symlinks. We have also
added to
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
the capability of applying several user toolchains. Finally,
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html)
adds several variables to match upstream CMake modules as much as possible.


## New tool_requires attribute

Starting in Conan 1.44, we have renamed “build requirement” to "tool requirement”. The
intention of this is to highlight that the usage of this kind of requirement must be for
“tools” exclusively, not being valid for libraries to express a “private” requirement or other
meanings. Now recipes will look like this:

```python
class MyPkg(ConanFile):
    tool_requires = "cmake/3.19.6"
```

Although the `build_requires` attribute will still work in Conan 1.X, it will disappear in
Conan 2.0 so please [start migrating your
recipes](https://docs.conan.io/en/latest/conan_v2.html#update-the-syntax-of-your-conanfile)
to make them ready for 2.0.

## New tools to explicitly handle symlinks

There are [several new
functions](https://docs.conan.io/en/latest/reference/conanfile/tools/files/symlinks.html)
under `conan.tools.files.symlinks` to manage symlinks. With these tools, you can transform
absolute to relative symlinks, remove broken symlinks, remove external symlinks and get
the symlinks in a folder. Let's have a look at them:

- **Convert the symlinks with absolute paths into relative ones**. It will only consider
  those inside the ‘base_folder’. 

```python
def absolute_to_relative_symlinks(conanfile, base_folder):
```

- **Remove external symlinks** to files that point outside the ‘base_folder’, no matter if
relative or absolute.

```python
def remove_external_symlinks(conanfile, base_folder):
```

- **Remove broken symlinks**, no matter if relative or absolute.

```python
def remove_broken_symlinks(conanfile, base_folder):
```

These tools will help migrate to Conan 2.0 where the package files won't be automatically
cleaned from broken absolute symlinks or external symlinks.

## Apply multiple user toolchains with CMakeToolchain

The
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
is now prepared to apply several user toolchains. For example, you could have multiple
`tool_requires` each one defining a toolchain in its `package_info` method:

```python
import os
from conans import ConanFile
class ToolchainPackage(ConanFile):
    name = "toolchain1"
    ...
    def package_info(self):
        f = os.path.join(self.package_folder, "mytoolchain.cmake")
        self.conf_info["tools.cmake.cmaketoolchain:user_toolchain"] = f
```

If you want to use several toolchains in a recipe, you can gather the values from all the
dependency configs and adjust the ``user_toolchain`` block to apply all the toolchains:

```python
from conans import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain
class Pkg(ConanFile):
    ...
    tool_requires = "toolchain1/1.0", "toolchain2/1.0"
    def generate(self):
        # Get the toolchains from "tools.cmake.cmaketoolchain:user_toolchain" conf at the
        # tool_requires
        user_toolchains = []
        for dep in self.dependencies.direct_build.values():
            ut = dep.conf_info["tools.cmake.cmaketoolchain:user_toolchain"]
            if ut:
                user_toolchains.append(ut)
        # Modify the context of the user_toolchain block
        t = CMakeToolchain(self)
        t.blocks["user_toolchain"].values["paths"] = user_toolchains
        t.generate()
      ...
```

This way, the `conan_toolchain.cmake` file generated by Conan will include both toolchains before declaring anything else:

```
...
include("/path/to/mytoolchain.cmake")
include("/otherpath/to/mytoolchain.cmake")
...
```

## Added variables to CMakeDeps to match better with upstream

As a way of getting closer to the typical variables declared by [CMake official find
modules](https://cmake.org/cmake/help/latest/manual/cmake-modules.7.html#find-modules) we
have added these variables so they are available when using
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html)
Conan generator:

- **PackageName_**LIBRARIES
- **PackageName_**INCLUDE_DIRS
- **PackageName_**INCLUDE_DIR
- **PackageName_**DEFINITIONS
- **PackageName_**VERSION_STRING

These definitions will certainly help in the vast majority of the cases. The intention is
not to try to define every possible variable that is defined by the official modules,
those should be added in recipes using a [custom
build_module](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html#properties).

---

<br>

Besides the items listed above,
there were some minor bug fixes you may wish to
read about. If so
please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#dec-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
