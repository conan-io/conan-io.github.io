---
layout: post
comments: false
title: "Conan 2.0 Recipe Migrations in ConanCenterIndex"
meta_title: "Here's a taste of all the pretty easy changes we are making in ConanCenterIndex getting ready for the Conan 2.0 launch"
description: "This article will break down all the changes we are making in ConanCenterIndex for you slightly more complicated header-only recipe which uses CMake to install files instead of a simply copy. This makes it a great reference for more CMake based projects."
---

<script type="application/ld+json">
{
 "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Conan 2.0 Recipe Migrations in ConanCenterIndex",
 "alternativeHeadline": "Here's a taste of all the pretty easy changes we are making in ConanCenterIndex getting ready for the Conan 2.0 launch",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Christopher McArthur, Conan Developer Advocate",
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan cmake header only package 2.0 migration recipe updates", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
 },
 "datePublished": "2022-10-26",
 "description": "This article will break down all the changes we are making in ConanCenterIndex for you slightly more complicated header-only recipe which uses CMake to install files instead of a simply copy. This makes it a great reference for more CMake based projects."
 }
</script>

- Everything you need is available in 1.53, so you can prepare recipes ahead of time
- Most of the changes are “search and replace”

I want to upgrade my personal project, and the community has done an amazing job upgrading recipes. More than I was even expecting. (and I review “most” of the PRs we get at ConanCenterIndex).

---

