---
layout: post
comments: true
title: JFrog Bintray Adds Support for Conan C/C++ Repositories  and Launches Conan-center Managed Central Repository
# other options
---


We are very excited to announce support for Conan repositories on  JFrog Bintray, the Universal Distribution Platform.

Currently serving more than 2 Billion downloads per month, Bintray offers developers the fastest and most reliable way to publish
and consume software releases.In addition, JFrog will soon launch conan-center which will become the central public
repository for Conan packages and the ultimate resource for OSS packages for C/C++ development.

Conan.io: Current challenges
============================

Since being launched, Conan gained popularity as a package manager for C/C++ developers, and conan.io quickly became the
central public repository for Conan C/C++ packages.  However, one of the problems with conan.io is that it is not moderated or curated.
Every registered user can freely upload packages leading to variable quality of packages available on conan.io.
Some packages met acceptable standards of  software quality, but others didn’t. Furthermore, some packages were uploaded
multiple times by different developers, which confused some of our users.
Conan.io also lacks some very important features necessary to manage OSS project releases, like organizations and access control.
Particularly lacking is a public API to facilitate automation  and integrating its usage into development and DevOps flows.


Conan repos in Bintray: Benefits
================================

With support for Conan repositories Bintray offers a stable, reliable and convenient platform where  C/C++ developers
and DevOps engineers can host their software packages.

With Bintray, Conan users get the following features for their software packages:

  1. They can  create and manage any number of their own Conan repositories in Bintray, with fine grained user and
    permissions management, and new ways of collaborating.

  2. A rich REST API gives them full  control over every aspect of their software distribution.
    They can  manage access to their content, collect logs and analytics, upload and download files, create access keys and entitlements and more.

  3. A scalable, robust, and safe platform with CDN (US and EU clusters) to provide enterprise grade performance and
    reliability with data being backed up and replicated over multiple cloud providers.

  4. Bintray will provide trust based signing of packages based on developers’ public identity (github).

And since it’s likely that C/C++ developers and DevOps also use other technologies, they will be happy to know that as a universal distribution platform,
JFrog Bintray supports all major package formats -  including Docker, CocoaPods, Chef, Puppet, Bower, Vagrant, Git LFS,
PyPi, Debian, npm, RubyGems, RPM, Opkg, NuGet, PHP Composer.


<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2017-05-25/arch.png" width="60%" align="center"/>
</p>


Conan-center
============

In addition to user repositories, we are launching conan-center, the new central public repository for Conan C/C++ packages.
Conan-center is a curated repository, that will accept inclusion-requests from user repositories, to create a free,
trusted, maintained and high quality central repository of OSS C/C++ packages.

Over the next few weeks, we will be taking steps to copy the current central repository hosted at conan.io to Bintray.
You can read about the process in the (Conan documentation)[http://docs.conan.io/move_to_bintray.html].
If you run into any issues, you are welcome to contact us at **info@conan.io**.

With Conan repositories and conan-center, Bintray provides the next generation of conan servers for worldwide distribution
of packages for the C and C++ communities. Start using it today in conan.io and bintray.com.

