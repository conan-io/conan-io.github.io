---
layout: post
comments: false
title: "ConanCenter is rolling out Conan 2.0 recipes - Are you ready?"
meta_title: "ConanCenter is rolling out Conan 2.0 recipes - Are you ready?" 
meta_description: "Learn how to safely consumer recipes using your very own ArtifactoryCE"
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "ConanCenter is rolling out Conan 2.0 recipes - Are you ready?d",
 "alternativeHeadline": "Learn how to setup your enviroment to consumer recipes from ConanCenter",
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

By Christopher McArthur, Conan Developer Advocate; inspired by Eric Lemanissier, ConanCenter contributor.

Conan 2.0 is coming and the community is pushing ahead. There’s been over 100 pull requests merged and you might see breaking changes!

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2022-09-01/conancenter-2-migration.png" align="center" alt="ConanCenter Pull Request Activity"/>
</p>

This graph shows the wave of new Pull Requests in the last two weeks. The community knocked out a new record for weekly Pull Requests. There were a staggering 314 open at one time, usually it’s ~140 for reference.

## Why are things changing?

ConanCenter has always maintained recipes consumers need to have an up to date client for the best experience. The reason is there are constantly improvements and fixes being made, sometimes those require new Conan features to be possible. There are usually waves of new features, patches and fixes that allow for even better quality recipes.

The Conan 2.0 beta is out and we, The Conan team and the Community, are making sure all the new features work - transparently - by testing it on the 1300+ recipes of open source projects that are available through ConanCenter. Details are in the [2.0 Road Map](https://github.com/conan-io/conan-center-index/blob/master/docs/v2_roadmap.md).

If you want to get your project ready check the [Conan 2.0 Migration Guide](https://docs.conan.io/en/latest/conan_v2.html) for more information.
Looking to get involved in open source? You can help with ConanCenter’s migration by reading the [ConanCenter Migration](https://github.com/conan-io/conan-center-index/blob/master/docs/v2_migration.md) specific documentation.

## What signs should you look for?

The one you are most likely to see is “Current Conan version (1.42.0) does not satisfy the defined one (1.50.2)”. The migration uses new features and recent bug fixes only available in recent client versions.

You might see missing imports, sometimes contributions do not set the required versions high enough and those new features might be missing. This might be a sign your client is out of date. Otherwise, please [open an issue](https://github.com/conan-io/conan-center-index/issues/new?assignees=&labels=bug&template=package_bug.yml&title=%5Bpackage%5D+%3CLIBRARY-NAME%3E%2F%3CLIBRARY-VERSION%3E%3A+SHORT+DESCRIPTION) so we can get it fixed!

Components that no longer exist. For instance, in CMake you might call ``find_package(Boost REQUIRED COMPONENTS filesystem regex)`` and see a new error message that filesystem and regex are not found. These need to be declared in the recipe and the names correct set for each generator which may not be caught in code review. 

Missing environment variables, this is more rare but some recipes expose tools or paths needed to function. These also need to be migrated and they might be missing when you update your project.

## What can I do to avoid this surprise?

This has always been a concern from ConanCenter consumers. Take a look at the [ConanCenter Consumer Recipes](https://github.com/conan-io/conan-center-index/blob/master/docs/consuming_recipes.md) guide for more details.

Conan is very flexible; you can add your own remote or modify your client’s configuration for more granularity. We see the majority of Conan users hosting their own remote, and only consuming packages from there. For production this is the recommended way to add some infrastructure to ensure stability. This is generally a good practice when relying on package managers - not just Conan.

Here are a few choices:

- [Running your own Conan Server](https://docs.conan.io/en/latest/uploading_packages/running_your_server.html) - great for local ad-hoc setups
- [Cache recipes in your own ArtifactoryCE](https://docs.conan.io/en/latest/uploading_packages/using_artifactory.html) - recommended for production environments

Using your own ArtifactoryCE instance is easy. You can [deploy it on-premise](https://conan.io/downloads.html) or use a [cloud provided solution](https://jfrog.com/start-free/?isConan=true) for **free**. Your project should [use only this remote](https://docs.conan.io/en/latest/reference/commands/misc/remote.html?highlight=add%20new) and new recipe revisions are only pushed to your Artifactory after they have been validated in your project.

The minimum solution, if still choosing to rely on ConanCenter directly, involves small changes to your client configuration by pinning the revision of every reference you consume in your project using using:

- [recipe revision (RREV)](https://docs.conan.io/en/latest/versioning/revisions.html) can be added to each requirement. Instead of ``fmt/9.1.0`` you can add a pound (or hashtag) to the end followed by the revision ``fmt/9.1.0#c93359fba9fd21359d8db6f875d8a233``. This feature needs to be enabled in Conan 1.x, see the [Activation Instructions](https://docs.conan.io/en/latest/versioning/revisions.html#how-to-activate-the-revisions) for details.
- [Lockfiles](https://docs.conan.io/en/latest/versioning/lockfiles.html) can be created with the ``conan lock create`` and read with by adding `` --lockfile=conan.lock`` to ``conan install`` or ``conan create`` commands. See the [lockfile introduction](https://docs.conan.io/en/latest/versioning/lockfiles/introduction.html#) for more information.
  - Please, be aware there are some known bugs related to lockfiles that are not being fixed in Conan v1.x - we are really excited for the 2.0 improvements to be widely used.

Both of these give you better control and will allow you to choose when to upgrade your Conan client and the recipes you are using. 

## Where is the best place to ask for help?

GitHub Issues are for “official” answers, most often you’ll get responses from the Conan team. For “community” support [Cpplang’s Conan Slack Channel](https://cpplang.slack.com/archives/C41CWV9HA) is a quick way to help. We know issues might crop up so we are making sure to smooth the process.
