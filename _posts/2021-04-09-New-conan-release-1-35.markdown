---
layout: post 
comments: false 
title: "Conan 1.35 : New [conf] items, new model
for dependency traversal, new model for environment variables, new Autotools
generators." 
description: "Conan 1.35 brings a long list of experimental new features
being created and tested in as part of the Conan 2.0 roadmap. This includes new
configurable items, major remodeling of dependency traversal and environment
variable abstractions, and the addition and refactor of generators based on
these new models. There are also over a dozen bugfixes."
---

Conan 1.35 adds a lot of new features. Before we start discussing them, we must
highlight the fact that they are virtually all **experimental**, and many of
which won't transition out of **experimental** status until Conan 2.0 is
released. This will likely be the case for the next few releases as well.  We're
adding new primitive **experimental** abstractions, refactoring existing
**experimental** features on top of these abstractions, and then adding new
**experimental** features on top of those. It's a whole lot of experimentation.
With that said, we definitely do not advise the use of these features in
production recipes or workflows for quite some time.

## New conan.tools.files namespace for Conan 2.0

The new
[`conan.tools.files`](https://docs.conan.io/en/latest/reference/conanfile/tools/files.html)
namespace currently contains only two documented functions:

* `patch()` (improved)
* `apply_conandata_patches()` (added)

However, the namespace is intended to be the new home of all of the existing
utility functions which relate to file operations, including:

* `mkdir()`
* `load()`
* `save()`
* `download()`
* `ftp_download()`

However, it's important to point out that we've also identified the need to
refactor virtually all of these file-related functions and change their function
signature. We don't want to break the existing functions, so we're using the
"namespace relocation process" as an opportunity to provide the functions with
the new signatures. It may be a few releases before these other functions in
this namespace are refactored and considered "stable", so please stay tuned.

## Install packages directly from Lockfile

One of the top feature requests we've had for those users experimenting with
Conan's "lockfile" feature is to perform a conan install using nothing but a
lockfile (without also needing to pass the package reference in that lockfile).
This is now possible. Lockfiles have always contained all the information
necessary to perform the Conan install, the only barrier was that there changing
the "conan install" command to accept a lockfile without a package reference
would be a breaking change. So, instead of breaking `conan install` in Conan
1.x, we've simply added a subcommand to "conan lock": [`conan lock
install`](https://docs.conan.io/en/latest/reference/commands/misc/lock.html#conan-lock-install)
which has the desired support. In Conan 2.x, `conan install` will support a
lockfile as an input directly, and `conan lock install` will likely be
deprecated.

## clean-modified command for lockfile bundles

In the last release, we added support for [lockfile
bundles](https://docs.conan.io/en/latest/versioning/lockfiles/bundle.html?highlight=bundle#lockfile-bundles)
for processing multiple lockfiles together at once. Only minimal commands were
provided at that time. In this release, we add the command [`conan lock bundle
clean-modified`](https://docs.conan.io/en/latest/reference/commands/misc/lock.html#conan-lock-bundle-clean-modified),
which does the same thing as [`conan lock
clean-modified`](https://docs.conan.io/en/latest/reference/commands/misc/lock.html#conan-lock-clean-modified),
but on all lockfiles in a bundle.

## Use [conf] to control build parallelization

The `[conf]` feature is starting to work out as intended, as a first-class
mechanism to configure specific and deeply-nested behaviors within Conan
operations. As of Conan 1.35.0, it can be used to control the [parallelization
parameters](https://docs.conan.io/en/latest/reference/config_files/global_conf.html?highlight=processes#tools-configurations)
passed to various build systems, with very flexible syntax. For example:

    [conf]
    tools.build:processes=10
    tools.microsoft.msbuild:max_cpu_count=20
    some_package:tools.ninja:jobs=30
    *:tools.ninja:jobs=30

The four lines in the profile section above demonstrate setting values for::

* All build systems
* Only  `MSBuild`
* Only `Ninja`, and only for a package named `some_package`
* Only `Ninja`, and for all packages not named `some_package`.

This is a great example of the textbook intended use-case for `[conf]`.

## Use [conf] to control actual Visual Studio installation

Here we have another great use of `[conf]`. Consider the following profile:

    [settings]
    compiler=msvc
    compiler.version=19.0

    [conf]
    tools.microsoft.msbuild:vs_version=16

In this case, the `vcvars` will locate and activate the Visual Studio 16
installation, but the `19.0` compiler version will still be used and the
corresponding default `toolset=v140` will be set.

Historically, there has been a bit of an awkwardness around using the Microsoft
tools within Conan. The way Microsoft releases them, there are implicit
associations between versions of the IDE (`Visual Studio`), the compiler
(`cl.exe`), and the "toolset" (eg. `toolset=v140`). Both the "Visual Studio"
compiler model, and the newer alternative `msvc` compiler model "respect" these
associations by default. When using the `msvc` compiler model, this new usage of
`[conf]` provides callers with a way to precisely control both the `Visual
Studio` used in a build, but use a non-default version of the compiler and
toolset.

## MSBuildToolchain produces conanvcvars.bat

Again, in the same spirit as many other new and experimental features,
[`MSBuildToolchain`](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html?highlight=msbuildtoolchain#msbuildtoolchain)
has been enhanced to improve reproducibility and transparency. Whereas before,
the toolchain would internally use Microsoft's
[`vcvarsall.bat`](https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-160)
to locate and use the desired versions of Microsoft build tools and call it, it
now takes an extra step and generates the results into `conanvcvars.bat` which
makes the location reproducible outside of Conan processes. As explained in the
previous section, this version of `Visual Studio` used is now configurable via
the `[conf]` item
[`tools.microsoft.msbuild:vs_version`](https://docs.conan.io/en/latest/reference/config_files/global_conf.html?highlight=vs_version),
and indeed that value will be the one written to `conanvcvars.bat` by the
`MSBuildToolchain`. Finally, it's also worth noting that the
[`MesonToolchain`](https://docs.conan.io/en/latest/reference/conanfile/tools/meson.html#mesontoolchain)
implementation [now uses this
script](https://github.com/conan-io/conan/pull/8719) when avaliable under the
hood to locate the Microsoft build tools.

## New "Visitor" Model for traversing dependency graph

The
[`MSBuildDeps`](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#msbuilddeps)
generator implementation has been refactored to use an experimental new
capability of iterating over the entire dependency tree to gather the
information needed to generate it’s files. The new
[`AutotoolsDeps`](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolsdeps.html)
also is using this capability. These are the first usages of this capability,
and take place in the `generate()` method of Conanfile. Other potential
use-cases of this capability may include advanced validation logic directly in
the `validate()` method of recipes, but such cases have not been tested yet.

Previously, generators were passed data structures to operate on:

* [`deps_cpp_info`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#deps-cpp-info)
* [`deps_env_info`](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#deps-env-info)
* [`deps_user_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#deps-user-info)

These data structures theoretically provide the generators with all of the
information needed by consumers. These data structures are intentionally
designed to be a separating layer between recipes and generators, to avoid
tight-coupling with potentially changing implementation details, and encourage
good boundaries.

However, these structures are limited to only include certain information which
was identified by the Conan team as being necessary for consumers. With the new
"Visitor" model, users can instead iterate over the actual instances of the
`conanfile` objects in the dependency graph. As a result, all limitations for
generators to read information about dependencies are effectively removed. So,
for example, recipe authors can define any number of custom python attributes
and methods within `conanfile.py`, and then write custom generators which read
those attributes, or execute those methods. Furthermore, far more "implicit"
information associated with each instance is available, such as `package_id`,
whether a dependency is a `requires` or a `build_requires`, etc. In short, this
makes generators much more powerful.

## New Environment Model for Recipes and Profiles

Conan has often been hailed for providing a brilliant and elegant first-class
experience for managing the complex needs around environment variables. Users
can pass in variables at the CLI, and recipes in the dependency graph can
produce them dynamically in `package_info()` method. Variables are separated
into "build" and "target" contexts for cross-build scenarios, and the virtual
environment generators produce shell scripts where the appropriate variables are
set. The number of advanced and complex cases handled properly by Conan's
"environment management" has always been very high, but never 100%. There have
always been some cases which seemed "out of reach" with the current
implementation.

However, after extensive analysis of numerous unresolvable Github issues and
discussion around Conan's modeling of the environment, we've identified some
deficiencies in the model. We've come up with an improved model which we believe
can come closer to handling 100% of use-cases.

The major change from the previous environment management is reproducibility.
All environment operations (variable add/append/remove) are now implemented
explicitly in a new [`Environment`](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html) class. Then, in all places where environment
variables have to be "applied" for various Conan operations, Conan no longer
applies them using Python function calls, which are impossible to reproduce
outside the Conan process invocation. Instead, a new generator called
[`VirtualEnv`](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualenv.htmlq) is used to produce shell scripts with the appropriate environment
variables set for the given context. Conan then will then use those scripts in
it's own shell invocations to produce the desired results, but in a way that the
user can reproduce from their own shell. Thus, the "reconciled
environment" will always be visible in generated files which can be opened,
analyzed, and re-used to reproduce build operations outside of Conan.

## New AutotoolsDeps, AutotoolsToolchain

Continuing the previous work on the new (still **experimental**) generator and
toolchain model, AND the new "Environments" model described above, Conan now has
`Deps` and `Toolchain` generator classes for `Autotools`. These automatically
use the shell scripts produced by `VirtualEnv` generator (when they are
available).

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#April-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
