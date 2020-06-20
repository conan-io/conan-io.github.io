---
layout: post 
comments: false 
title: "Conan 1.26: New conanfile.py methods, source caching, and transparent cmake integration"
---

Conan 1.26 has been released. Without a doubt, the most substantial feature in
this release is the introduction of three new recipe methods!  The first and
most significant one is the `toolchain()` method, so let's talk about that
first.

## New Method: toolchain()

The primary goal of the
[`toolchain()`](https://docs.conan.io/en/latest/creating_packages/toolchains.html)
method is to separate the generation of the build system files from the build
method, so that those build system files can be used for building outside of
Conan (without having to run `conan create` or `conan build`). In general, the
use of Conan dependency information outside of Conan has come up in many
different contexts.  We're working on several of those, and this new method aims
to provide support cases related to local development flows.  

In theory, changing an existing recipe to use the new method can and
should be transparent and functionally equivalent.  Here's a summary of how
this new feature would be used:

* Define a new `toolchain()` method in `conanfile.py`
* Instantiate the `CMakeToolchain()` class inside that method
* `conan install` will then generate a `conan_toolchain.cmake` file
* This step is very similar to how `conanbuildinfo.cmake` gets generated
* Then, when running cmake outside of Conan, you can use it with:
  * `cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake`
* The file will also be used implicitly when using the `CMake()` helper class

## New Methods: export() and export_sources()

The other two methods added in this release are
[`export()`](https://docs.conan.io/en/latest/reference/conanfile/methods.html#export)
and
[`export_sources()`](https://docs.conan.io/en/latest/reference/conanfile/methods.html#export-sources).
The goal of these methods is to provide more flexible method-based alternatives
to the well-known-attributes of
[`exports`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#exports)
and [`exports_sources`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#exports-sources). It works by exposing a `self.copy()` function just like
the [`source()`](https://docs.conan.io/en/latest/reference/conanfile/methods.html#source) method.  

So, for example, you could change from this:  

```python
    exports_sources = "patches/**"
```

... to this...

```python
    def exports_sources(self):
        self.copy(pattern="patches/**")
```

## Transparent CMake Integration

The next biggest accouncement from this release is that we've made yet another
major step towards more transparent CMake integration by adding components
support to the
[`cmake_find_package`](https://docs.conan.io/en/latest/integrations/build_system/cmake/cmake_find_package_generator.html)
generator. With this release, users can now consume Conan dependencies within
CMake projects in a truly transparent way. The find_package generator provides
the transparent mechanism, and the
[components](https://docs.conan.io/en/latest/reference/generators/cmake_find_package.html?#components)
feature, along with the customizable target name feature in Conan, enable all
the targets align with existing target names, references, and interdependencies
which are used in the `CMakeLists.txt` of the open-source community.  This is
the culmination of more than a years worth of planning, so it's a very exciting
release for that reason.  Here is a graphic demonstrating each of the nuanced
dependencies which can exist among projects and components. In this graphic:

* `App1` depends directly on the full target `world/0.0.1`
* `App2` depends directly on the `World::Worldall` component of `world/0.0.1`
* The `World::Worldall` component depends directly on `World::Helloworld` component
* The `World::Worldall` component depends directly on `Greetings::Bye` component
* The `World::Helloworld` component depends directly on the `Greetings::Hello` component
* Nothing depends directly on the `greetings/0.0.1` target

![CMake Components]({{ site.url }}/assets/post_images/2020-06-19/cmake_components_graphic.png)

Of note, there is a related CMake generator called
[cmake_find_package_multi](https://docs.conan.io/en/latest/reference/generators/cmake_find_package_multi.html).
This generator still does not support components, but that is planned for a
future release.

## New Sub-Command : conan config init

In the past, there have been many comments and suggestions about various
annoyances when setting up a new conan home directory from scratch.  `conan
config install` handles a vast majority of use-cases, but not all of them. There
are many niche cases where users want to provision a new workspace with all the
defaults values from the current conan version, and this was particularly
awkward.  `conan config init` provides a simple and intuitive way to handle
these cases.  

## New Generator : MSBuild

One piece of feedback we've recieved from multiple users is that MSBuild lacks
anything resembling the "targets" abstraction found in CMake. The variables
produced in the current Visual Studio generators are equivalent to global
variables in CMake. So, when importing `conanbuildinfo.props` into a Visual
Studio project, all dependencies get used for all builds in the project. This
can be problematic for a number of reasons.

The new [MSBuild Generator](https://docs.conan.io/en/latest/reference/generators/msbuild.html)
intends to offer a number of advantages over the current Visual Studio generators.  
First, the name of the generator matches the name of the build system which is
just a consistency improvement.  More importantly, it uses a completely
different structure in the way the dependency information is produced in the
generated .props files. This makes it possible for users to selectively import
dependencies on a per-project basis . As we intend for this generator to become
the new standard for MSBuild projects, we are very interested in user feedback.
Please reach out and let us know what you think if you have the opportunity to
try it out.

## Additional Features and Fixes  

For recipe authors, we have quite a few additional new features.   We have a new
["remove_files_by_mask"](https://docs.conan.io/en/latest/reference/tools.html?highlight=remove_files_by_mask#tools-remove-files-by-mask)
tool for cleaning.  We have a new `stdcpp_library` tool to make evaluating the
C++ standard for the current build, and writing conditionals around it easier.
On a related note, we've also further improved our support for the Intel
compiler on two fronts.  We're now handling the C++ standard flag automatically,
and making the CMake helper call `compilervars.sh`, which is required for proper
interop with Intel C++ compiler.

As usual, we cannot cover everything in the release in this blog post, so visit
the [changelog](https://docs.conan.io/en/latest/changelog.html#jun-2020) for the
complete list.  

-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
