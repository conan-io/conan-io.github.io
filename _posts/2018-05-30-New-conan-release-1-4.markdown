---
layout: post
comments: false
title: "Conan 1.4: SCM integration, new CMake generators, better Visual Studio environment management & much more!"
---

Conan 1.4 release is out with some outstanding features. Just after very productive talks at [SwampUp 2018](https://swampup.jfrog.com/) and
feedback from the community we got our hands dirty and came up with some useful features in this release.

## SCM integration for git repositories

Many advanced users came across the issue of capturing the commit of the repository of the sources in export time when
[recipe and sources were in the same repo](https://docs.conan.io/en/latest/creating_packages/package_repo.html#capturing-the-remote-and-commit-from-git-scm-experimental).

With the new ``scm`` experimental attribute this can be done in an easy way and it could be useful to download sources when
[recipe and sources are in different repos](https://docs.conan.io/en/latest/creating_packages/external_repo.html#recipe-and-sources-in-a-different-repo)
too. Currently this only supports git as SCM.

This feature has been released as experimental, so we want to hear your feedback! Please check the documentation and report to the
[Conan issue tracker](https://github.com/conan-io/conan/issues).

## New cmake_paths and cmake_find_package generators

After all the feedback collected regarding CMake integration, we focused the development with the goal of providing a transparent way to
integrate CMake relying on ``find_package()``, especially useful for Conan package consumers.

This led to two different generators:

- ``cmake_find_package`` generator creates one *Find\<package_name\>.cmake* file for each dependency. This will make each find_package in you
  *CMakeLists.txt* point to the dependency solved by Conan after a ``conan install``.
  [Read more](https://docs.conan.io/en/latest/integrations/cmake/cmake_find_package_generator.html#cmake-find-package-generator).

- ``cmake_paths`` generator creates a *conan_paths.cmake* file with ``CMAKE_MODULE_PATH`` and ``CMAKE_PREFIX_PATH`` variables adjusted to
  the dependencies folders. This also allow users to integrate Conan without modifying the *CMakeLists.txt*:
  ``cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_paths.cmake``.
  [Read more](https://docs.conan.io/en/latest/integrations/cmake/cmake_paths_generator.html#cmake-paths-generator).

Stay tuned to know more about how to use both generators!

## Better Visual Studio environment management

There has been many minor issues related to ``vcvarsall`` in this release:

- Added new parameters to ``tools.vcvars_command()`` to let users choose SDK version and compiler toolset.
- Improved robustness of ``tools.vcvars_dict()`` when reading ``vcvarsall`` output.
- ``tools.vcvars_dict()`` now sets only the environment variables set by ``vcvarsall``.
- ``virtualbuildenv`` generator now includes the needed variables from ``vcvarsall`` in *activate_build.bat/.ps1* files.

## Other things going on!

There are other useful features that will make your live easier:

- New tools including XCRun wrapper for easier development of packages targeting Apple devices (Thanks to the contributors!).
- In recipes: The ``fPIC`` flag is auto-managed in the Autotools build helper
- In CI: There is a new ``--json`` argument to output the results of the ``conan search`` command.
- We also added support for GCC 8 and Clang 7 as well as c++ language standard c++20.

## Preparing the future

Many of these release changes are internal. Big improvements are currently under development to enable bringing new features to Conan such
as:

- Refactor of the graph builder to improve build-requires inclusion.
- Better information about the dependency graph, and improving reproducibility.
- Parallelize downloads of packages.
- Mix binaries of the same recipe from different remotes.
- Conan Workspace (a.k.a. conan-project) to edit Conan packages and develop library dependencies will be coming finally in next 1.4.1
  release!
