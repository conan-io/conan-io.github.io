---
layout: post
comments: false
title: "Conan 2.0 implements Conan-agnostic deployment of dependencies for developers"
meta_title: "Conan 2.0 deployers can be used to create Conan-independent copy of the dependencies for developers - Conan Blog"
meta_description: "Discover how to create a Conan-independent copy of the dependencies that can be used for developers without Conan, includig both library dependencies and tools"
---

Upgrading to a major version like 2.0 can take some effort, we know it, and we ourselves are also investing many resources to continue upgrading the packages in the ConanCenter central repository. But Conan 2.0's new architecture and design will allow to iterate better and faster on top of it, and this is the first of many additions to Conan 2.0 to come. 

This new feature allows to install Conan dependencies artifacts directly into your project folder, and achieve a fully Conan-independent project, that can be built and run even without Conan installed in the system. This has been a long time demanded feature for some cases where the normal Conan development flows are not possible.

## Normal installation and usage of Conan packages

The following figure illustrates the normal usage of Conan to install and consume dependencies:

<p class="centered">
    Normal installation and usage of Conan packages
    <img  src="{{ site.baseurl }}/assets/post_images/2023-05-25/Using_packages_from_cache.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Using Conan packages from the cache"/>
</p>

When Conan installs the dependencies, they are installed in the "Conan cache", a folder that by default lives in the user home (Conan doesn't need to install anything at the system level), so they can be easily used by all the projects that use those dependencies.

The Conan generated files, like the ``conan_toolchain.cmake`` or the ``xxx-config.cmake`` CMake files used to correctly locate dependencies inside the Conan cache, will contain absolute paths to the location of the headers, libraries and binaries inside the Conan cache.

The development flow is typically ``conan install .`` to install the dependencies, then a call to ``cmake`` with either generated presets or generated toolchain to build the project.


## Creating a Conan-agnostic deploy of dependencies

With the Conan 2.0 new ``full_deploy`` deployer it is possible to create a Conan-agnostic copy of dependencies that can be used by developers without even having Conan installed in their computers.

Let's see it with an example. All the source code is in the
[examples2.0 Github repository](https://github.com/conan-io/examples2)

```bash
  $ git clone https://github.com/conan-io/examples2.git
  $ cd examples2/examples/extensions/deployers/development_deploy
```

In that folder we can find the following ``conanfile.txt``:

```ini
  [requires]
  zlib/1.2.13

  [tool_requires]
  cmake/3.25.3

  [generators]
  CMakeDeps
  CMakeToolchain

  [layout]
  cmake_layout
```

The folder also contains a standard ``CMakeLists.txt`` and a ``main.cpp`` source file that can create
an executable that links with ``zlib`` library.

We can install the Debug and Release dependencies, and deploy a local copy of the packages with:

```bash
  $ conan install . --deploy=full_deploy --build=missing
  $ conan install . --deploy=full_deploy -s build_type=Debug --build=missing
```

This will create the following folders:

```txt
  ├──src
  ├──build
  │   ├──generators
  |         └── ZLibConfig.cmake
  ├──full_deploy
  │   ├──build
  │   │   └──cmake
  │   │       └──3.25.3
  │   │           └──x86_64
  │   │               ├──bin
  │   │
  │   └──host
  │       └──zlib
  │           └──1.2.13
  │               ├──Debug
  │               │   └──x86_64
  │               │       ├──include
  │               │       ├──lib
  │               └──Release
  │                   └──x86_64
  │                       ├──include
  │                       ├──lib
```

<p class="centered">
    Conan-agnostic deploy of dependencies
    <img  src="{{ site.baseurl }}/assets/post_images/2023-05-25/Conan_independent_dependencies_deploy.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Conan-agnostic deploy of dependencies for developers"/>
</p>

The project is fully self-contained. It contains both the necessary tools (like ``cmake`` executable), the headers and compiled libraries of ``zlib`` and the necessary files like ``ZLibConfig.cmake`` in the ``build/generators`` folder, that point to the binaries inside ``full_deploy`` with a relative path. 

The Conan cache can be removed, and even Conan uninstalled, then the folder could be moved elsewhere in the computer or copied to another computer, assuming it has the same configuration of OS, compiler, etc.

```bash
  $ cd ..
  $ cp -R development_deploy /some/other/place
  $ cd /some/other/place
```

And the files could be used by developers:

```bash
  # Commands for WINDOWS
  $ cd build
  # Activate the environment to use CMake 3.25
  $ generators\conanbuild.bat
  $ cmake --version
  cmake version 3.25.3
  # Configure, should match the settings used at install
  # If CMake>=3.23 you can use ``cmake --preset conan-default``
  $ cmake .. -G \"Visual Studio 17 2022\" -DCMAKE_TOOLCHAIN_FILE=generators/conan_toolchain.cmake
  $ cmake --build . --config Release
  $ Release\compressor.exe
  ZLIB VERSION: 1.2.13
```

The environment scripts in Linux and OSX are not relocatable, because they contain absolute paths and the ``sh`` shell does not have any way to provide access to the [current script directory for sourced files](https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh/29835459#29835459).

This shouldn't be a big blocker, as a "search and replace" with ``sed`` in the generators folder can fix it:

```bash
  # LINUX
  $ cd build/Release/generators
  # Fix folders in Linux
  $ sed -i 's,{old_folder},{new_folder},g' *
  # Fix folders in MacOS
  $ sed -i '' 's,{old_folder},{new_folder},g' *
  $ source conanbuild.sh
  $ cd ..
  $ cmake --version
  cmake version 3.25.3
  # If CMake>=3.23 you can use ``cmake --preset conan-default``
  $ cmake ../.. -DCMAKE_TOOLCHAIN_FILE=generators/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
  $ cmake --build .
  $ ./compressor
  ZLIB VERSION: 1.2.13
```

## Conclusions

The described new feature is not necessarily the recommended approach to consume Conan packages, but it can be useful in some exceptional cases when it is not possible to run Conan to install the dependencies for development. We are happy to be able to deliver this functionality to the users that need it with Conan 2.0.

Note that the described approach in this post is useful for 1 development configuration, as the generated CMake files can only support 1 configuration (Debug/Release for multi-config tools like Visual Studio). If you need to support multiple OSs or platforms you will need to generate 1 deploy for each one. 

The presented approach can be very easily customized for your own needs, because Conan 2.0 also implement some new extensions points:

- If the ``--deployer=full_deploy`` doesn't implement your final desired output layout or you need to customize anything in it, it is possible to [create your own deployers](https://docs.conan.io/2/reference/extensions/deployers.html#custom-deployers)
- For even further custom automation capabilities, check the [custom commands new framework](https://docs.conan.io/2/reference/extensions/custom_commands.html)

This is a new feature, and at the moment it only implements support for ``CMake``. Feedback is very welcome, please create a [Github issue for any question, comment or suggestion](https://github.com/conan-io/conan) about it.
