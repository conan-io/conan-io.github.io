---
layout: post
comments: false
title: "Conan 2.0 Recipe Migrations in ConanCenterIndex"
meta_title: "Here's a taste of all the pretty easy changes we are making in ConanCenterIndex getting ready for the Conan 2.0 launch"
meta_description: "This article will break down all the changes we are making in ConanCenterIndex for you slightly more complicated header-only recipe which uses CMake to install files instead of a simply copy. This makes it a great reference for more CMake based projects."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
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
 "datePublished": "2022-10-13",
 "description": "This article will break down all the changes we are making in ConanCenterIndex for you slightly more complicated header-only recipe which uses CMake to install files instead of a simply copy. This makes it a great reference for more CMake based projects.",
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

![diff updating imports](https://lh5.googleusercontent.com/5X14uDbu3jQP0235dESPzXLhFmMP3vRXTbEPC0aJBjE5p0tLnUayC7xN_vCSSH0Lh8khJRxIVhhiqKb4qXSg9z69T0u0yiZ123R9jv39R_EtipSl76Vt55c_QzHZfOSsgoYmnDpAggsr9zEQ0npHm0B-588P8fag5yVyJRSgxF7maUmtxvxBoq6jPA)

You might notice the only import being dropped was ``functools`` this is because the new Generators and build helpers… we’ll get to those soon.

## Enabling Layouts

One of the key features in 2.0 that enables a lot of the improvements is [Layouts](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts). Since RESTinio is a CMake based project you would probably reach for the [``cmake_layout``](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake_layout.html) however this is tailored towards build and packaging libraries. This would probably work but this is a “less is more” situation… for Header-Only, i’d start with the [``basic_layout``](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#basic-layout).

Importing this and adding it in we can finally replace some clutter, those old “subfolder properties” which were a convention in ConanCenterIndex.

![diff adding layout](https://lh4.googleusercontent.com/cHkSjdEeh6DVKXORS7CQdotn5hWGbGKB4MnL3MxhTcPcvsyzbOlAGSBdbSI4m3XmcvnwUENhq1Snxhe-A9Z0iUG1aX_KXz2DOXFm8XUrQPG6l4MlrUO6HIuaPO8c1TfMxjXu_gpinDI3EIkqSeeniUC3yFKiUQ3n4Zn3fc0k6Q2e6g-aPfkmrahA7w)

- ``\_source_subfolder`` becomes ``source_folder``
- ``\_build_subfolder`` can be replaced by ``self.build_folder``

![diff removing subfolder properties](https://lh3.googleusercontent.com/fYSzRonQUk5FccNB5ROil14743lhjdoljr8e2IE-0eUZ_oK9jYMOZSwSkhQW4zgGB5vaRxUEGpJ0iWJ37UTddxOonwZDnd3zAEcbTzDzQXu9BJHM3NX-42ioYY_W0NGKsLoDw366Y31Se1VqgHwMMXLGYcvm2VUzT1CofmL8588Ou5TaxQW5hAzY2w)

We get to do even more clean up. Since this is header-only, there is no “build folder” but we do configure CMake. This is now taken care of by the new ``conan.tools.cmake.CMake`` build helper. Since the ``basic_layout`` setups the property ``self.build_folder`` the CMake help takes full advantage of this.

![adding basic layout](https://lh4.googleusercontent.com/6LrL2joBMkdRL_fenTr-_r6U5_GL9vPunsgoOplrSzRv-0vmG0GRnWUeSz2ekz9XwrbxLX1Ovl8q6hNX_wlK34S711h-ouc1xfQCsLTg2uqhtBVGQg-Pi477Fgn7PWNUKTh45qiMr-6vThh6BxCadqefpg4cqj-coGTnyP_KMmWme5eo4L1iYBYEcw)

## Switch to the new Generators

This recipe previously used the old ``cmake`` generator as an attribute… It should have used ``cmake_find_package_multi`` but let’s just pretend it did. These can be replaced with [``CMakeToolchain``](https://docs.conan.io/en/2.0/reference/tools/cmake/cmaketoolchain.html) and ``CMakeDeps`` respectively.

This change creates a lot of difference.

![diff new generator vs old helper](https://lh4.googleusercontent.com/xdHPxK5OieGYAg1Nf9VbP0nYnUidEIR-a_lsFVBBgmaCWiME0KhtnWDc4InqIow0oZqutmchgZhXiLDP3cWkxR6tmqfeIUkw7Q6pteQoRWghunzqPT4FuLngiyEGPBNSbye8D3aW_7vM_lw2EewQpg3qVuNFoR01CN3dGWk7xvQAS5oMg3owH72M-w)

- We no longer pass CMake configuration options to the build helper.

  - That responsibility with given to the new toolchain.
  - CMakeDeps will generate the files required for RESTinio’s calls to ``find_package``

- ``cmake.definitions`` can be replaced by ``tc.variables``

The best part is cleanup! We can also remove the old generators attribute along with the old “cmake wrapper” that we used to use to call the old ``cmake`` generators ``include(conanbuildinfo.cmake)`` and ``conan_basic_setup()``

![diff build method](https://lh6.googleusercontent.com/EnqlmgX_WvCe9uSg6ekDqIkxGD8hUbkzKtO3N2goc8VmivB_pGFGbzqqLyJ8OMG2N8MQ_3w364w0KwprdChmDQr5ux--NTJq8M-NqOCxcG01tYhq1UA-gfRcCqx2c9J12lAK1tpwN492teFp2ahhPW_mQpUeU2a4zIEQ7zn-YpIG8OObUha7INSBsw)

This is sadly where we uncover our first caveat… this “cmake wrapper” we used in ConanCenterIdex sometimes hides functionality. In this particular example, it directed the build help to the correct subfolder of RESTinio with its ``CMakeLists.txt``. With ``add_subdirectory(source_subfolder/dev/restinio)`` so we will need to move this into the recipe.

Thankful this is a pretty common case and the new build helper can be configured correctly.

![diff build methods pt2](https://lh6.googleusercontent.com/lfTqL25PkFCD8Iw-l_zK3peA19bTkhg_lpaMCl0ZZ5uPzK6IFJumv2AnXWJTtreVtJ98wnwOfm0WAUr99Gk7DIL0KQ6u_fCi1srLumQS1GlzViPxEuBqQTr90eWwRxxAOi5rnBiAcBDxVyls6w0eH1tXuXeNuwijvdG6ug7doBxrOODZ5y2y6CSfVg)

We can simply pass the ``build_script_folder`` argument to let it know the “source folder” which will be used when it configures CMake.

## Tackling the validate method

This is the most complicated part. In Conan 2.0 we will drop the ``Visual Studio`` compiler for the ``msvc`` compilers. There’s a lot of reason why, so it might be worth checking out the [Conan Tribe Proposal](https://github.com/conan-io/tribe/blob/main/design/032-msvc_support.md) where this was decided.

Thankfully we don’t need to think about this too much as the Community has already figured out the best way of going about this. Check the [CMake Template Package](https://github.com/conan-io/conan-center-index/blob/master/docs/package_templates/cmake_package/all/conanfile.py#L90) from ConanCenterIndex we can see there’s a new helper ``check_min_vs`` that handles the new compiler.

![diff validate mthod](https://lh4.googleusercontent.com/M-8F-pfrnSKSDGuz2FqUMq_I7eZDI4RanbKXbrKdNZrijyF__su5OrKtihbeh0Q0ZBV6zm9h7HR_Y3uzR_0SrtqmgKG_uCnvhobcGrFQb3ymWJwwU_FutQr6JDLeYriV4TsxcSsvvmrwdqE7rVS525F_TL3V1w_Gnq7lQ1GqtA_ZZsQMMdCYnUPjRQ)

There’s a few noteworthy Conan 2.0 changes:

- ``self.settings.compiler`` became ``self.info.settings.compiler``
  - This is actually a migration pain point we are seeing in ConanCenterIndex, there are some trade-offs.
- [``check_min_vs``](https://docs.conan.io/en/2.0/reference/tools/microsoft/helpers.html#check-min-vs) is added

Also we no longer print warnings, this is because the convention in ConanCenter causes a lot of noise for the considerable group of users that have custom compilers or define their own with custom settings.

## Updating package id

This is a pretty easy one, and generally the last step. The old ``header_only`` has been replaced with a ``clear`` to make it more obvious what it’s doing.

![diff package id](https://lh6.googleusercontent.com/xdo5uBZlKIUdpGi3eEkLNOSzjjE6QnRTYAMnMI1_72zuT4nDROmNxExYn452ACSzOvlECvMEO_vD17P9Y_EO_fWIXGjAAmPh2tNzQmQr5YiYE0Ul7nnux6tClKyoOxV5fRc5YJBvZcgk187ZNVg8cugV8YH9V4VUoCTKerg6MT86cIrmzHO6pni59w)

## Package info and cpp folders

We will once again need to add a few lines to help optimize the new generators.

The layout does a lot of work for use, including helping to set up the ``cpp_info`` with folders for binaries, frameworks, and libraries. As we are packaging a header only project, these need to be explicitly set to empty.

## Test Package

This is an important part of the recipe since we still want to support 1.x all the while adding 2.0 support. There’s a lot of steps here but it’s pretty straightforward.

- Create a new folder ``test_v1_package``
- Move the ``test_package/conanfile.py`` to ``test_v1_package``
- Copy the ``test_package/CMakeLists.txt`` to ``test_v1_package``
- In the original ``test_package/CMakeLists.txt`` remove the lines to the old generator
  ![diff old test package cmake list](https://lh3.googleusercontent.com/VxqOvH7ZX37BPlC5EFCpNM1efSIRP1IYPor8i9b1iw8vaR9ppAUXrPoGIXRhSU3yPU13lwNgYccICkMMhKdSVb0zMvPvP_BTNAvfQyY_PwrMP43djvC7p50ER8KaIkb-GWhxHzCqz_2YAG3dkgSW3V0fwXSLaYYbncR9jBMS8gtLawvHjNm2h4doZA)
- Change the copied file ``test_v1_package/CMakeLists.txt`` to pull the source files form the original location ``../test_package/test_package.cpp`` to not duplicate files
- Download the new ``test_package/conanfile.py`` from the [ConanCenterIndex template](https://github.com/conan-io/conan-center-index/blob/master/docs/package_templates/header_only/all/test_package/conanfile.py)

That should do it.

If you are looking for the full diff, you will be interested in <https://github.com/conan-io/conan-center-index/pull/13338> which is the final product and was merged!
