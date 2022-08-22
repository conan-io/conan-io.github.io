---
layout: post
comments: false
title: "Conan 1.51: Improved download tool to support getting files from the local file system, support for components in MSBuildDeps, improved CMakePresets integration, new MesonDeps generator and lots of fixes to ease Conan 2.0 migration."
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

We are pleased to announce that [Conan 1.51 is
out](https://github.com/conan-io/conan/releases/tag/1.51.0) and comes with some
significant new features and bug fixes. For example, we added [support in
conan.tools.files.download](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-download)
to get files from the local file system. Also, now the
[MSBuildDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#msbuilddeps)
generator has support for components. We have made some improvements to the `CMakePresets`
support. We added a new
[MesonDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesondeps.html)
generator. Finally, we continue to work on the transition to Conan 2.0. This release
brings several fixes to make the migration easier.


Support for files in the local file system in conan.tools.files.download
------------------------------------------------------------------------

Starting in Conan 1.51, the
[download](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-download)
tool can reference files from the local file system. That means that
[conan.tools.files.get()](https://docs.conan.io/en/latest/reference/conanfile/tools/files/downloads.html#conan-tools-files-get)
will also work with local files. To use it in your recipes, reference the file you want to
get or download using the ``file:///<location>`` syntax like this:

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

This release brings component support for the
[MSBuildDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html?highlight=msbuilddeps#msbuilddeps)
generator. Now, for Conan packages that use components, this generator will create
separate property files for each component. That means that you can customize those
property files to just include what you need. For example, if you are depending directly
on a package that has components such as [boost](https://conan.io/center/boost) but you
just want to use the **boost** **filesystem** and **chrono** components, you can easily
customize the property file in the ``generate()`` method. Let's see an example:


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
        # we want to use instead of all of them
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

We continue to improve the CMakePresets support in Conan. This release adds a couple of features:

- The ``CMakePresets.json`` adds ``toolset`` and ``architecture`` items when using Ninja
  generator and the msvc compiler. This will make that Visual Studio can set the correct
  compiler automatically

- There is a new
  [conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html) item
  named
  [tools.cmake.cmaketoolchain.presets:max_schema_version](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html#cmaketoolchain)
  to define which schema version is used for the files *CMakePresets.json* and
  *CMakeUserPresets.json*. By default, the version schema of the generated
  *CMakeUserPresets.json* is **4** and the schema for the *CMakePresets.json* is **3**, so
  be aware that they require CMake >= 3.23.


Read more about the CMakePresets integration in the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html).


New MesonDeps generator
-----------------------

In most cases, when creating packages that use Meson as the build system, you use the 
[MesonToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesontoolchain.html)
along with the
[PkgConfigDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html)
generator and then Meson will find the requirements using *pkg-config*. There are some
cases, like the example below, where the build script uses the ``find_library()`` method
directly:


```python
project('mesonpackage', 'cpp')
cxx = meson.get_compiler('cpp')
mylib = cxx.find_library('mylib', required: true)
executable('app', 'main.cpp', dependencies: mylib)
```

In this case, Meson won't use already known detection mechanisms like *pkg-config*,
*cmake* or *config-tool* and you must inject the correct flags to the compiler to find
those libraries. This is the use case of
[MesonDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/meson/mesondeps.html)
that will define the appropiate *args* and *link_args* variables to link with those
libraries. 


Ease Conan 2.0 migration
------------------------

The migration process to Conan 2.0 compatible recipes has started in [Conan Center
Index](https://github.com/conan-io/conan-center-index) and the Conan team is making a
great effort to help in the migration process to Conan 2.0 compatible recipes. With that
in mind, we have released several patch Conan versions up to Conan 1.51.3 and backported a
few fixes to Conan 1.50.2 which is the Conan version used in Conan Center Index by this
date. If you want to get ready for Conan 2.0, please do not forget to check the [Conan
migration guide](https://docs.conan.io/en/latest/conan_v2.html) to 2.0 in the Conan
documentation.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#aug-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
