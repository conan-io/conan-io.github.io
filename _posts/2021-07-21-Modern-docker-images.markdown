---
layout: post
comments: false
title: "Modern Docker Images to build C/C++ projects for ConanCenter: How I Learned to Stop Worrying and Love the Old images"
meta_description: "The New Docker images which should become the official to build all C/C++ package on Conan Center Index
and distribute under Conan Center. They should be adopted by default for all users. Fixed glibc and libstdc++ compatibility
problems and unified all Docker recipes using multistage-build on Jenkins"
---


This is the continuation of the initial [post](https://blog.conan.io/2020/06/17/Conan-Docker-Images.html) about new
Docker images for the Conan Center.
Preferably read the first post to understand the problem, the motivation and the proposed
solution for Conan Docker Tools. In this post we will continue the proposed implementation,
highlight the problems encountered during development and the result of this long journey that
should improve in many aspects the way we use Docker images for Conan.

## The importance of the community

Right after the presentation of the first proposal of the previous post, we had a great and
important feedback from the community involving Conan. This shows how important these Docker images
are not only for the Conan Center, generating official packages for general distribution, but also
for people who own their personal projects and use the images to validate and build their Conan
recipes, as well as the companies they build packages through sources.

After long feedback and new formulations, we understood that it was necessary to make changes to
the initial concept, we realized that we could not modify the existing images for better
maintenance, given the risk of breaking the behavior between users, so we started from scratch
again, formulating a more balanced version between Conan Center and users. Unfortunately we can't
keep an old version long enough to support older compilers, but we believe this is the price of
progress, we need to sacrifice older versions for better maintenance for newer versions.

That said, it is clear how important the involvement of the entire community has been and how much
we take into account its manifestation. We are grateful to the great tribe that surrounds Conan and
makes it more and more complete.

## Conan Docker Images: Revisited

The pull request [#204](https://github.com/conan-io/conan-docker-tools/pull/204) showed us some weak points to consider:

* Installing Clang via LLVM's APT repository does not guarantee full compatibility with ``libstdc++`` version used to
build GCC.
* APT packages that were requirements for GCC and Clang were still present, further inflating the final image.
* The packages provided through Ubuntu do not have older versions available, in case a new version comes along. This
affects the reproducibility requirement.
* Older compilers were always an issue in terms of maintenance once they arrived in the EOL (end-of-life) state. It was
necessary to update the PPA address and build the images again
* The continuous integration service used, although it was considerably fast, it was not possible to customize and
prioritize the build, if necessary.

Noticing the listed issues, we took a more radical solution, even though it took more time to implement, but resulted
in something better in terms of maintainability and practicality.

Therefore, we decided to abandon PR #204 and start again from scratch, considering the items listed above.

## A new plan: Using the same base image

Before we start implementing new dockerfiles with their proper corrections, we first need to understand what the objective
behind it all is. We would like to understand what the expectation is for these new images 2 years from now. As we have
seen before, in a few years with the current approach we are already maintaining over 40 different dockerfiles. Also, one of the points discussed is whether there will be
rotation to avoid the accumulation of old images and their restrictions in terms of maintenance.

For current and already available images on hub.docker, these will be kept but no longer supported (new versions will
not be introduced). Your recipes and images will remain available, as their immediate removal would result in
catastrophic failure for many users. They will eventually be removed, but at a distant date and to be defined.

As for the new images, these will be adopted as official and widely promoted for use by all users. The transition
to the new images in Conan Center should take place in a few months after release, because it will be necessary to rebuild the packages that already
exist in the Conan Center and replace them, this is to ensure full compatibility between packages. As for rotation and
maintenance, we believe it is necessary to rotate supported compilers over time, to avoid a large build, effort and
maintenance load for old images and packages that are not always used by the community. Therefore, the following rule
will be adopted:
* Clang will be supported in the 3 newest versions. Older versions will be available for download but will not receive
updates.
* GCC on the other hand, is widely used for the Linux environment and only version 4.x was left out.

One of the problems we would like to solve is the compiler used and its libraries, we always wanted to be independent
of the Linux distribution. In the initial pull request, we built the GCC from sources, while the Clang uses
prebuilt. So, we chose to build both from sources in order to have more control over the compiler used.

The library ``libstdc++`` is distributed along with the GCC project. We chose to use a single version of the library,
which
was neither the newest, to allow older distributions to use, but also not so old, so that new features can be consumed
by newer compilers. The version chosen was ``libstdc++.so.6.0.28``, the same distributed with GCC 9 and 10.

Ubuntu 16.04 Xenial LTS is still the base used, its support will be until April 2024. After that date, we will need to
update the images to a newer version of the distribution, in addition to rebuilding all available official packages.

So forward thinking is having fewer images, but better support, without the drastic breakage and incompatibility issues.
To summarize the plan:

* Ubuntu 16.04 LTS as base Docker image
* Build Clang and GCC from source
* Use libstdc++.so.0.6.28 for all new Docker images
* Use glibc 2.23 for all new Docker images
* Rotate old compiler versions to keep better support in the future

## From blueprint to prototype: Writing the new Docker recipes

During prototyping, we realized that we could divide the process of building a Docker image into 3 phases:
* The base, where all common packages are installed to all images, such as Python, git, svn, etc, in addition to the
non-root user configuration.
* An image where only the compiler is built. In this container can be installed packages referring to the compiler build
only, which will not be present in the final image, for example, Ninja, which is used for LLVM.
* Finally, we need to merge the base to the produced compiler into a single image, without adding extra packages, but
still reusable between each compiler version.

For the case of the base image, this one is still quite modular, just changing the variables file to update the package
to be installed. The complete recipe can be obtained
[here](https://github.com/conan-io/conan-docker-tools/blob/feature/single-image/modern/base/Dockerfile), but let's look
at a few pieces:

{% highlight docker %}

ARG DISTRO_VERSION
FROM ubuntu:${DISTRO_VERSION}

ENV PYENV_ROOT=/opt/pyenv \
    PATH=/opt/pyenv/shims:${PATH}

ARG CMAKE_VERSION
ARG CMAKE_VERSION_FULL
ARG PYTHON_VERSION
ARG CONAN_VERSION

{% endhighlight %}

Now, both the distribution version and the installed packages are configurable in terms of version used. Previously, a
script was used to update all 42 recipes as needed!

{% highlight docker %}

RUN printf '/usr/local/lib64\n' >> /etc/ld.so.conf.d/20local-lib.conf \
    && printf '/usr/local/lib\n' > /etc/ld.so .conf.d/20local-lib.conf \
    ...

{% endhighlight %}

In order to not be affected by system packages or Conan packages that invoke ``apt-get``, the compiler and its
artifacts are installed in ``/usr/local``. However, this is not enough to prioritize the order ``libstdc++`` used, for
that we need to update ``ldconfig`` with the local directories. Until then, this was not necessary in the previous
images, as everything was either consumed directly from the system, or installed directly in ``/usr``.

These are the main features of the base image, which is used in all final images.

## Building GCC from source

Now let's look at the GCC build image, the full recipe can be found
[here](https://github.com/conan-io/conan-docker-tools/blob/feature/single-image/modern/gcc/Dockerfile), but let's
highlight a few points:

{% highlight docker %}

RUN cd gcc-${GCC_VERSION} \
    && ./configure --build=x86_64-linux-gnu --disable-bootstrap --disable-multilib ...

{% endhighlight %}

No matter the version, GCC continues to use the same lines for its build.
Some factors were configured in this version used:
* The multilib support was discarded as we are only interested in producing packages with 64-bit support.
* Fortran support has been added, thus producing ``gfortran`` together in the image. Currently the Conan package for
``gfortran`` is totally broken and has a complex dependencies chain to fix.
* Bootstrap has been disabled to reduce build time to just 20 minutes.

Once GCC 10 is built, its libstdc++ generated is copied to an Artifactory instance and this is downloaded directly to
each final image. Actually, that was the original intent, but as we will see, that was not possible. While we were
developing the new recipes, GCC 11 was released and along with it, the version was ``libstdc++`` already ``.29``, which
made usage incompatible. In this case, we are left with the following dilemma:

* Using the same libstdc++ version, except for GCC 11.
    * Conan Center becomes homogeneous, everything can be used without compiler restriction and distribution
    * Binaries can hardly be used outside of Conan Center because they need the newest version of libstdc++ library
that is not yet available in official PPA. All build requirements would be broken.
    * A possible solution would be to statically link libstdc++ in all binaries, but this solution has a number of
risks.
* Each image uses the corresponding version of libstdc++ provided by the compiler.
    * Better than the current scenario, where it is dependent on PPA and we have no control over it.
    * All images still use the same version of glibc, another advantage over the current scenario.
    * We will need to take care of the build requirements, as they will only be compatible with later versions.
    * Better for users, than the current scenario. The requirements related to libstdc++ are the same, but the glibc
version is still the same version for everyone.

Given the conditions and risks, we chose to go the second way: **Use the libstdc++ version available together with the
compiler**.

The last part of the image uses the concept of Docker
[multistage-build](https://docs.docker.com/develop/develop-images/multistage-build/), a technique that avoids creating
separate recipes and images to take advantage of common parts.


{% highlight docker %}

FROM ${DOCKER_USERNAME}/base-${DISTRO}:${DOCKER_TAG} as deploy

ARG GCC_VERSION
ARG LIBSTDCPP_PATCH_VERSION

COPY --from=builder /tmp/install /tmp/install

RUN sudo rm -rf /usr/lib/gcc/x86_64-linux-gnu/* \
    && sudo cp -a /tmp/install/lib/gcc/x86_64-linux-gnu/${GCC_VERSION} /usr/lib/gcc/x86_64-linux-gnu/ \
    && sudo cp -a /tmp/install/include/* /usr/local/include/ \
    && sudo cp -a /tmp/install/lib64/ /usr/local/ \
    && sudo cp -a /tmp/install/libexec/ /usr/local/ \
    && sudo cp -a /tmp/install/lib/* /usr/local/lib/ \
    && sudo cp -a /tmp/install/bin/* /usr/local/bin/ \
    && sudo rm -rf /tmp/install \
    && sudo update-alternatives --install /usr/local/bin/cc cc /usr/local/bin/gcc 100 \
    && sudo update-alternatives --install /usr/local/bin/cpp cpp /usr/local/bin/g++ 100 \
    && sudo update-alternatives --install /usr/local/bin/c++ c++ /usr/local/bin/g++ 100 \
    && sudo rm /etc/ld.so.cache \
    && sudo ldconfig -C /etc/ld.so.cache \
    && conan config init --force

{% endhighlight %}

In this section, the base image used is the same one we created before, through a caching mechanism, this drastically
reduces the final image build time.
Also, all artifacts generated from GCC are now copied to their respective locations. Finally, the compiler becomes the
default in the image and the libraries are listed and cached. And here's the icing on the cake, the same recipe works
from GCC 5 to the latest version, just modifying some arguments. The maintenance has been drastically simplified
compared to current Conan Docker Tools.

## Conan meets the Wyvern: Building Clang C/C++ compiler from source

For the construction of Clang, we tried to make it available from version 6.0 to 12, but we had a series of obstacles
and challenges that made us change our mind. Here we will share a little bit of this long journey of CMake files and
compilation hours. To see the full recipe, it is available
[here](https://github.com/conan-io/conan-docker-tools/blob/feature/single-image/modern/clang/Dockerfile).

As we would like to use only one version of libstdc++, we chose to find a way to build the Clang without the direct
dependency on GCC, building the Clang with another Clang already installed, thus avoiding ``libgcc_s``, ``libstdc++``
and using ``libc++``, ``libc++-abi``, ``libunwind``, ``compiler-rt`` and ``ldd`` instead. The ``libstdc++`` would only
be used for Conan packages, not as a Clang requirement. However, we had some situations and the need for some actions
that will be listed here:

* The LLVM project uses CMake support, which facilitates the configuration of its construction, even customization if
necessary.
* We chose to use Clang 10 as a builder, as it is current and still compatible with the chosen Ubuntu version. The
compiler is pre-built and distributed by the official LLVM PPA.
* From version to version, options are added or removed, reflecting the evolution of project features and legacy
deprecation. With these changes, it was inevitable to study the CMake files of each version to understand which options
do not work in subsequent versions or which option should be used to specify the preferred library.
* Unlike GCC, LLVM has a huge range of parameters and a longer build time, around 1h depending on the host. So, for
each attempt, a long wait was needed to get the result.
* Until Clang 9 release, ``libc++`` was not automatically added to be linked when using Clang. As a solution, the
project supports a configuration file, where ``libc++`` can be specified by default. However, this behavior changes
between versions 6, 7 and 8, requiring different standards and making it difficult to use the same Docker recipe for
all versions.
* With the removal of the GCC dependency, it was necessary to use ``libunwind`` during the build. It is already
internalized in LLVM, but used as a dynamic library only. So a question arises, what happens if a project uses the
image with Clang and installs Conan's libunwind package? A big mess when linking, is the answer. Clang tries to link
the version distributed by the Conan package, resulting in several errors. As a workaround, we renamed the original
LLVM ``libunwind`` to ``libllvm-unwind``.

With all the advents and limitations, it became quite difficult to maintain from Clang 6 to 12. After a lot of
discussions and advices from some of the LLVM maintainers, we decided to limit Clang support to starting from version
10, because it is not necessary to apply as many modifications, including the configuration file. Also, in the Linux
environment, Clang is not the primary compiler, so we believe its use is always tied to newer versions.

Now that the difficulties faced are clear, let's go a step further and detail the Clang deployment step.

{% highlight docker %}

FROM ${DOCKER_USERNAME}/gcc${LIBSTDCPP_MAJOR_VERSION}-${DISTRO}:${DOCKER_TAG} as libstdcpp

FROM ${DOCKER_USERNAME}/base-${DISTRO}:${DOCKER_TAG} as deploy

ARG LIBSTDCPP_VERSION
ARG LIBSTDCPP_PATCH_VERSION

ARG DOCKER_USERNAME
ARG DOCKER_TAG
ARG DISTRO

COPY --from=builder /tmp/install /tmp/clang
COPY --from=libstdcpp /usr/local /tmp/gcc

RUN sudo mv /tmp/gcc/lib64 /usr/local/ \
    && sudo ln -s -f /usr/local/lib64/libstdc++.so.6.0.${LIBSTDCPP_PATCH_VERSION} /usr/local/lib64/libstdc++.so.6 \
    && sudo ln -s -f /usr/local/lib64/libstdc++.so.6 /usr/local/lib64/libstdc++.so \
    && sudo cp -a /tmp/gcc/include/* /usr/local/include/ \
    && sudo rm -rf /usr/lib/gcc/x86_64-linux-gnu/* \
    && sudo cp -a /tmp/gcc/lib/gcc/x86_64-linux-gnu/${LIBSTDCPP_VERSION} /usr/lib/gcc/x86_64-linux-gnu/ \
    && sudo cp -a /tmp/gcc/lib/* /usr/local/lib/ \
    ...

{% endhighlight %}

Similar to what was done with GCC, in Clang we also use the same base image and copy the artifacts generated by the
compiler to the ``/usr/local`` directory. However, the ``libstdc++`` library was extracted from the GCC 10 image. This
is a necessity of the possible configurations supported by Conan.

## Tests and more tests: A CI pipeline to test Docker images

To ensure that the images produced met our requirements, we needed to add new tests that cover in addition to what was
already tested in Conan Docker Tools. Until then, a single script was used which validated a series of builds, versions
of installed binaries and user permissions. The content of the new tests can be seen
[here](https://github.com/conan-io/conan-docker-tools/tree/feature/single-image/modern/tests).

We introduced greater modularization in the tests, dividing the steps into separate scripts, to serve each compiler
closer. With the support for Fortran, it was necessary to adapt a test that covered it. Furthermore, many applications
that are now bundled with Conan are no longer part of the base image and this has also been validated.

If you want to test locally a produced Docker image, you can easily run:

{% highlight bash %}

$ cd modern && pytest tests --image conanio/gcc10-ubuntu16.04 --service deploy -vv --user 0:0

{% endhighlight %}

## The CI service change: From Travis to Azure and the Jenkins arrival

Since the beginning of the project, Conan Docker Tools has always used CI services such as Travis and Azure. However,
this did not give us the full power to prioritize the build in the queue, or customize the host, or customize the build
lines to use Docker-in-Docker if necessary.

With that in mind, we started using Jenkins to also build the new Docker images. The big
advantage in this is the use of features for cache in Docker. Previously, a single job took up to 2h if it was on other
services, without the use of caching. Now, using Jenkins and Docker ``--cache-from``, updating a package, from base
image to final image, takes just 4 minutes per job. The Jenkinsfile file used can be viewed
[here](https://github.com/conan-io/conan-docker-tools/blob/feature/single-image/.ci/xenial.jenkinsfile).

Although the file looks complicated at first glance, it is still possible to use docker-compose to build an image from
scratch. As an example, let's use Clang 12:

{% highlight bash %}

$ cd modern && docker-compose build clang12

{% endhighlight %}

The produced image will be named as ``conanio/clang12-ubuntu16.04:1.38.0``, where ``1.38.0`` is the image tag and
version of Conan installed. But it's totally configurable by the .env file.

In the case of legacy images, they will continue to be built in Azure when needed, we have no intention of moving them
to Jenkins due to effort and maintenance.

## Finals words and feedback

We invite everyone who uses Conan Docker Tools images to use this new formulation, which should become official soon.
These new images are the result of a long journey, where we learned from our mistakes and listened to the community to
reach what we have today. We believe improvements should be added continuously to keep the CDT progressing, so please
let us your feedback on issue [#205](https://github.com/conan-io/conan-docker-tools/issues/205).
