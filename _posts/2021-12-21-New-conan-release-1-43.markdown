---
layout: post
comments: false
title: "Conan 1.43: New cpp_info properties proposal to move forward new generators without breaking Conan Center, modern tools.gnu.PkgConfig to supersede legacy tools.PkgConfig, baremetal os setting to represent bare metal platforms without operating system."
meta_title: "Version 1.43 of Conan C++ Package Manager is Released"
meta_description: "The new version features includes new cpp_info properties proposal to move forward new generators without breaking Conan Center, modern tools.gnu.PkgConfig to supersede legacy tools.PkgConfig, baremetal os setting to represent bare metal platforms without operating system and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.43 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.43 Conan C/C++ package manager version",
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
 "datePublished": "2021-12-21",
 "description": "New cpp_info properties proposal, modern tools.gnu.PkgConfig, new baremetal os setting.",
 }
</script>

We are pleased to announce that [Conan 1.43 is
out](https://github.com/conan-io/conan/releases/tag/1.43.0) and comes with some
significant new features and bug fixes. We have changed the `cpp_info` properties
model to push the migration of recipes in Conan Center, reducing the risk of breaking
consumers that use the current `cmake_find_package/multi` generators. Also, there's a new
`tools.gnu.PkgConfig` that replaces `tools.PkgConfig`. Finally, we have a new `os` setting
to represent Hardware platforms without an operating system.


## Changes in cpp_info properties model

Starting in Conan 1.43, we have decided that the properties model is used only by the new
generators like
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html)
and
[PkgConfigDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html).
The current generators, like `cmake_find_package` and `cmake_find_package_multi`, will not
listen to these properties. Setting that cpp_info information independent makes the
migration process less prone to error. The drawback is that we need to maintain both the
old `.names`, `.filenames`, etc. attributes and the `set_property` methods coexisting in
recipes in Conan Center Index. This coexistence will end once we no longer support current
generators sometime after Conan 2.0 is released. Then, the old attributes will disappear
from recipes, and only the `set_property` model will remain.

There are a couple of details that must be taken into account when introducing the new
properties model in recipes:

- In contrast to the `.names` attribute, the target names set with the `cmake_target_name`
  property are "absolute". That means that Conan will not prepend any namespaces to the
  value you set with this property.
- When consumers use the CMakeDeps generator, this generator will create config CMake
  scripts by default. To generate CMake module files, you have to set the
  `cmake_find_mode`
  [property](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html#properties)
  for this generator.

Let's see an example of how recipes have to be modified and how they will look in this
transition from Conan 1.X to 2.0. 

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

With the current model, the `cmake_find_package/multi` generators will create the
`Alembic::Alembic` target. For the filename, it will inherit the value set with `.names`
and generate `FindAlembic.cmake`, `AlembicConfig.cmake`, etc. To set the same information
for the new `CMakeDeps` generators we should add the `cmake_target_name` and
`cmake_file_name` properties.

```python
...
class AlembicConan(ConanFile):
    name = "alembic"
    ...
    def package_info(self):
        self.cpp_info.names["cmake_find_package"] = "Alembic"
        self.cpp_info.names["cmake_find_package_multi"] = "Alembic"
        self.cpp_info.set_property("cmake_target_name", "Alembic::Alembic")
        self.cpp_info.set_property("cmake_file_name", "Alembic")
        ...

```

Please, [check the
docs](https://docs.conan.io/en/latest/migrating_to_2.0/properties.html#properties-migration)
for a detailed guide on how set the properties in your recipes to prepare them for Conan
2.0.

## New tools.gnu.PkgConfig

Conan 1.43 brings the new
[tools.gnu.PkgConfig](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfig.html)
tool, that improves and replaces the current `tools.PkgConfig` one.
This tool can extract information from existing from existing `.pc` files.
This can be used, for example, to create a “system” package recipe over some system
installed library, as a way to automatically extract the `.pc` information from the system.
Or if some proprietary package has a build system that only outputs `.pc` files.

This tool provides a `fill_cpp_info()` method that can be used in the `package_info`
method to translate the information from the `.pc` files to the Conan `cpp_info`. Let's
see an example:

```python
...
class MyPkg(ConanFile):
    ...
    def package_info(self):
        pkg_config = PkgConfig(self, "gl")
        pkg_config.fill_cpp_info(self.cpp_info, is_system=True)
        ...

```

This will get the information from the `gl.pc` file and translate that to the attributes
of the `cpp_info`. In this case, for example, it will add `GL` to
`self.cpp_info.system_libs`. Please, check the Conan documentation for more details on the
new
[PkgConfig](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfig.html)
tool 

## New baremetal os setting for Hardware platforms without operating system

Conan 1.43 comes with a new `baremetal` os setting added to the default Conan settings.
This setting is just a general name convention and it is expected that users might
customize the space inside the `baremetal` setting with further subsettings to specify
their specific hardware platforms, boards, families, etc.

The ``os=baremetal`` value is still not used by Conan builtin toolchains and helpers, but
it is expected that, as the evolve, they start using it in the future.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#dec-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
