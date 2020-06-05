---
layout: post
comments: false
title: "Conan Docker Tools - A case of study - Conan.io Official Blog"
description: This post reviews the Conan Docker Tools project, its successes, failures and future.
tags: docker infrastructure devops
---

For a uniform distribution of packages to be possible, Conan needs an infrastructure that allows a homogeneous environment for the construction of packages. This solution has always been thought of since the beginning of the project and has taken on a large proportion throughout its development. In this post we will cover the history, problems and solutions covered in the [Conan Docker Tools](https://github.com/conan-io/conan-docker-tools) project, the Conan appendix focused on Docker images.

## Prologue

With the initiative to establish a standardization for the construction environment used in the CI services, for the Conan Community and Bincrafters projects, the use of Docker was the option of greater acceptance due to the size of images generated and ease of maintenance.

So the Conan Docker Tools project was started, supporting a minimum number of Docker images, all based on Ubuntu, with the standard compiler installed, according to the version of the distribution, in addition to some more support system packages.

## Evolution

The initial images varied between Ubuntu 14.04 (Trusty) and 17.10 (Artful), depending on the version of GCC and Clang available between distributions. Therefore, it was possible to obtain images for GCC 4.8 to GCC 7, in addition to Clang 3.9 and later. The Python version used was still 2.7 and a good portion of packages that are now distributed in the Conan Center Index, were obtained through the system.

Over time, new images have been added, either because a new compiler version is available, or at the request of the community. Images made specifically for cross-compiling (ARM) were produced, in addition to others related to smaller versions of each compiler (up to GCC 6 only).

The size of each image was around 900MB, which contained the compiler with support for building 64-bit and 32-bit projects, in addition to Python 2.7, Conan and various utilities such as wget, vim, curl, ninja and valgrind. Although the final size was smaller than using a VM, it was still much larger than conventional images for CI purposes. After some time, some utilities were removed, such as vim and valgrind, as they were only needed for debugging purposes, which was less than 10% of cases. In addition, Python has been moved to version 3, however being installed through the pyenv project, giving greater flexibility in the desired version, regardless of distribution. This rework managed to reduce the image size by 15%.

## Symptoms of a problem

Despite efforts to accompany the release of new versions of the GCC and Clang compilers, it was not possible to use the same distribution, as the same compiler would only be available in a new version, which implied multiple distribution. However, there was a bigger problem, each distribution has a specific version of the glibc library, which is backward compatible only, creating a delicate situation among Conan packages.

Packages for installers, that is, packages that only contained executables (cmake, 7z, ninja, ...) do not take the compiler into account for the package ID, so, regardless of the version of the compiler used, the package should be the same for each platform. This resulted in a problem related to the version of glibc, where it was necessary to build this type of package to the oldest possible version, to avoid errors when using the package. To this end, an image was built based on CentOS 6, associated with GCC 7, where the version of glibc was old enough to be compatible with any other image available in the project.

Over time and the evolution of compilers, we come to the following scenario:

![Ubuntu version]({{ site.url }}/assets/ubuntu_versions.png)

As can be seen, for each new version of a compiler, we will possibly have a new distribution and it will be incompatible with its previous versions due to the version of glibc.

## Unique treatment

Despite following the evolution of the new versions, the maintenance cost and incompatibility factor increases with each new image, reaching an unsustainable situation. Therefore, it was decided that it would be better to opt for a redesign of the images, using only a common version, old enough to support previous versions of glibc, but new enough to be covered by the distribution support (Long Term Support).

The base image selected was Ubuntu Xenial (16.04), as it is LTS, still supported, and is old enough with glibc 2.23 available. The cost of opting for a single distribution version and supporting all compilers and their versions, is to build them from the sources, thus increasing the time of each work in the CI. How much time? Around 2x more than before.

Currently, pull request [#204](https://github.com/conan-io/conan-docker-tools/pull/204) is implementing the new version of a base image, which should compose current and future compilers. In addition, this image should be used to generate Conan packages, in the Conan Center Index.

## Conclusion

The implementation of a construction environment for the distribution of packages and replication of behavior is an essential part for a package manager, without it, many unknown points are added to each error encountered during a construction, each development environment ends up being distinct and hard to be reproduced. However, the development and maintenance of an environment for construction is equally challenging and can result in several environments, as distinct and incompatible as if there were no specific environments.

Conan Docker Tools, demonstrated that there is a higher price when choosing to update the distribution used, instead of building the compiler through the sources, to maintain the ease and agility in using a version of the same compiler already available in the distribution. With the introduction of new compilers and their versions, incompatibilities between versions of glibc, and increased time for maintenance start to cost more than just updating the compiler.

As an evolution for this use case, a new image, based on a single distribution version, will be used for all compilers and their versions, correcting the extensive variety of images and their multiple versions.

If you are interested to learn about these images, please visit [CDT](https://github.com/conan-io/conan-docker-tools) repository, or if you want to make a comment about this new approach, please, comment on the issue [#205](https://github.com/conan-io/conan-docker-tools/issues/205).
