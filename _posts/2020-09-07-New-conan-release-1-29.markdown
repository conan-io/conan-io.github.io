---
layout: post 
comments: false 
title: "Conan 1.29: Updates to multiple generators, new 
tools.rename function, experimental toolchain for gnu make, lockfile bug fixes"
---

Conan 1.29 has been released. This release doesn't contain any major new
features, but instead brings more completeness and quality to existing
features.

## Updates to Generators

Some of the newer `cpp_info` properties have now been added to both the `QMake`
and `Qbs` generators, including `cpp_info.system_libs`,
`cpp_info.framework_paths` and `cpp_info.frameworks`. Additionally, the `json`
generator learned how to generate the `user_info` data from the build context.

The `cmake_find_package` and `cmake_find_package_multi` both had some bugs in
the previous release surrounding the new `filenames` attribute of `cpp_info`.
Also, there was a bug in the `cmake_multi` generator in which it was producing
`cmake` files which were failing under valid conditions. These have all been
fixed.

## New tools.rename Function

On Windows, many users have reported an intermittant problem with python's
`os.rename` function when used in some `conanfile.py` contexts. Sometimes the
function will fail simply with a permission error. Numerous workarounds have
been offerred, but in this release we've merged a new tools function called
`tools.rename` which uses a more robust mechanism to avoid these errors.

## Experimental Toolchain for Gnu Make

Continuing our work on Conan's new toolchain strategy, this release contains a
toolchain class for the `Gnu Make` build system. Like the existing `MSBuild` and
`CMake` toolchains which had been added previously, this new toolchain class
generates `.mak` files for the `Gnu Make` build system which contain all the
relevant build-related variables from Conan. To clarify, this does NOT include
varaibles related to dependencies: this is still the domain of generators.

## Lockfile Bug Fixes

We have also continued to evolve and improve the experience around Lockfiles. In
this release, we fixed one bug where some package's were erroneously marked as
modified, and another bug where `Package_ID_Unknown` were not being updated
correctly.  We've also added a more helpful message when users try to compute
the `build_order` of a graph from a "base" lockfile (which isn't possible.) Now
the output should be much more helpful.

-----------
<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#sep-2020) for the
complete list.  

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
