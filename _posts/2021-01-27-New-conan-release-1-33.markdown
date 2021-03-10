---
layout: post
comments: false
title: "Conan 1.33: New configuration mechanism in profiles, new Qbs toolchain and
MSVC compiler settings, and better support for Apple platforms such as Catalyst."
---

Conan 1.33.0 is a big release! We're introducing a new section in profiles named
`[conf]`, and a corresponding configuration file named `global.conf` to
enable setting of related values globally. We've improved support for Qbs with a
new toolchain and build helper, as well as a new build helper for Meson. We've
added a new generator called CMakeDeps, and updated the "build_modules" strategy
to support passing different build modules for different generators. A new
`strip_root` argument to the ubiquitous `tools.get()` function, and has also
been added to the related functions of `tools.unzip()` and `tools.untargz()`.
We've now also added two new sub-settings under `macOS` : `sdk` and `subsystem`,
the latter to support [Mac Catalyst](https://developer.apple.com/mac-catalyst/).

## New [conf]iguration section in profiles and global.conf

In this release, Conan is adding some new configuration capabilities. For
various reasons, `conan.conf` was not a suitable place for the global
definitions of these configurations, so we've introduced a new file in the Conan
user home directory specifically for this purpose:

[`global.conf`](https://docs.conan.io/en/latest/reference/config_files/global_conf.html)

The primary purpose of this file at this time is to define global values for the
new profile block known as `[conf]`. The `[conf]` feature provides a new way for
users to pass paramters to Conan recipes and Conan-provided tools. By default,
`[conf]` parameters and values do not affect `package_id`, so it is very similar
to the `[env]` block of profiles. However, the big difference is that `[conf]`
is logically dedicated for the purpose of declaring and specifying parameters
for Conan behavior, whereas the `[env]` block is really designed for declaring
and specifying parameters for other command-line tools which are invoked by
Conan, such as build scripts, builds systems, compilers, linkers, etc.

You can use `[conf]` to declare arbitrary variables and values, prefixed with
the `user` namespace. Notice that you can define one value to apply to all
packages, and then define values on a per-package basis just like the `[env]`
section. Again, this can be defined in either a profile, or `global.conf`:

```yaml
[conf]
user.mycompany.logging:print_all_env_vars=False
mypkg:user.logging:print_all_env_vars=True
```

Here, you can see that we've used a sub-namespace of `mycompany` which is
recommended for all custom uses of `[conf]` to avoid potential conflicts in the
future. You can then use these variables and values in your recipes like this:

```python
class Pkg(ConanFile):
    name = "mypkg"

    def build(self):
        if(self.conf["user.mycompany.logging:print_all_env_vars"]):
            for param in os.environ.keys():
                self.output.info("%s=%s" % (param, os.environ[param]))
                # Will print all env vars defined at build as "key=value" pairs
```

However, in addition to providing a new feature for Conan recipe authors to
expose parameters from recipes like this, the `[conf]` feature is used to expose
parameters for built-in Conan classes and functions in Conan's `tools`
namespace. This includes `build_helpers`, `generators`, `toolchains`, and other
free functions. For example, we've used it to expose `MSBuild`'s verbosity
setting. As you can see in the example below, we expose such `conf` items using
the full namespace of the tool or function, in this case,
`tools.microsoft.msbuild_verbosity`:

```yaml
[conf]
tools.microsoft:msbuild_verbosity = Quiet
mypkg:tools.microsoft:msbuild_verbosity = Normal
mypkg2:tools.microsoft:msbuild_verbosity = Diagnostic
```

Finally, we've also used it to expose some parameters relating to "core"
behaviors of Conan under a `core` namespace.

```yaml
core:required_conan_version = "expression"
core.package_id:msvc_visual_incompatible
```

The first question many people will ask when learning about this new feature is:
"when should I use `[conf]` instead of `[settings]` or `[options]`?"

The key factor is whether or not the parameter will affect the binary because
`[conf]` does not affect `package_id` by default (note: we are looking at making
it possible to opt-in to `[conf]` affecting `package_id` on-demand). So for
example, optimization level would not be a good fit to expose via `[conf]`,
because different values will result in differnet binaries. Aside from
`verbosity`, other examples which would be good fits include the number of
processors to use, whether or not to build in parallel, paths to generated log
files, etc. Outside of the built-in usages we're implementing, the most common
usage we suggest is to replace instances where people have used environments
variables to implement non-binary-affecting parameters for recipes.

In summary, the `[conf]` feature is still very new in it's implementation, and
there is a lot more we hope to add to it in the upcoming releases (most
importantly, CLI-argument support). Still, we know there are probably several
use cases out there which we have not thought of but which `[conf]` could be
expanded to address. If you think you have a use case which might be a good
candidate for `conf`, please let us know by opening github
[issue](https://github.com/conan-io/conan/issues).

## New strip_root parameter to tools.get()

The function known as `tools.get()` has been around a long time, and makes it
very convenient to get source code files for packages. It does this by providing
a single function which:

- downloads the sources
- automatically detects when it's a compressed `.zip` or `.tar.gz` file
- automatically extracts the contents with the appropriate tool

One of the unfortunate details of many source archives is that there is often a
"root directory" inside the archive, with all the files residing inside that
directory.  So, after extraction, there's an extra folder layer with some name
which needs to be managed in some way. No matter how it's managed, it results in
extra lines of code in the recipe, typically having to explicitly reference the
directory name in both the source and build method.

`tools.get()` now gives us a better way! By passing the parameter of
`strip_root=True`, the unzip process will understand that this root directory is
un-necessary, and it will not be present after the sources are extracted.

Of note, `tools.get()` relies internally on two other public `tools` functions,
which now also support the same parameter. In summary, here are the three
affected function signatures.

- `tools.get(...., strip_root=True)`
- `tools.unzip(...., strip_root=True)`
- `tools.untargz(...., strip_root=True)`

## New Meson, Qbs, and CMake Integrations

For the `Qbs` build system, we've added a new [`toolchain` and
`build_helper`](https://docs.conan.io/en/latest/reference/conanfile/tools/qbs.html#qbs)
which leverage our new model for build system integrations.  You can use them in
your recipes like so:

```python
from conan.tools.qbs import Qbs, QbsToolchain

class Pkg(ConanFile):

    def generate(self):
        tc = QbsToolchain(self)
        tc.generate()

    def build(self):
        qbs = Qbs(self)
        qbs.build()
```

For `Meson`, we already a toolchain class, but this release introduces a
`build_helper` for it.  So, now usage looks the same as `Qbs` above.

```python
from conan.tools.cmake import Meson, MesonToolchain

class Pkg(ConanFile):

    def generate(self):
        tc = MesonToolchain(self)
        tc.generate()

    def build(self):
        meson = Meson(self)
        meson.build()
```

Also, we've had numerous `CMake` integrations for a long time, including a
Toolchain, a Build Helper, and numerous Generators. With this release, we're
adding another Generator named
[`CMakeDeps`](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake.html?highlight=cmakedeps#cmakedeps).
In truth, it's just the `cmake_find_package_multi` under a new name and
namespace, and leveraging the new integrations model. Here it is together with
the toolchain and build helper.

```python
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps

class Pkg(ConanFile):

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
        deps = CMakeDeps(self)
        deps.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
```

## Per-Generator build_modules on cpp_info

Another integration point we're continuing to improve support for is the use of
additional build system files such as `.cmake` files for CMake.  Organizations
may have been using such files prior to Conan, or may have some special use
cases which make declaring variables in these external files to have some
advantage over defining them in Conan's `cpp_info` data structure.

In any case, for quite a while we've had an experimental implementation
supporting only CMake.  With this release, we make it possible to support any
number of build systems by changing the syntax. Here's an example of the new
syntax:

```python
    self.cpp_info.build_modules["cmake_find_package"].append("cmake/myfunctions.cmake")
```

`cpp_info.build_modules` now supports taking a dictionary where the key is the
name of the generator that the build_module should be `include()`d into, and the
values are a list of paths to the files to `include()`.

Currently, we've only implemented the functionality to do the include into the
CMake generators, but in the future, we hope to implement support into all
generators. If you have a build system you would like to see supported with this
feature, please open a Github issue to request it.

## New `msvc` compiler in settings

This release signals the start of yet another major migration process in
Conan's binary modeling strategy. We've now added a new compiler named `msvc`.
Indeed as you may have guessed, the long-term goal is therefor to eventually
replace the compiler name of `Visual Studio` in Conan's settings.

Furthermore, this setting comes along new models for `compiler.version` and
`compiler.runtime`.  For version, `msvc` now models the actual compiler
executable version rather than the IDE version.  For runtime, what was
previously `compiler.runtime` is now divided into `compiler.runtime` and
`compiler.runtime_type`.

So, whereas the old syntax was:

```yaml
compiler="Visual Studio"
compiler.version=16
compiler.runtime=MDd
```

The equivalent syntax for the new compiler model is:

```yaml
compiler=msvc
compiler.version=19.1
compiler.runtime=dynamic
compiler.runtime_type=Debug
```

The timeline for this feature is that we would like to have it stabelized in
version future release of Conan 1, and make it the default model for Conan 2.0.
This includes completely removing the visual studio generator in Conan 2.0. For
this reason, the more users who migrate to this generator ahead of time and
provide feedback, the better it will be for Conan 2.0.

## Improved support for Apple platforms

Apple continues to release new and different platforms and options for
developers, and we're continuing to track that with Conan. We've added support
for [Mac Catalyst](https://developer.apple.com/mac-catalyst/) by adding the
subsetting of `subsystem` under `Macos`, and then adding the `catalyst` option
to it. Additionally, to properly allow developers to distinguish binaries built
for embedded Apple platforms, and those built for their simulator, we've added
a subsetting of `sdk` under each of the following Apple-related `os` settings:

```yaml
    Macos:
        version: ...
        sdk: [None, "macosx"]
        subsystem: [None, "catalyst"]
    iOS:
        version: ...
        sdk: [None, "iphoneos", "iphonesimulator"]
    watchOS:
        version: ...
        sdk: [None, "watchos", "watchsimulator"]
    tvOS:
        version: ....
        sdk: [None, "appletvos", "appletvsimulator"]
```

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jan-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
