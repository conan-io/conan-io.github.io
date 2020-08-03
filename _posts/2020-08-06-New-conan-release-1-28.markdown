---
layout: post 
comments: false 
title: "Conan 1.28: Lockfile improvements, New attributes: 
provides, required_conan_version and recipe_folder, Improved Clang support on Windows, 
Support components in pkg_config generator, Define generator filenames"
---

Conan 1.28 has been released. With a long list of new features, it definitely
feels like progress! Lockfiles were basically completely overhauled, so lets
start there.

## Lockfile Improvements

First, the command itself has complete changed. What was previously:

```bash
    conan graph lock
```

is now:

```bash
    conan lock
```

Next, a new parameter is now mandatory when using lockfiles with the `conan
create` command. If you pass a `--lockfile` parameter, you must also pass the
`--lockfile-out` parameter. Users can pass the same filename for both, effectively
overwriting the original lockfile, but in many cases users will want them to be
different. The previous behavior was confusing in many cases.

Next, a new concept has been added which we call "Base lockfiles". Base
lockfiles only capture the topology of the dependency graph. Specifically, it
locks the `ref` field which includes `name/version@user/channel`. If revisions
are enabled, it will also lock the `rrev` field which contains the "recipe
revision". It does NOT capture the package ID, or package revision fields. This
is particularly helpful in solving a common race condition experienced in
continuous integration workflows which perform multiple builds. Often times,
each build is performed in a separate and clean workspace, and starts building
at different times. Even when done "in parallel", they can be slightly offset.
The problem is that other jobs can be uploading new versions or revisions of
dependencies at any time. Thus, running `conan lock` multiple times in different
workspaces, even just a few seconds apart, could result in different
configurations locking different revisions of the same dependency. Now, CI jobs
can begin by calling `conan lock` with the `--base` flag. This will produce a
"general" lockfile which only locks the name and versions of dependencies. A
copy of this lockfile can be passed to `conan create` in each of the future
build stages that follow, which will add the configuration-specific fields and
information to the copies.

This "base lockfile" concept leads to the next major improvement: stronger
enforcement of "locked" values making each field in a lockfile "truly
immutable". This is not to say that a lockfile cannot be
updated (lockfiles can and are updated). The rule is this: empty fields in a
lockfile can be populated, but once a field has a value, it cannot change. Base
lockfiles are a good example of cases which have unpopulated fields which are
waiting for future commands to set values in. This improvement was very
important, as it was recently discovered that there were several ways to
produce completely invalid and unbuildable lockfiles in previous versions. That
should no longer be possible moving forward.

## New Attributes: provides, required_conan_version, recipe_folder

Conanfile.py learned a few new attributes based on feature requests from users.

`provides` is a very important new attribute which is helpful for dealing with
packages that are known to produce conflicts. For a simple example, we can look
to three separate libraries/packages: `libjpeg`, `libjpeg-turbo`, `mozjpeg`.
They are all alternate implementations of the same libraries which produce the
same symbols. If you try to compile and link all three at the same time, you
will be in violation of the "One-Definition Rule" (ODR) of C++ and receive fatal
compiler errors.  By adding this attribute to Conan, we can detect the violation
based on the attribute before compilation begins, saving significant time in a
number of cases.

`required_conan_version` enables users to declare what minimum version of Conan
a recipe requires. With the rapid evolution of Conan and new features coming out
every month, this attribute makes a lot of sense. If you are familiar with the
`CMake` build system, you might recognize that this is similar to
`cmake_required_version`.

`recipe_folder` simply makes it easier for recipes to programatically refer to
the directory where the `conanfile.py` is currently being built from. This is
helpful a number of cases for custom generators, python requires, and other
tricky scenarios. This feature has been requested a number of times over the
years, so we were happy to get it done in this release.

## Improved Clang Support on Windows

With this release, we finally were able to merge a PR that had been outstanding
for nearly 1 year.  The diff only shows 6 lines in a single file have changed,
but this belies the magnitude of the research, consideration, and discussion
that has gone into it. With this, the default `settings.yml` now includes
some necessary changes to support more of the use cases for Clang on windows.

The reason this PR was outstanding for so long was because Clang presents
multiple unique and challenging problems for modeling ABI compatibility in a
formalized way (which is what Conan does.) First, users of Clang have two
executables which they can choose from: `clang.exe` and `clang-cl.exe`. They CAN
produce identical/compatible binaries, but `clang.exe` can also produce
incompatible binaries. Next, on linux, `Clang` has always had a flag named
`-stdlib` for the user to define the standard library to link against. On
Windows, `Clang` links against Microsoft's STL rendering this flag irrelevant.
Conversely, on Windows, `Clang` (just like `CL.exe`) allows users to choose the
`MSVC` runtime to link against (`MT`/`MD`/etc). This concept does not exist for
Clang on Linux. So, the current PR adds the `runtime` subsetting for `clang`
compiler, and makes the existing subsetting of `libcxx` optional by adding
`None` as a valid choice.

It's important to note that these new settings, while a big step forward, are
just the first step. Providing a truly robust and first-class experience with
`clang-cl` on windows will require an iterative approach over several releases,
taking feedback along the way (that's how we do most things around here.)  We're
already working hard on some of the next steps, but user feedback on this first
set of changes would be very helpful.

## Support components in pkg-config generator

A few releases ago, we released our first draft of the concept of "package
components", where a package could separate the things that it provides into
components which could be selectively consumed by downstream packages.  Shortly
thereafter, we added support for these components to the CMake family of
generators. With this release, we add support to the `pkg-config` generator.

## Define generator filenames (CMake Only)

All generators produce the generated files using the naming convnetion of:
`conanbuildinfo.xyz` where `xyz` is the typical file extension associated with
the corresonding build system or platform. This was unconfigurable. Over the
past year, this convention has been revisited for a few different reasons. The
change for this particular release was to enable recipe authors to set the
generated build system file name as an attribute on `cpp_info`.  

## Additional Features and Fixes  

Add content

As usual, we cannot cover everything in the release in this blog post, so visit
the [changelog](https://docs.conan.io/en/latest/changelog.html#aug-2020) for the
complete list.  

-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
