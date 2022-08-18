---
layout: post
comments: false
title: "Conan 1.51: Improved download tool to support getting files from the local file system, support for components in MSBuildDeps, improved CMakePresets integration, new MesonDeps generator, and lots of fixes to ease Conan 2.0 migration."
meta_title: "Version 1.51 of Conan C++ Package Manager is Released" 
meta_description: "The new version features includes improved download tool, support for components in MSBuildDeps, new MesonDeps generator, improved CMakePresets integration and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.51 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.51 Conan C/C++ package manager version",
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
 "datePublished": "2022-08-21",
 "description": "Improved download tool to support getting files from the local file system, support for components in MSBuildDeps, new MesonDeps generator, improved CMakePresets integration and lots of fixes to ease Conan 2.0 migration.",
 }
</script>

- Improved download tool to support getting files from the local file system
- Support for components in MSBuildDeps
- new MesonDeps generator
- improved CMakePresets integration
- lots of fixes to ease Conan 2.0 migration.



We are pleased to announce that [Conan 1.51 is
out](https://github.com/conan-io/conan/releases/tag/1.51.0) and comes with some
significant new features and bug fixes. For example, we added [support in
conan.tools.files.download](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-download)
to get files from the local file system. Also, now the
[MSBuildDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#msbuilddeps)
generator has support for components. We have made some improvements to the `CMakePresets`
support. We added a new
[MesonDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesondeps.html)
generator. Finally, we continue to work in the transition to Conan 2.0 and this release
brings lots of fixes to make the migration easier.


Support for files in the local file system in conan.tools.files.download
------------------------------------------------------------------------

From Conan 1.51 the
[download](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-download)
tool has support for referencing files located in the local file system. That means that
[conan.tools.files.get()](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-get)
will also work with local files. To use it in your recipes just reference the file you
want to get or download using the ``file:///<location>`` syntax like this:

```python
from conan import ConanFile
from conan.tools.files import get


class MylibConan(ConanFile):
    ...

    def source(self):
        get(self, "file:///path_to_folder/source.zip")
        # or if you want to use download...
        downloadt(self, "file:///path_to_folder/main.cpp")

```

To learn more about these tools, please check the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html).


Components support in MSBuildDeps
---------------------------------



Since we introduced XcodeDeps in [Conan
1.42](http://localhost:4000/2021/11/10/New-conan-release-1-42.html), we have been
gradually improving this generator. Since Conan 1.49 this generator creates separate
*.xcconfig* files for packages that have components, now this release adds some internal
optimizations that make it more efficient to consume these type of packages. The
components support makes it possible to select just specific components instead of adding
the whole package. For example, if you are depending directly on a package that has
components such as [boost](https://conan.io/center/boost) but you just want to use the
**boost** **filesystem** and **chrono** components, you can easily do this in your recipe
in the ``generate()`` method. Let's see an example:

Improvements in CMakePresets integration
----------------------------------------

New MesonDeps generator
-----------------------



Ease Conan 2.0 migration
------------------------










---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#aug-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
