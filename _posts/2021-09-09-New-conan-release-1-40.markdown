---
layout: post
comments: false
title: "Conan 1.40 : lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the default, added Clang 13 and Visual Studio 2022 integration and new [conf] default_build_profile item."
meta_title: "Version 1.40 of Conan C++ Package Manager is Released"
meta_description: "lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the default, added Clang 13 and Visual Studio 2022 integration, new [conf] default_build_profile item and much more..."
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
 "description": "Lots of improvements in CMakeDeps and CMakeToolchain, new Conan Center remote as the default, added Clang 13 and Visual Studio 2022 integration and new [conf] default_build_profile item.",
 }
</script>

Conan 1.40 brings several significant new features. We have improved [CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) and [CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html) helpers adding new properties that make them more flexible. Also, finally, we have removed the old *conan-center* default remote and added the new *conancenter* as the default. We have added support for Clang 13 and Visual Studio 2022. Also, now setting `default_build_profile` in [global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#global-conf) you can set a profile that will be used by default in the [build context](https://docs.conan.io/en/latest/reference/profiles.html#build-profiles-and-host-profiles).


## Improvements in CMakeDeps and CMakeToolchain helpers


## Setting conancenter (center.conan.io) as default Conan remote

## Support for Clang 13 and Visual Studio 2022


## Use default_build_profile to set a default build context profile

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#sept-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
