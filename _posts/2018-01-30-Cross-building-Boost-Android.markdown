---
layout: post
comments: false
title: Cross building Boost C++ libraries to Android with Conan
# other options
---

Today we released a Conan package [Boost/1.66.0@conan/stable](https://github.com/lasote/conan-boost) on [conan-center](https://bintray.com/conan/conan-center).

This package contains binaries for **more than 150 different** configurations: Windows (different flavors of Visual Studio),
Linux (gcc and clang compilers), OSX. In all systems, it is possible to use different architectures, build types,
or choose if we want to link statically, dynamically, or even to use boost header-only libraries.

But this package also includes large improvements for cross-building boost to different platforms, like Raspberry PI, or Android.
This amazing work has been done thanks to many contributions from the (conan) community, thank you all!!!

[Conan-center](https://bintray.com/conan/conan-center) only includes the most mainstream binaries, those for Windows,
Linux and OSX, but this post explain how you can use conan to easily cross-build Boost to those platforms.



## The conan model


Conan packages are defined by recipes, which are python scripts, describing how to build and package the library.
With one conan recipe, many different binary packages can be created, i.e: one for Windows Visual Studio 14, another one for Linux GCC 6 and so on.
Conan package recipes are responsible for translating the user settings (os, architecture, compiler, etc) and call the underlying library's
build system with the right options/flags, generating a different binary package for different input settings.

Both package recipes and binaries for all platforms and configurations can be uploaded to the same conan server,
to share them with the team. From now on, if any developer wants to work with this library and there is already a binary generated
for the requested configuration (settings/options) then the library is going to be retrieved directly from the server.
It will save a huge amount of time to any developer of CI process, especially when we are talking about big and complex libraries like boost.

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-01-30/conan_model.png" align="center" width="500"/>
</p>

When the user runs “conan install” to retrieve the dependencies for his project, Conan will download the recipe,
evaluate it with their settings/options, and download the  binary matching the user’s configuration.


## Cross building Boost with Boost Build (b2)


The Boost Build system (aka b2) [accepts some arguments](http://www.boost.org/doc/libs/1_66_0/libs/context/doc/html/context/architectures/crosscompiling.html)
to define the cross-compilation:

    architecture, address-model, binary-format, mfloat-abi, abi, target-os


In our case, if we want to cross-build to a Android/ARM system, the arguments to pass to “b2” are:

    architecture=arm
    address-model=32
    binary-format=elf
    abi=appcs
    target-os=android

Hence the command like command would be:

    $ b2 architecture=arm address-model=32 binary-format=elf
      abi=aapcs target-os=android link=static variant=release
      --without-python  -j8 --abbreviate-paths -d2 --debug-configuration
      --build-dir=”my_build_folder"

But this is not enough because boost has some third-party dependencies, like **zlib** or **bzip2**.
The user also needs to set some environment configuration, the build tools and compilers paths, the details of
the toolchain and compilations flags has to be specified. To do it the best approach is to define an ``user-config.jam``
file with the details for cross-building, which could look like:

    using zlib : 1.2.11 : <include>/.conan/data/zlib/1.2.11/conan/stable/package/39a53587004d75943e385925ca011baeab537de0/include
    <search>/.conan/data/zlib/1.2.11/conan/stable/package/39a53587004d75943e385925ca011baeab537de0/lib ;
    using clang : 5 : "arm-linux-androideabi-clang++"  :
    <archiver>"/path/to/arm_21_toolchain/bin/arm-linux-androideabi-ar"
    <ranlib>"/path/to//arm_21_toolchain/bin/arm-linux-androideabi-ranlib"
    <cxxflags>"-fPIC  -I/path/to/arm_21_toolchain/include/c++/4.9.x"
    <cflags>"-fPIC  -I/path/to/arm_21_toolchain/include/c++/4.9.x" <ldflags>""  ;

This is an important detail if we want to cross-build Boost for Android,
it should link against cross-built versions of zlib and bzip2 for the same configuration we are cross-building Boost.


<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-01-30/boost_deps.png" align="center" width="300"/>
</p>


It could be a huge challenge for any developer and a real impediment.
Fortunately, [conan-center](https://bintray.com/conan/conan-center) repository already contains zlib and bzip2 packages with
pre-built binaries for hundreds of configurations, but most importantly:
they also know how to cross-build themselves, using their own build systems.


##  Creating Boost packages with native and cross-build binaries



There are two ways of creating binary packages. The first one is using “conan create”, typically used by package
creators to explicitly build and test packages before uploading them. This process usually starts cloning a repository
that contains the conan package recipe:


    $ git clone -b release/1.66.0 https://github.com/lasote/conan-boost
	$ conan create . myuser/testing


The second way is to consume existing packages. End users can create a ``conanfile.txt`` or ``conanfile.py``, declaring the necessary package
dependency, and then use the command, "conan install" (more info [getting started](http://docs.conan.io/en/latest/getting_started.html#getting-started)).

A **conanfile.txt** to consume the boost library looks like:

    [requires]
    boost/1.66.0@conan/stable


The "conan install" command will try to download a pre-built binary package for developer's default configuration
(more info [default profile](http://docs.conan.io/en/latest/reference/config_files/default_profile.html)),
but it can fail if there is no binary for the requested configuration.
The "--build missing" argument should be used in this case forcing conan to build the library from
sources with the library recipe. The command should be:


    $ conan install . --build missing


In both cases, to specify which configuration do you want to build, it is very handy to use
[profiles](http://docs.conan.io/en/latest/reference/profiles.html):

	$ conan install . --build missing --profile my_clang_profile

The profiles are plain text files defining settings, options, environment variables, and build requirements.

A default profile for OSX  could be:

    [settings]
    os=Macos
    os_build=Macos
    arch=x86_64
    arch_build=x86_64
    compiler=apple-clang
    compiler.version=9.0
    compiler.libcxx=libc++
    build_type=Release
    [options]
    [build_requires]
    [env]


If we want to cross-compile to Raspberry PI from Windows, we could install the correct toolchain and define the following profile:

    ~/.conan/profiles/rpi
    target_host=arm-linux-gnueabihf
    standalone_toolchain=C:/sysgcc/raspberry
    cc_compiler=gcc
    cxx_compiler=g++

    [settings]
    os_build=Windows
    arch_build=x86_64
    os=Linux
    arch=armv7 # Change to armv6 if you are using Raspberry 1
    compiler=gcc
    compiler.version=6
    compiler.libcxx=libstdc++11
    build_type=Release

    [env]
    CONAN_CMAKE_FIND_ROOT_PATH=$standalone_toolchain/$target_host/sysroot
    PATH=[$standalone_toolchain/bin]
    CHOST=$target_host
    AR=$target_host-ar
    AS=$target_host-as
    RANLIB=$target_host-ranlib
    LD=$target_host-ld
    STRIP=$target_host-strip
    CC=$target_host-$cc_compiler
    CXX=$target_host-$cxx_compiler
    CXXFLAGS=-I"$standalone_toolchain/$target_host/lib/include"


And use this profile with [conan create](http://docs.conan.io/en/latest/creating_packages/getting_started.html)
which would build the library, in the local cache, with the settings specified in our profile "rpi":

    $ conan create . conan/stable --profile=rpi

You can follow [this guide](http://docs.conan.io/en/latest/systems_cross_building/cross_building.html#windows-to-raspberry-pi-linux-arm)
in the conan docs to know more about compiling for Raspberry PI.


If you want to cross build a Conan package you need:

- The correct toolchain (compiler and tools)
- A profile that describe the settings and the needed environment variables to locate the toolchain.


## Creating Boost packages for Android



### Preparing the Android toolchain


The Android toolchain can be generated from the [Android NDK](https://developer.android.com/ndk/downloads/index.html).

From the NDK version r16 is only supported “clang” compiler and “libc++” as the standard c++ library.

You can [download the NDK](https://developer.android.com/ndk/downloads/index.html) and invoke the “make_standalone_toolchain.py”
script specifying the api level, architecture and standard library:

    $ cd build/tools
    $ python make_standalone_toolchain.py --arch=arm --api=21 --stl=libc++ --install-dir=/myfolder/arm_21_toolchain

### Preparing the Conan profile

Copy and paste this profile in your profiles folder (~/.conan/profiles) adjusting the path to the new
standalone toolchain (replace *“/myfolder/arm_21_toolchain”* with your install path):

**.conan/profiles/android_21_armeabi-v7a_clang**

    standalone_toolchain=/myfolder/arm_21_toolchain
    target_host=arm-linux-androideabi
    cc_compiler=clang
    cxx_compiler=clang++

    [settings]
    compiler=clang
    compiler.version=5.0
    compiler.libcxx=libc++
    os=Android
    os.api_level=21
    arch=armv7
    build_type=Release

    [env]
    CONAN_CMAKE_FIND_ROOT_PATH=$standalone_toolchain/sysroot
    PATH=[$standalone_toolchain/bin]
    CHOST=$target_host
    AR=$target_host-ar
    AS=$target_host-as
    RANLIB=$target_host-ranlib
    CC=$target_host-$cc_compiler
    CXX=$target_host-$cxx_compiler
    LD=$target_host-ld
    STRIP=$target_host-strip
    CFLAGS= -fPIC  -I$standalone_toolchain/include/c++/4.9.x
    CXXFLAGS= -fPIC  -I$standalone_toolchain/include/c++/4.9.x
    LDFLAGS=


### Building Boost package for Android

In [conan-center](https://bintray.com/conan/conan-center) you can find binaries for known platforms like Windows,
OSX and Linux but not for Android.
In this section we are going to build boost for Android and upload the resulting package to a repository where
it can be consumed by other developers, not building the boost library from sources again in the process.

We are going to use the “conan create” command, so we need to clone the recipe repository:

    git clone -b release/1.66.0 https://github.com/lasote/conan-boost
    conan create . conan/stable --build missing --profile=android_21_armeabi-v7_clang

With the “--build missing” parameter we are telling conan to build from sources any transitive dependency
for the specified profile, in this case Conan will cross-build also **zlib** and **bzip2**.

Now we can upload the generated binary packages to a conan-server, Artifactory or Bintray.
Check the [Uploading packages](http://docs.conan.io/en/latest/uploading_packages.html) section in the docs.

	> conan upload boost/1.66.0@conan/stable --all -r=myremote
	> conan upload zlib* --all -r=myremote
	> conan upload bzip2* --all -r=myremote
	# or just
    > conan upload * --all -r=myremote

We could also share profiles, remotes and settings among the team with the [conan config install](
http://docs.conan.io/en/latest/reference/commands/consumer/config.html) command.

At this point the binary packages for Android are in my-remote (i.e: [conan-center](https://bintray.com/conan/conan-center))
and developers using the
above profile can reuse them without building from sources the whole boost library.

In a **following blog post** we will create an android app, using the boost library, with an Android Studio
project and a simple "conanfile.txt". We will explain how to generate the same app for multiple architectures (arm, x86 ...)
and package everything in a single apk.
