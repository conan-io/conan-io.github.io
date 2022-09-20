---
layout: post
comments: false
title: "Getting up to speed with the latest Conan 1.50 features"
meta_title: "Getting up to speed with the latest Conan 1.50 features" 
meta_description: "Learn about the most significant changes to your recipes upgrading from 1.30s to 1.50s. Getting Ready for Conan 2.0 starts with using the new Conan 1.x generators"
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Getting up to speed with the latest Conan 1.50 features",
 "alternativeHeadline": "Learn about the important Conan 1.50 build system integrations",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Christopher McArthur, Conan Developer Advocate", 
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
 "datePublished": "2022-09-21",
 "description": "Learn about the most significant changes to your recipes upgrading from 1.30s to 1.50s. Getting Ready for Conan 2.0",
 }
</script>

Hello! I am Chris, some of you might already know me from GitHub as [prince-chrismc](http://github.com/prince-chrismc), and I’ve recently stepped into the role of Developer Advocate for Conan. My last two positions have been desktop/web applications for IoT and blockchain technology… Not a lot of C++ to say the least. The very first order of business was learning all the new features that were made available for Conan 2.0 - which is going to be a game changer.

> Conan 2.0 will be released really soon, so it's important to update you recipes with the latest features. The old methods are deprecated and will be removed. Make sure to check the [Conan 2.0 Recipe Migration](https://docs.conan.io/en/latest/migrating_to_2.0/recipes.html) for details.

Conan 2.0 Beta was released on June 20th 2022, and I spent the two weeks upgrading one of my projects from 1.33 to 1.51 with help from the Conan team and community on [Slack](https://cpplang.slack.com/archives/C41CWV9HA). It only [took me ~125 lines of diff](https://github.com/prince-chrismc/user-management/pull/301) to upgrade my project with half of that coming from updating my `readme.md`. Here’s the big things I learnt.

**TL;DR** - The biggest change is the switch to new generators. How Conan interacts with build systems and the impact on workflows that might need to be migrated. Don’t let that scare you, it’s actually _way_ easier than it sounds.

## Why are the generators changing?

When Conan 1.0 was released 6 years ago the C++ landscape was different and the expectation of developers to have access to package managers has grown significantly. Build systems improvement amplified Conan's ability to seamlessly fit into normal workflows.

For CMake specifically, the use of toolchain allows accurately declaring the settings and profile. This makes the builds more deterministic. Most notably this makes the integration fully transparent. With CMake 3 we got `find_package` and `IMPORTED` targets. In the subsequent years since, this has become the dominant and recommended way of consuming external libraries.

Learning about 2.0, "transparent" has been the buzz word. If you write good build scripts then adding Conan to you project will require zero changes. Upgrading should be removing the Conan specific line items.

## Generators Changes

Originally Conan offered the `cmake` generator, where you needed to modify your `CMakeLists.txt` to get the correct settings. With the industry wide adoption of targets, Conan introduced `cmake_find_package[_multi]` and slowly increased the flexibility.

Today, you should replace those with `CMakeToolchain` and `CMakeDeps`. Instead of modifying your CMakeLists to include `conanbuildinfo.cmake`, you simply pass the `conan_toolchain.cmake` when you configure CMake. Targets are still generated, but they now come with the correct namespace and target name in almost all cases (if not please open a PR with ConanCenter).

The biggest drawback is you need to call `conan install` before `cmake ..`. This sounds innocent at first but if you rely on third party tools that support cmake you no longer have the `cmake-wrapper` to call conan for you. The way CMake designed the toolchain support is that it needs to be preset at configuration before the project is declared. 

Conan will no longer get its settings from CMake, rather Conan will convert its settings to CMake which you will need to pass explicitly.

### Layouts

Layouts are a huge improvement. Previously you needed two distinct workflows, one for local development and a second for creating packages. Debugging the latter was a nightmare and was very often plagued with structural changes requiring nasty workarounds. With the new generators understanding layouts, they can preserve the project's build structure in the cache so the same relative structure is used in both. This should also help with `editable` mode which is looking promising. I am super excited to try this out again.

### Presets

CMake Presets are a delight. I never knew these existed until Conan pooped out some files in my build directory. Conan 2.0 will bump the requirement to CMake 3.15 but I’d recommend using 3.23+ for local development to take full advantage of what 1.x provides.

When configuring CMake, you no longer need to specify the compilation architecture to match your profile. Conan will pre-populate all that information and CMake will automatically detect and load it. `cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release` can now be replaced with `cmake --preset release`.

It is worth knowing, some compilers are not passed in (yet), for `gcc` if you set your profile to a specific version `compiler.version=11` you will still need to pass the environment variables to CMake `CC=gcc-11 CXX=g++-11`. You do not need this when the compiler version is in the CMake Generator.

## Two profiles is the new standard

Conan has distinguished the host and build contexts for a while, but the features that will be carried into 2.0 require you to be more explicit. You’ll probably run into messages asking for you to specify the build context, my “general default” advice:

- `-pr:h` (or `-pr` since 99% of the time you are changing the configuration of the binary you ware generating) is the settings for the binary + configuration of your tools (e.g. `CMaketoolchain` use Ninja, build type set to Debug, or switch environment variables for a different compiler). 
- `-pr:b` can be `default`. Your build machine environment should be detected with the default Conan profile. This is the change in Conan 2.0 from `None` to `default_profile`. If you need to compile tools from source you’ll want to set the information in this profile.
