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

This release brings component support for the MSBuildDeps generator. Now, for Conan
packages that use components, this generator will create separate proerty files for each
component. That means that you can customize those property files to just include what you
really need. For example, if you are depending directly on a package that has components
such as [boost](https://conan.io/center/boost) but you just want to use the **boost**
**filesystem** and **chrono** components, you can easily do this in your recipe in the
``generate()`` method. Let's see an example:


```python
import textwrap
from conan import ConanFile
from conan.tools.microsoft import MSBuildDeps
from conan.tools.files import save


class MyappConan(ConanFile):
    name = "myapp"
    version = "1.0"

    ...
    
    def generate(self):
        deps = MSBuildDeps(self)
        deps.generate()
        # overwrite the generated conan_boost.props
        # with just the components
        # we want to use instead the whole package
        component_deps = textwrap.dedent(r"""
          <?xml version="1.0" ?>
          <Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">
            <ImportGroup Label="PropertySheets">
              <Import Condition="'$(conan_boost_chrono_props_imported)' != 'True'" Project="conan_boost_chrono.props"/>
              <Import Condition="'$(conan_boost_filesystem_props_imported)' != 'True'" Project="conan_boost_filesystem.props"/>
            </ImportGroup>
            <PropertyGroup>
              <conan_boost_props_imported>True</conan_boost_props_imported>
            </PropertyGroup>
          </Project>
            """)
        save(self, "conan_boost.props", component_deps)

```

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
