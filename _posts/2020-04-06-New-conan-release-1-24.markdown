---
layout: post 
comments: false 
title: "Conan 1.24: New Cross-Build Model, Components API for Generators, New Init() Method, and More"
---

Conan 1.24 comes with a substantial list of completed feature requests, both
major and minor.  The largest changes relate to the cross-build model and
provide more power when working with some of the most complex packages users are
working on today.  This includes `Protobuf` and `LLVM` to name a few. There are
also some subtle additions which are incremental steps towards some long-term
goals such as supporting "components" in build systems like `CMake`, providing
a robust abstraction for `cppstd`, helping users prepare for Conan V2.0 with
more opt-in deprecations. 

## Cross-Build Modeling + Context Modeling  

In
[2017](https://docs.conan.io/en/latest/changelog.html#beta2-23-december-2017),
we implemented cross-build support to Conan largely based on experience with
cross-build models in build systems. We updated the settings model of `os` and
`arch` with the new distinct settings of `os_build`/`arch_build` and
`os_target`/`arch_target`. That model has received a lot of use both
internally and from users which resulted in very valuable feedback from a
variety of use cases. Based on this feedback, it was clear that the model was
insufficient and something more robust was needed.

The [new
model](https://docs.conan.io/en/latest/systems_cross_building/cross_building.html#using-build-requires)
adds a new command-line argument to specify a completely separate profile which
will be used to build `build_requires` in the dependency graph. This sounds
simple, but is accomplished by providing a new abstraction called
["contexts"](https://docs.conan.io/en/latest/devtools/build_requires.html#build-and-host-contexts).
There is one context in which `build_requirements` are built (called the "build
context"), and another context in which the rest of the `requirements` are built
(called the "host context"). Of note, when necessary, it is also possible to
force build requirements to stay in the host context if they are declared in
recipes. Here is a graphic showing how "contexts" can be used to allow a
`build_requirement` such as "protobuf" to use "zlib" with one profile, while the
package "my_pkg" uses zlib with a different profile.

<p class="centered">
    <a href="https://docs.conan.io/en/latest/devtools/build_requires.html#build-and-host-contexts"><img src="{{ site.url }}/assets/post_images/2020-04-06/conan-gtest_nasm.png" align="center" alt="context example diagram"/></a>
</p>

## New `init()` method on `conanfile.py`  

At it's core, `conanfile.py` is a Python class.  All of it's existing functions
have been carefully designed to model the problems of building and packaging for
C/C++.  However, at scale, there is a practical need to manage and share code
among recipes (such as providing a base class for Conanfiles) and
`python_requires` was created to enable that. 

Based on feedback from users, there are still some capabilities surrounding the
fundamental instantiation of the Conanfile Python object which would be valuable
but are not currently possible. The new `init()` method is now the "first"
conanfile function to be run if defined (it runs before config_options.)  

**Note** : `init()` method is intended for use with `python_requires()`. Other
uses may lead to undesirable consequences.

## New Markdown Generator  

A novel [new
generator](https://docs.conan.io/en/latest/reference/generators/markdown.html)
has been added which produces a markdown (.md) file from the package which
provides a summary of package information based on the Conan package. This is
suitable to be rendered by popular web frontends to `git` repositories such as
Github/Gitlab/Bitbucket where special rendering for `README.md` is commonplace. 

<p class="centered">
    <a href="https://docs.conan.io/en/latest/reference/generators/markdown.html"><img src="{{ site.url }}/assets/post_images/2020-04-06/conan-markdown_generator.png" align="center" alt="markdown generator sample"/></a>
</p>

## Components API for future Generators  

Many popular libraries use CMake as a build system, and leverage a CMake feature
known as "target components". This allows consumers to compile and link against
certain parts of a library while ignoring others. This granularity adds a lot of
complexity for tools trying to integrate with CMake, but it is widely used by
consumers of popular libraries so it was always something we wanted to support.
In this release, we add some features which bring us closer to that goal. Also,
it is conceivable that other build systems may feature a similar concept, so
we've tried to implement these features in a general way. 

For this release, we've added a new member to
[`cpp_info`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info)
called "`components`". It is a dictionary where the keys are component names,
and the values are each independent `cpp_info` instances. Thus, each component
can be advertised with all the same info that a separate package would (in terms
of `cpp_info`).  If you're familiar with CMake components and how Conan
generators work, it should be fairly easy to imagine the existing CMake
generator converting these Conan components into CMake components. 

It's important to point out that this new member is not yet implemented into any
generators. In fact, the `components` member has intentionally been omitted from
[`deps_cpp_info`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#deps-cpp-info)
so that it cannot be used.  As stated earlier, it is just the first step toward
eventually supporting the components concept. Stay tuned to the next release for
additional progress. 

## CONAN_V2_MODE deprecations  

In Conan v1.x, there were several mechanisms added to empower recipe authors to
share code among many recipes. After some time in the wild, it's become clear
that some of these mechanisms have problems of safety or supportability. In this
release, enabling `CONAN_V2_MODE` will disable two of these mechanisms: 
- `<cache>/python` will no longer be added to `sys.path`
- `PYTHONPATH` from `env_info` will no longer be appended for `python_requires`
  packages

## SystemPackageTool Behavior Change  

The default global behavior of `SystemPackageTool` has always been to
automatically run system package manager commands to fetch or update system
dependencies. Users could apply a global override to this behavior by setting
the environment variable `CONAN_SYSREQUIRES_MODE` to one of the other two modes:
`disabled` or `verify`.  

Both the default and the environment variable are "global" in nature (affecting
all recipes). Based upon user request, we have now added a new way to affect
this behavior: "per-package". Each `conanfile.py` can now specify it's own
default behavior a `default_mode` parameter of the [`SystemPackageTool`
constructor](https://docs.conan.io/en/latest/reference/conanfile/methods.html#systempackagetool).

Thus, the "new" precedence for controlling this behavior is as follows:  
1. Global: `CONAN_SYSREQUIRES_MODE` environment variable (if defined)
2. Per-package: `default_mode` parameter (if defined)
3. Global: `enabled` program default

**Note** : The parameter is named `default_mode` because it only applies when
the `CONAN_SYSREQUIRES_MODE` environment variable is NOT set. If the environment
variable is set to any value at all, the `default_mode` parameter in each recipe
is completely ignored.

## Additional Features and Fixes  

This release actually contains too many exciting features and bugfixes for us to
highlight them all. As always, you can see the complete list in the
[changelog]( https://docs.conan.io/en/latest/changelog.html#mar-2020).  However,
here's a list of honorable mentions:

* Add `tools.cppstd()` to retrieve actual compiler flags for the current setting
* Shortpaths support for `Cygwin`
* More detailed information when binaries are missing
* Support for mirrors in `tools.get()`
* Add description field to output of `conan info`
* Avoid unnecessary calls to CMake `find_package()`
* Multiple fixes for Sun C Compiler

-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues). 
