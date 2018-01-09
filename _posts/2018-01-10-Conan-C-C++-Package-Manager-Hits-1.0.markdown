---
layout: post
comments: false
title: Conan C/C++ Package Manager Hits 1.0
# other options
---

Since first being released over two years ago, Conan has evolved rapidly and introduced many improvements. Our great community of users, who quickly adopted Conan, have contributed much to the project, and thanks to valuable feedback, many big and important features were developed in all the releases leading to version 0.30.


A commitment for stability
==========================

Conan 1.0 also introduces some great new features. The new “build” and “target” OS and architecture settings provide better cross-building support beyond the standard settings which correspond to the “host” settings that apply to the system on which the compile binaries will run. Windows subsystems (Cygwin, MSYS, MSYS2, WSL) have been modeled in settings, and tools that use them when building packages have been developed.

Beyond the new features, the most important thing that lead to Conan 1.0 is trust. Many users and companies have adopted Conan and rely on it for their production systems. Through the versions building up to 1.0, these companies have been an incredible source of feedback and improvements, and their flexibility in letting us make changes and even “break” things has allowed us to evolve very quickly while they adapted to these changes as necessary.

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-01-10/conan1.0users.png" align="center"/>
</p>


Now it’s time to reward the trust we have received; Conan 1.0 is mainly a commitment to stability and robustness. From now on, one of our highest priorities is not to break anything when we add new features and functionalities. Maintaining your scripts and projects will only mean upgrading them to use new features without having to modify them in any way to keep supporting existing ones. To support this goal, we have migrated our testing and CI to our own infrastructure that uses Jenkins. This allows us to do many more tests in a fraction of the time. We will continue to expand our testing regimen to include end-to-end tests, and more exhaustive testing of compilers, tools and build systems used in the C and C++ ecosystems.

Growing team
============

To support the challenges ahead, we are growing our development team. Daniel has just joined us, another engineer will join us in two weeks, and we’re looking for some more talented developers. We’re located in Madrid, a great, fun and friendly city. So if you’re here, or are willing to relocate, [drop us a line](info@conan.io).

If you do join us, here are some of the challenges you’ll work on. Our top priority for 2018 is the Open Source community and managing the long queue of requests for Open Source packages to be included in [conan-center](https://bintray.com/conan/conan-center), the central, public repository for Conan packages. We will also be working on improving usability of Conan with Bintray as well as integrations with more tools like IDEs.


The journey has just begun
==========================

Conan 1.0 is a milestone and a celebration rolled into one. It’s a huge word of thanks to the community and all those who contributed by giving pure Open Source LOVE! We couldn’t have come this far without the support of our users testing and providing feedback, or without the [Bincrafters](https://bincrafters.github.io) community doing an amazing job creating OSS packages, or without the full time maintenance and support sponsored by JFrog. You ALL rock. 


We have come this far, and it has taken us a while, but Conan 1.0 is not the goal, it’s just the beginning. Join this amazing journey and visit [conan.io](https://conan.io).

