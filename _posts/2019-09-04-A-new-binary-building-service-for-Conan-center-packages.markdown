---
layout: post
comments: false
title: "A New Binary Building Service for Conan-center Packages"
subtitle: "Early Access Program EAP"
---


[Bintray Conan-center](https://bintray.com/conan/conan-center) is the main repository for curated Conan packages. Users have been able to contribute to it by uploading packages to their own Bintray repositories, then submitting them via an "Inclusion Request" process. 

Bintray repositories account for a large number of downloads (24 million downloads so far in 2019 including many terabytes of transfers), which is attributed to the decentralized nature of Conan. While Conan-center is the most popular one, some other repositories like the Bincrafters, contain a larger number of packages and account for many of those downloads.

So one may ask, why aren’t there more packages in the Conan-center? The truth is that the submission process and contributing packages is difficult. Not only is there a new process to learn, but also creating all the binaries and uploading them to the personal Bintray repos, prior to submitting them to Conan-center is difficult, and requires a lot of work, especially when setting up the CI services. We listened to your feedback, and this is the reason for launching this new service


# A new way to contribute packages to Conan-center

The new process for contributing packages to the Conan-center uses the git repository [conan-center-index](https://github.com/conan-io/conan-center-index). This repository will contain all the package recipes upon which the binaries will be built and then uploaded to the Conan-center. The repository readme and wiki describe how to contribute new packages, new versions, and fixes using the pull-requests to this repository. 

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-09-04/conan-center-build-service.png" align="center" alt="Conan-center binary build service"/>
</p>

The contributor workflow is as follows:

1. Fork the [conan-center-index](https://github.com/conan-io/conan-center-index) git repository, and then clone it.
2. Create a new folder with the Conan package recipe (conanfile.py)
3. Push to GitHub, and submit a pull request.


Once the contributor’s pull request is submitted, the conan-center-index CI process of creating and uploading the packages to the Conan-center begins.


1. The CI launches the build, runs a series of automated quality checks, builds package binaries for multiple configurations and output results and alerts on any possible error messages as GitHub comments. The build logs can be directly downloaded from GitHub. 
2. The pull request is reviewed. 
3. After the pull request is merged, the built binaries are automatically uploaded to Conan-center


---
**Note:** New packages uploaded to the Conan-center will not use ``user/channel``. This is a new Conan 1.18.2 feature, therefore this version or greater is needed to be able to consume those packages with the following syntax:

```
[requires]
pkg1/1.2.3
pkg2/4.5.6
```

---
<br/><br/>

# Moving towards a community-focused flow

The benefits of this new proposed flow are:

- It is a more natural way to contribute, only a GitHub account is needed, and no additional requests besides a pull-request is necessary. It is also the most natural approach for community contributions and collaborating to maintain the package recipes. It will also serve as a centralized resource for learning how the different open-source libraries are packaged.
- The conan-center-index CI service will implement building binaries for many different configurations, including more than 100 different binaries, with different operating systems (Windows, Linux, Mac OSX), compilers (Visual Studio, GCC, apple-clang), compiler versions, debug/release, static/shared, etc. No need to further set up your own CI with other external services to create the packages (of course you can still have your own CI for developing and testing your code, but no Conan package creation will be necessary there).
- Submitting new versions and fixes go through the same process. According to the previous process, once a package was accepted in the Conan-center, the new package versions could be uploaded without the need to be revalidated. With this new flow, all modifications to the existing recipes and new versions will also go through the same build and validation process. Adding new package versions will usually be done by adding the new version to a list (and submitting the pull request), which can be done by anyone in the community.
- It will be much easier to produce new binaries when new compiler versions are released, which happens quite frequently. For example, Apple-Clang new versions quickly affect users because of the aggressive updates, while it takes time for the community to produce new binaries. With this new flow, firing re-builds of the entire repository for new compiler versions will now be possible. Also, keeping the Conan-center consistent, by using the latest versions of packages by default when possible, will be possible.
- It will be possible to maintain multiple versions of the same package with the same recipe and some metadata. Fixes to those recipes will automatically apply to all those versions and by being built by CI service, will extensively improve package maintenance and backporting fixes.
- The new quality checks, for example, the requirement that ensures that all package names use lowercase, will help to automate reviews and achieve higher quality packages. They are implemented as hooks, so users can also use them even before submitting recipes.

# How to start using it: Early Access Program

The repository is now public, anyone might see it, submit issues, requests, etc. Consumers of packages from Conan-center might start using the new packages as soon as they become available just by updating their Conan clients.

The Early Access Program applies to early contributors. The CI will only allow registered contributors, otherwise, no build will be produced. The idea is to be able to improve the system and the user experience before opening it to the whole community.

If you want to be part of this EAP, please send a petition to ``info@conan.io`` with the subject ``[EAP access]`` or add a comment on [this GitHub issue](https://github.com/conan-io/conan-center-index/issues/4). After you have requested access, please go to [the Wiki](https://github.com/conan-io/conan-center-index/wiki) for more details about the contribution process.

For any related issue, suggestion, please use the [repository issues](https://github.com/conan-io/conan-center-index/issues). Looking forward to making Conan-center bigger and more useful for the community!
