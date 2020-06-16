---
layout: post
comments: false
title: "Conan Docker Tools - Official docker images for creating C++ packages for ConanCenter"
description: This post reviews the Conan Docker Tools project, its successes, failures and future.
tags: docker infrastructure devops
---

For a uniform distribution of packages to be possible, Conan needs an infrastructure that allows a homogeneous environment for the construction of packages. This solution has always been thought of since the beginning of the project and has taken on a large proportion throughout its development. In this post we will cover the history, problems and solutions covered in the [Conan Docker Tools](https://github.com/conan-io/conan-docker-tools) project, the Conan appendix focused on Docker images.

## Prologue

With the initiative to establish a standardization for the construction environment used in the CI services, for the Conan Community and Bincrafters projects, the use of Docker was the option of greater acceptance due to the size of images generated and ease of maintenance.

So the **Conan Docker Tools** project was started, supporting a minimum number of Docker images, all based on Ubuntu, with the standard compiler installed, according to the version of the distribution, in addition to some more support system packages.

## Evolution

The initial images varied between Ubuntu 14.04 (Trusty) and 17.10 (Artful), depending on the version of GCC and Clang available between distributions. Therefore, it was possible to obtain images for GCC 4.8 to GCC 7, in addition to Clang 3.9 and later. The Python version used was still 2.7 and a good portion of packages that are now distributed in the [Conan Center Index](https://github.com/conan-io/conan-center-index), were obtained through the system.

Over time, new images have been added, either because a new compiler version is available, or at the request of the community. Images made specifically for cross-compiling (ARM) were produced, in addition to others related to smaller versions of each compiler (up to GCC 6 only).

The size of each image was around 900MB, which contained the compiler with support for building 64-bit and 32-bit projects, in addition to Python 2.7, Conan and various utilities such as wget, vim, curl, ninja and valgrind. Although the final size was smaller than using a VM, it was still much larger than conventional images for CI purposes. After some time, some utilities were removed, such as vim and valgrind, as they were only needed for debugging purposes, which was less than 10% of cases. In addition, Python has been moved to version 3, however being installed through the pyenv project, giving greater flexibility in the desired version, regardless of distribution. This rework managed to reduce the image size by 15%.

## Symptoms of a problem

Despite efforts to accompany the release of new versions of the GCC and Clang compilers, it was not possible to use the same distribution, as the same compiler would only be available in a new version, which implied multiple distribution. However, there was a bigger problem, each distribution has a specific version of the glibc library, which is backward compatible only, creating a delicate situation among Conan packages. Such situation has been reported by the community, and it is well explained on the issue [#1321](https://github.com/conan-io/conan-center-index/issues/1321).

Packages for installers, that is, packages that only contained executables (cmake, 7z, ninja, ...) do not take the compiler into account for the package ID, so, regardless of the version of the compiler used, the package should be the same for each platform. This resulted in a problem related to the version of glibc, where it was necessary to build this type of package to the oldest possible version, to avoid errors when using the package. To this end, an image was built based on CentOS 6, associated with GCC 7, where the version of glibc was old enough to be compatible with any other image available in the project.

Over time and the evolution of compilers, we come to the following scenario:

![Ubuntu version]({{ site.url }}/assets/ubuntu_versions.png)

As can be seen, for each new version of a compiler, we will possibly have a new distribution and it will be incompatible with its previous versions due to the version of glibc. To better illustrate this situation, let's use the following example: The ``ninja/1.10.0`` is an installer package, that is, only the executable is packaged, and ``settings.compiler`` is not part of its package ID, therefore, the compiler and its version not taken into account. Consequently, if ``ninja/1.10.0`` package is built, using Ubuntu 18.04 (Bionic), with GCC 8 and glibc version 2.27, it will only be compatible with distributions with the same version of glibc or later, otherwise an error will occur at run time, due to the lack of the library in the requested version. This type of problem is known to the Conan community, and today it is one of the challenges to be solved in the Conan Center Index.

## Unique treatment

Despite following the evolution of the new versions, the maintenance cost and incompatibility factor increases with each new image, reaching an unsustainable situation. Therefore, it was decided that it would be better to opt for a redesign of the images, using only a common version, old enough to support previous versions of glibc, but new enough to be covered by the distribution support (Long Term Support).

The base image selected was Ubuntu Xenial (16.04), as it is LTS, still supported, and is old enough with glibc 2.23 available. The cost of opting for a single distribution version and supporting all compilers and their versions, is to build them from the sources, thus increasing the time of each work in the CI. How much time? Around 2x more than before. Let's show you a comparison between the current conan docker recipe for GCC 9 and, the new centralized version:

<table>
<tr>
<th>
Actual
</th>
<th>
New Version
</th>
</tr>

<tr>
<td style="vertical-align:top">
<pre>
{% highlight docker %}
FROM ubuntu:eoan

...

RUN dpkg --add-architecture i386 \
    && apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends \
       sudo \
       binutils \
       wget \
       git \
       libc6-dev-i386 \
       libc6-dev \
       linux-libc-dev:i386 \
       g++-9-multilib \
       ...
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100 \
    ...
    && useradd -ms /bin/bash conan -g 1001 -G 1000,2000,999 \
    ...
    && wget --no-check-certificate --quiet -O /tmp/pyenv-installer \
       https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer \
    && chmod +x /tmp/pyenv-installer \
    && /tmp/pyenv-installer \
    && rm /tmp/pyenv-installer \
    ...
    && update-alternatives --install /usr/bin/python python /opt/pyenv/shims/python 100 \
    ...

USER conan
WORKDIR /home/conan

RUN mkdir -p /home/conan/.conan \
    && printf 'eval "$(pyenv init -)"\n' >> ~/.bashrc \
    && printf 'eval "$(pyenv virtualenv-init -)"\n' >> ~/.bashrc

{% endhighlight %}
</pre>
</td>
<td style="vertical-align:top">
<pre>
{% highlight docker %}
FROM ubuntu:xenial

...

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends \
       sudo \
       build-essential \
       wget \
       git \
       libc6-dev \
       gcc \
       ...
    && rm -rf /var/lib/apt/lists/*

RUN wget --no-check-certificate --quiet -O /opt/gcc-${GCC_VERSION}.tar.gz \
      https://github.com/gcc-mirror/gcc/archive/releases/gcc-${GCC_VERSION}.tar.gz \
    && tar zxf /opt/gcc-${GCC_VERSION}.tar.gz -C /opt \
    && cd /opt/gcc-releases-gcc-${GCC_VERSION} \
    && ./configure --prefix=/usr/local \
                   --enable-languages=c,c++ \
                   --disable-bootstrap \
                   ...
    && make -j "$(nproc)" \
    && make install-strip \
    && cd - \
    && rm -rf /opt/gcc* \
    && apt-get remove -y gcc gcc-5 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
    ...

RUN groupadd 1001 -g 1001 \
    ...
    && useradd -ms /bin/bash conan -g 1001 -G 1000,2000,999 \
    ...

RUN wget --no-check-certificate --quiet -O /tmp/pyenv-installer \
      https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer \
    && chmod +x /tmp/pyenv-installer \
    && /tmp/pyenv-installer \
    ...

RUN pip install -q --no-cache-dir conan conan-package-tools cmake==${CMAKE_VERSION} \
    && chown -R conan:1001 /opt/pyenv \
    && find /opt/pyenv -iname __pycache__ -print0 | xargs -0 rm -rf \
    && update-alternatives --install /usr/bin/python python /opt/pyenv/shims/python 100 \
    ...

USER conan
WORKDIR /home/conan

RUN mkdir -p /home/conan/.conan \
    && printf 'eval "$(pyenv init -)"\n' >> ~/.bashrc \
    && printf 'eval "$(pyenv virtualenv-init -)"\n' >> ~/.bashrc


FROM base as release

RUN pip install -U conan conan-package-tools

{% endhighlight %}
</pre>
</td>
</tr>
</table>

The new recipe version is bigger than the current version, because it builds GCC from sources, and uses multi-stage builds feature. However, some points were preserved:
- System packages (APT) are required for basic utilities (e.g. wget, git, ...) and pre-required libraries for building (e.g. libsqlite3 for python)
- GCC and Python are configured as default by ``update-alternatives`` command
- A non-root user (conan) is added and used by default. That's a security recommendation from Docker community.
- *pyenv-installer* is used to install *pyenv*, thus, the Python version is flexible

The new version uses multi-stage builds feature for caching the *base* image and reusing it for any new Conan release. That strategy can save time when building Docker images.

Currently, the pull request [#204](https://github.com/conan-io/conan-docker-tools/pull/204) is implementing the new version of a base image, which should compose current and future compilers. In addition, this image should be used to generate Conan packages, in the Conan Center Index.

## Conclusion

The implementation of a construction environment for the distribution of packages and replication of behavior is an essential part for a package manager, without it, many unknown points are added to each error encountered during a construction, each development environment ends up being distinct and hard to be reproduced. However, the development and maintenance of an environment for construction is equally challenging and can result in several environments, as distinct and incompatible as if there were no specific environments.

Conan Docker Tools, demonstrated that there is a higher price when choosing to update the distribution used, instead of building the compiler through the sources, to maintain the ease and agility in using a version of the same compiler already available in the distribution. With the introduction of new compilers and their versions, incompatibilities between versions of glibc, and increased time for maintenance start to cost more than just updating the compiler.

As an evolution for this use case, a new image, based on a single distribution version, will be used for all compilers and their versions, correcting the extensive variety of images and their multiple versions.

If you are interested to learn about these images, please visit [conan-docker-tools](https://github.com/conan-io/conan-docker-tools) repository, or if you want to make a comment about this new approach, please, comment on the issue [#205](https://github.com/conan-io/conan-docker-tools/issues/205).
