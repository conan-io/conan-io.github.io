---
layout: post
comments: false
title: "Conan 1.40 : lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the only predefined remote, added Clang 13 and Visual Studio 2022 integration and new [conf] default_build_profile item."
meta_title: "Version 1.40 of Conan C++ Package Manager is Released"
meta_description: "The new version features include lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the only predefined remote, added Clang 13 and Visual Studio 2022 integration, new [conf] default_build_profile item and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.40 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.40 Conan C/C++ package manager version",
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
 "datePublished": "2021-09-09",
 "description": "Lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the only predefined remote, added Clang 13 and Visual Studio 2022 integration and new [conf] default_build_profile item.",
 }
</script>

Conan 1.40 brings several significant new features. We have improved
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) and
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
helpers adding new properties that make them more flexible. Also, finally, we have removed the old
*conan-center* remote and added the new *conancenter* as the only predefined remote. We have added
support for Clang 13 and Visual Studio 2022. Also, now setting `default_build_profile` in
[global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#global-conf)
you can define the profile that Conan uses by default in the [build
context](https://docs.conan.io/en/latest/reference/profiles.html#build-profiles-and-host-profiles).


## Improvements in CMakeDeps and CMakeToolchain helpers

We have added [some new
properties](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html?highlight=cmake_target_namespace#properties)
in the [new CMake helpers](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html) to
make them more flexible. Let's go through some of them:

* `cmake_target_namespace`: Use it to set the namespace of the target consumed in CMake. By default,
  this namespace is the same as the library name or to the value of the `cmake_target_name` property.
  So, if you create a library named *hello*, the default target to link in the consumer will be
  `hello::hello`. With this property, we can customize that target namespace to others like
  `MyChat::`.

Set this property in the `package_info` of the recipe:

```python
class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    ...
    def package_info(self):
        self.cpp_info.set_property("cmake_target_namespace", "MyChat")
    ...
```

Then, the consumer of the library can link the library using the new namespace in the
*CMakeLists.txt*.

```cmake
cmake_minimum_required(VERSION 3.15)
project(Consumer CXX)
find_package(hello CONFIG REQUIRED)
add_executable(example example.cpp)
target_link_libraries(example MyChat::hello)
```

* `cmake_find_mode`: Use it to make *CMakeDeps* generate *FindXXX.cmake* module files, config CMake
  scripts, both of them or none. The *none* option can be convenient if you want to make a package
  that wraps system libraries, and the consumers should find the config files in the CMake config
  path.

* `cmake_module_file_name`, `cmake_module_target_name`, `cmake_module_target_namespace`: These
  properties are equivalent to `cmake_file_name`, `cmake_target_name` and `cmake_target_namespace`
  but will be used for *FindXXX.cmake* module files when `cmake_find_mode` is `module` or `none`.

## Setting conancenter (center.conan.io) as the only predefined Conan remote

As you probably know, we released a new remote for ConanCenter in May with a more resilient and
scalable architecture. It's been the default since Conan 1.37, and now in the 1.40 version, we have
removed the old bintray remote and left `https://center.conan.io` as the only predefined remote for
Conan. If you are using an older Conan version, remember that the old remote is frozen and that new
packages are only available via the new `https://center.conan.io`.  For more information about this,
read [the dedicated blog
entry](https://blog.conan.io/2021/09/03/conancenter-declare-bintray-obsolete.html).

## Support for Clang 13 and Visual Studio 2022

Although Clang 13 and Visual Studio 2022 are not officially released yet, we have added support for
them in this release in case users want to start testing them. Please note that this support is
considered **experimental**, so it may change when the official versions are released.

## Use default_build_profile to set a default build context profile

Now you can set a default profile for the profile build that Conan uses for several commands. Also, a
host profile can be set as default as well. Using this is as easy as setting
`core:default_build_profile` and `core:core:default_profile `in the
[global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#global-conf)
configuration file. Imagine that we want to always compile for a Linux arm device in our MacOs
development environment:

```yaml
core:default_build_profile=macos_profile
core:default_profile=linux_armv8_profile
```

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#sept-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
