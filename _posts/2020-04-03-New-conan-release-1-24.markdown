---
layout: post 
comments: false 
title: "Conan 1.24: New Cross-Build Model, Components API for Generators, New Init() Method, and More"
---

## Cross-Build Modeling + Context Modeling

In 2017, we implemented cross-build support to Conan largely based on experience with cross-build models in build systems. We updated the settings model of `os` and `arch` with the new distinct settings of `os_build`/`arch_build` and `os_target`/`arch_target`. This new model has received a lot of use both internally and from users which resulted in very valuable feedback from a variety of use cases. Based on this feedback, it was clear that the model was insufficient and something more robust was needed.

The <new model> adds a new command-line argument to specify a completely separate profile called a "<build_profile>" which will be used to build `build_requires` in the dependency graph. This sounds simple, but is accomplished by providing a new abstraction called "contexts".  There is one context in which `build_requirements` are built (called the "build context"), and another context in which the rest of the `requirements` are built (called the "host context"). 

## Components API for future Generators

Many popular libraries use CMake as a build system, and leverage a CMake feature known as "target components".  This allows consumers to compile and link against certain parts of the library while ignoring others. This granularity adds a lot of complexity for tools trying to integrate with CMake, but it is widely used by consumers of popular libraries so it was always something we wanted to support.  In this release, we add some features which bring us closer to that goal. Also, it is conceivable that other build systems may feature a similar concept, so we've tried to impelement these features in a general way. 

For this release, we've added a new member to `cpp_info` called "`components`". It is a dictionary where the keys are component names, and the values are each independent `cpp_info` instances. Thus, each component can be advertised with all the same info that a separate package would (in terms of `cpp_info`).  If you're familiar with CMake components and how Conan generators work, it should be fairly easy to imagine the existing CMake generator converting these Conan components into CMake components. 

It's important to point out that this new member is not yet implemented into any generators. In fact, the `components` member has intentionally been omitted from `deps_cpp_info` so that it cannot be.  As stated earlier, it is just the first step toward eventually supporting the components concept. Stay tuned to the next release for additional progress. 

## CONAN_V2_MODE deprecations  

In Conan v1.x, there were several mechanisms added to empower recipe authors to share code among many recipes. After some time in the wild, it's become clear that some of these mechanisms have problems of safety or supportability. In this release, enabling CONAN_V2_MODE will disable two of these mechanisms: 
- `<cache>/python` will no longer be added to `sys.path`
- `PYTHONPATH` from `env_info` will no longer be appended for `python_requires` packages

New init() method on `conanfile.py` (intended for python_requires())

At it's core, `conanfile.py` is a Python class.  All of it's existing functions have been carefully designed to model the problems of building and packaging for C/C++.  However, at scale, there is a practical need to manage and share code among recipes (such as providing a base class for Conanfiles) and `python_requires` was created to enable that. Based on feedback from users, there are still some capabilities surrounding the fundamental instantiation of the Conanfile Python object which would be valuable but are not currently possible. The new `init()` method is now the "first" conanfile function to be run if defined (it runs before config_options.)  

## SystemPackageTool Default Behavior Change

The default behavior of SystemPackageTool has been to run system package manager commands to fetch or update system dependencies.  Extensive feedback regarding problems caused by this default has led us to change it in this release. As of this release, Conan will NOT install system requirements if the CONAN_SYSREQUIRES_MODE is not manually set.

## Additional Features and Fixes

This release actually contains too many exciting features and bugfixes for us to highlight them all. As always, you can see the complete list in the [changelog]( https://docs.conan.io/en/latest/changelog.html#mar-2020).  However, here's a list of honorable mentions:

