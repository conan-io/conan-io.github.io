---
layout: post comments: false title: "Conan 1.26: New conanfile.py methods,
source caching, and transparent cmake integration"
---

Conan 1.26 has been released. Without a doubt, the most substantial feature in
this release is the introduction of three new recipe methods!  The first and
most significant one is the `toolchain()` method, so let's talk about that first.

## New Method: toolchain()

The primary goal of the `toolchain()` method is to separate the generation of
the build system files from the build method, so that those build system files
can be used for building outside of Conan (without having to run `conan create`
or `conan build`). In general, the use of Conan dependency information outside
of Conan has come up in many different contexts.  We're working on several of
those, and this new method aims to provide support cases related to local
development flows.  

To make use of this new `toolchain()` method, every recipe will have to be
refactored. In theory, changing an existing recipe to use the new method can and
should be transparent and functionally equivalent, but because we're talking
about C and C++ build systems we're expecting some corner cases.  

## New Methods: export() and export_sources()

The other two methods added in this release are `export()` and
`export_sources()`.  The goal of these methods is to provide more flexible
method-based alternatives to the well-known-attributes of `exports` and
`exports_sources`. It works by exposing a `self.copy()` function just like the
`source()` method.  These new methods aren't just about attribute-vs-method
strategy, there is a broader implication which resolves several long-standing
feature requests. In summary, because they are methods, users can now call
`tools.download()` and choose to obtain sources externally.  In the past, the
`source()` method has existed expressly for this case. The feature requests we
mentioned were largely related to enabling `source()` to cache sources with the
package the same way the `exports_sources` attribute did. So now,
`export_sources()` effectively provides a "caching alternative" to the
`source()` method for out-of-source recipes. We're still considering refactoring
the `source()` method to support this behavior in the future, but that would be
a breaking change so if we do implement that, it will likely be in Conan 2.0. 

## Transparent CMake Integration

The next biggest accouncement from this release is that we've made yet another
major step towards more transparent CMake integration by adding components
support to the `cmake_find_package` generator. With this release, users can now
consume Conan dependencies within CMake projects in a truly transparent way. The
find_package generator provides the transparent mechanism, and the components
feature, along with the customizable target name feature in Conan, enable all
the targets align with existing target names, references, and interdependencies
which are used in the `CMakeLists.txt` of the open-source community.  This is the
culmination of more than a years worth of planning, so it's a very exciting
release for that reason.  

## New Sub-Command : conan config init

In the past, there have been many comments and suggestions about various
annoyances when setting up a new conan home directory from scratch.  `conan
config install` handles a vast majority of use-cases, but not all of them. There
are many niche cases where users want to provision a new workspace with all the
defaults values from the current conan version, and this was particularly
awkward.  `conan config install` provides a simple and intuitive way to handle
these cases.  

## Additional Features and Fixes  

For recipe authors, we have quite a few additional new features.   We have a new
"remove_file_by_mask" foWe have a new experimental `msvc` generator for cases
where people wanted `1-props-file-per-dependency`.  We have a new
`stdcpp_library` tool to make evaluating the C++ standard for the current build,
and writing conditionals around it easier.  On a related note, we've also
further improved our support for the Intel compiler on two fronts.  We're now
handling the C++ standard flag automatically, and making the CMake helper call
`compilervars.sh`, which is required for proper interop with Intel C++ compiler.

As usual, we cannot cover everything in the release in this blog post, so visit
the [changelog](https://docs.conan.io/en/latest/changelog.html#jun-2020) for the
complete list.  

-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
