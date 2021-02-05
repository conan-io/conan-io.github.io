---
layout: post
comments: false
title: "JFrog announces sunset of the Bintray service"
---

Bintray is a free service that JFrog has provided for community and open source users to distribute their packages, including Conan packages, and artifacts. As a Conan user you might know about [ConanCenter](https://conan.io/center), the central repository for Conan open source packages, and also that ConanCenter has been hosted in Bintray.

JFrog has [announced the sunset of Bintray](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/). This sunset will happen May 1st, 2021.

**ConanCenter will not be sunset**. On the contrary, ConanCenter, with the new package submission process and the automatic build service in the [conan-center-index repository](https://github.com/conan-io/conan-center-index) **will get more resources and we will keep investing and improving it**.

For users that were hosting their own Bintray repositories for Conan packages, the best alternative would be to self-host an instance of [Artifactory Community Edition (CE) for Conan](https://conan.io/downloads.html), which is completely free and doesn’t have capacity restrictions.  Alternatively, JFrog now offers [cloud-hosted instances of the JFrog Platform]([git checkout -b add_links_bintray_sunset](https://jfrog.com/artifactory/start-free/?isConan=true)), with a free tier designed for individual with reduced usage. If your instance will be used for an open-source project, you can apply to [JFrog’s OpenSource program for sponsorship](https://jfrog.com/open-source/), which provides increased resources at no cost to qualifying projects.

We know that this will have a major impact for some users. We understand that closing a service that users have been enjoying for free for many years will inevitably cause some pain. We will do our best to help our users migrate to alternative strategies, and hope we can minimize the inconvenience and disruption it will cause.

On the positive side, this will also give JFrog more capabilities to focus on our products as well as our community and open source projects, including ConanCenter, the free ArtifactoryCE, and Conan itself.

If you have any questions, please feel free to write to [conancenter@jfrog.com](mailto:conancenter@jfrog.com).