OpenSSL and Boost are missing but those are too involved for a blog, so the last one was [RESTinio](https://github.com/conan-io/conan-center-index/blob/1c3556ccd1cb04a6023d0170ba04552649eb45f3/recipes/restinio/all/conanfile.py), which I will try to break down every change that’s needed to upgrade so you can upgrade your own recipes.

This is a Header only, but unlike most (usually they are just ``copy`` files), it's a CMake based project so it’s relatively easy and comes with a few extra quirks. The only thing I will not cover (since it was already done) is the ``package_info`` “property names” for the new [CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) generator. You can read about the [New ``cpp_info.set_property`` model](https://github.com/conan-io/conan-center-index/blob/master/docs/v2_migration.md#new-cpp_info-set_property-model) in the ConanCenter docs.

## Updating the imports

All of the 2.0 methods are in the ``conan`` namespace… Notice the “s” is no longer there, this should make code reviews an easy way of spotting new versus old.

There’s a [cheat sheet](https://github.com/conan-io/conan-center-index/blob/master/docs/v2_linter.md#import-conanfile-from-conan) for more of the file IO and common imports in ConanCenterIndex. Most of the tools imports are now grouped ``conans.tools.Version`` is made available from ``conan.tools.scm``

My recommendation is to look for ``tools.`` and add in the new imports for each then just replace it with an empty string then add back the ``self`` as the first argument. This will work for all but the rare case where a name was changed. You should be able to very quickly find the tool category in the [2.0 Reference](https://docs.conan.io/en/2.0/reference/tools.html) documentation.

For those who wonder, why not add the category of the tools where they are being used, this is to follow the recommendations in [tools import guidelines](https://docs.conan.io/en/latest/reference/conanfile/tools.html?highlight=main%20guidelines) where the higher namespace is considered private and **should not be used**.

The only “surprise” is the import you will need to add. This is because some method were previously methods for the ``ConanFile``, for instance ``self.copy`` will become ``copy(self, …)`` and this is exposed from the ``conan.tools.files``. You will also need to change the source and destination for the files methods, the new static methods no longer assume the folder and require you to be explicit.

Just with changing the imports alone, you can see the difference between old versus new

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/0.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff updating imports"/>
</p>

You might notice the only import being dropped was ``functools`` this is because the new Generators and build helpers… we’ll get to those soon.

## Enabling Layouts

One of the key features in 2.0 that enables a lot of the improvements is [Layouts](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts). Since RESTinio is a CMake based project you would probably reach for the [``cmake_layout``](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake_layout.html) however this is tailored towards build and packaging libraries. This would probably work but this is a “less is more” situation… for Header-Only, i’d start with the [``basic_layout``](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#basic-layout).

Importing this and adding it in we can finally replace some clutter, those old “subfolder properties” which were a convention in ConanCenterIndex.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/1.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff adding layout"/>
</p>

- ``\_source_subfolder`` becomes ``source_folder``
- ``\_build_subfolder`` can be replaced by ``self.build_folder``

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/2.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff removing subfolder properties"/>
</p>

We get to do even more clean up. Since this is header-only, there is no “build folder” but we do configure CMake. This is now taken care of by the new ``conan.tools.cmake.CMake`` build helper. Since the ``basic_layout`` setups the property ``self.build_folder`` the CMake help takes full advantage of this.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/3.png" style="display: block; margin-left: auto; margin-right: auto;" alt="adding basic layout"/>
</p>

## Switch to the new Generators

This recipe previously used the old ``cmake`` generator as an attribute… It should have used ``cmake_find_package_multi`` but let’s just pretend it did. These can be replaced with [``CMakeToolchain``](https://docs.conan.io/en/2.0/reference/tools/cmake/cmaketoolchain.html) and ``CMakeDeps`` respectively.

This change creates a lot of difference.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/4.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff new generator vs old helper"/>
</p>

- We no longer pass CMake configuration options to the build helper.

  - That responsibility with given to the new toolchain.
  - CMakeDeps will generate the files required for RESTinio’s calls to ``find_package``

- ``cmake.definitions`` can be replaced by ``tc.variables``

The best part is cleanup! We can also remove the old generators attribute along with the old “cmake wrapper” that we used to use to call the old ``cmake`` generators ``include(conanbuildinfo.cmake)`` and ``conan_basic_setup()``

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/5.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff build method"/>
</p>

This is sadly where we uncover our first caveat… this “cmake wrapper” we used in ConanCenterIdex sometimes hides functionality. In this particular example, it directed the build help to the correct subfolder of RESTinio with its ``CMakeLists.txt``. With ``add_subdirectory(source_subfolder/dev/restinio)`` so we will need to move this into the recipe.

Thankful this is a pretty common case and the new build helper can be configured correctly.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/6.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff build methods pt2"/>
</p>

We can simply pass the ``build_script_folder`` argument to let it know the “source folder” which will be used when it configures CMake.

## Tackling the validate method

This is the most complicated part. In Conan 2.0 we will drop the ``Visual Studio`` compiler for the ``msvc`` compilers. There’s a lot of reason why, so it might be worth checking out the [Conan Tribe Proposal](https://github.com/conan-io/tribe/blob/main/design/032-msvc_support.md) where this was decided.

Thankfully we don’t need to think about this too much as the Community has already figured out the best way of going about this. Check the [CMake Template Package](https://github.com/conan-io/conan-center-index/blob/master/docs/package_templates/cmake_package/all/conanfile.py#L90) from ConanCenterIndex we can see there’s a new helper ``check_min_vs`` that handles the new compiler.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/7.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff validate mthod"/>
</p>

There’s a few noteworthy Conan 2.0 changes:

- ``self.settings.compiler`` became ``self.info.settings.compiler``
  - This is actually a migration pain point we are seeing in ConanCenterIndex, there are some trade-offs.
- [``check_min_vs``](https://docs.conan.io/en/2.0/reference/tools/microsoft/helpers.html#check-min-vs) is added

Also we no longer print warnings, this is because the convention in ConanCenter causes a lot of noise for the considerable group of users that have custom compilers or define their own with custom settings.

## Updating package id

This is a pretty easy one, and generally the last step. The old ``header_only`` has been replaced with a ``clear`` to make it more obvious what it’s doing.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/8.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff package id"/>
</p>

## Package info and cpp folders

We will once again need to add a few lines to help optimize the new generators.

The layout does a lot of work for use, including helping to set up the ``cpp_info`` with folders for binaries, frameworks, and libraries. As we are packaging a header only project, these need to be explicitly set to empty.

## Test Package

This is an important part of the recipe since we still want to support 1.x all the while adding 2.0 support. There’s a lot of steps here but it’s pretty straightforward.

- Create a new folder ``test_v1_package``
- Move the ``test_package/conanfile.py`` to ``test_v1_package``
- Copy the ``test_package/CMakeLists.txt`` to ``test_v1_package``
- In the original ``test_package/CMakeLists.txt`` remove the lines to the old generator

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2022-10-26/9.png" style="display: block; margin-left: auto; margin-right: auto;" alt="diff old test package cmake list"/>
</p>

- Change the copied file ``test_v1_package/CMakeLists.txt`` to pull the source files form the original location ``../test_package/test_package.cpp`` to not duplicate files
- Download the new ``test_package/conanfile.py`` from the [ConanCenterIndex template](https://github.com/conan-io/conan-center-index/blob/master/docs/package_templates/header_only/all/test_package/conanfile.py)

That should do it.

If you are looking for the full diff, you will be interested in <https://github.com/conan-io/conan-center-index/pull/13338> which is the final product and was merged!
