---
layout: post 
comments: false 
title: "Conan 1.37 : new default URL for ConanCenter, new layout() method, new
Bazel integrations, new build_policy=never, new --build-require flag" 
meta_title: "Version 1.37 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.37 : new URL for ConanCenter, new layout method, new
integration for Bazel, new build_policy never, new build-require flag."
---

Conan 1.37 brings several significant new features. At the top of the list, is a
new URL for Conan Center added to the default remotes.txt which comes with the
Conan client. The release also includes a major new method to conanfile.py
called `layout()`, and some new classes for integration with the
[Bazel](https://docs.conan.io/en/latest/integrations/build_system/bazel.html)
build system. There is also a new `build_policy` called `never` and a new flag
called `--build-require` which works with the `conan install` and `conan create`
commands.

## New default URL for ConanCenter

With this release, the Conan client will now come installed with the following 2
URL's in `remotes.txt` (in the following order):

* `https://center.conan.io`
* `https://conan.bintray.com`

It's important to understand that these URL's point to two separate Conan
repositories, and they have the following differences:

### `https://conan.bintray.com`

This repository contains copies of all Conan packages, new and legacy (by
"legacy" we mean packages which predate ConanCenterIndex). Currently, copies of
all new package builds and binaries are uploaded here. On **July 1st**, new
packages will **STOP** being uploaded here, and the repository will effectively
become read-only.

### `https://center.conan.io`

This repository only contains copies of all Conan packages which have been built
from ConanCenterIndex (no legacy packages). Currently, copies of all new package
builds and binaries are uploaded here.  On **July 1st**, this repository will
become the **ONLY** place where new packages are uploaded. This is why we have
added it to the client in the first position.

### Long-term deprecation: `https://conan.bintray.com`

We have not yet set a date for the removal of the conan.bintray.com URL from the
default list of remotes, nor the physical deletion of the repository and its
packages. These events are likely to be quite far out into the future. However,
everyone should understand that they are ultimately planned for removal some
day.

## New `layout()` method for `conanfile.py`

The new
[`layout()`](https://docs.conan.io/en/latest/reference/conanfile/methods.html#layout)
method is one of the most interesting and long-awaited new additions to
`conanfile.py` in a while. So, here we'll explain it's basic value propositions,
but first, a simple example:

```python
def layout(self):
    self.cpp.source.includedirs = ["include"]
    self.cpp.build.libdirs = ["."]
    self.cpp.build.libs = ["mylib"]
    self.cpp.build.includedirs = ["gen_include"]
    self.cpp.package.libs = ["mylib"]
```

The first benefit we want to highlight is that it provides a new way to declare
information for downstream consumers, when a package is in
[`editable_mode`](https://docs.conan.io/en/latest/developing_packages/editable_packages.html).
Historically, the place to declare information for consumers was inside the
`package_info()` method. However that method was not designed to handle the case
of packages in `editable_mode`, so initially we provided a separate mechanism
for handling the `editable_mode` case known as [`layout
files`](https://docs.conan.io/en/latest/developing_packages/editable_packages.html#layout-external-files)
However, those files are external to the recipe, so the big improvement with the
`layout()` method is that recipes authors can delcare the information inside the
recipe which feels more natural and was highly requested by many users.

There is also another major benefit of defining appropriate values in the
`layout()` method. It enables users working with the "local development
workflow" (in their local workspace) to more accurately reproduce the steps
performed by the `conan create` command which take place exclusively in the
conan cache. So, now users can have the recipe in the local directory, and run
the local flow commands:

```shell
    conan source
    conan build
    conan package
```

Conan will effectively do the same operations as it would do for `conan create`,
but those operations will use the directories in the user-space.

Finally, we are experimenting with one other possible benefit of declaring all
the appropriate information in the `layout` method. That is, the ability to
"automatically" implement the traditional `self.copy` steps of the `package()`
method, which appear as boilerplate in many recipe. So, in the future, we may
simply be able to write something like this...

```python
def package(self):
    LayoutPackager(self).package()
```

... to replace `package()` methods which might currently look like this ...

```python
def package(self):
    self.copy("*.h", src="include", dst="include")
    self.copy("*.hpp", src="include", dst="include")
    self.copy("*.hxx", src="include", dst="include")
    self.copy("*.a", src=".", dst="lib")
    self.copy("*.so", src=".", dst="lib")
    self.copy("*.so.*", src=".", dst="lib")
    self.copy("*.lib", src=".", dst="lib")
    self.copy("*.dylib", src=".", dst="lib")
    self.copy("*.dll", src=".", dst="bin")
    self.copy("*.exe", src=".", dst="bin")
```

Of note, have already identified some challenges to this strategy, and
discussing major changes and improvements to `LayoutPackager` in upcoming
releases, so it's definitely not safe to use for production recipes. We are only
providing it in this release for power-users to perform experiments and provide
feedback.

## New Bazel Integration

We've added the following two new generators for the
[Bazel build system](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html?highlight=bazel)
which are similar in nature to the `CMakeDeps` and `CMakeToolchain` generators:

* `BazelDeps`
* `BazelToolchain`

We've also added a standard build helper class named `Bazel` to make calling
Bazel from the CLI less error prone (similar to `CMake` and `MSBuild` build
helpers).

```python
    def build(self):
        bazel = Bazel(self)
        bazel.configure()
        bazel.build(label="//main:hello-world")
```

While there are few open-source projects today using Bazel compared to some
other build systems, there are enterprise teams using it for their internal
components who have requested it.

### New `build_policy=never`

There are essentially two ways to create a Conan package:

* `conan create` : compiles sources into binaries and then packages them
* `conan export-pkg` : takes precompiled binaries and packages them

One of Conan's marquee features is the unique ability to pass `--build` to the
`conan install` command and have Conan re-build some or all dependencies in the
graph from source.  Unfortunately, for any packages in the dependency graph
which were created using `conan export-pkg` command, rebuilding from source is
impossible. This leads to awkward issues when passing `--build`.

Now, recipe authors can and should add the following attribute to any recipes
which are designed to be used with `conan export-pkg`:

```python
    build_policy=never
```

When Conan encounters recipes with `build_policy=never`, it will understand that
this recipe cannot be rebuilt from source and continue on to the next recipe
without error.

### New `--build-require` flag

The `conan install` and `conan create` commands now support an additional flag:
`--build-require`. The need for this flag was discovered as a consequence of the
new `build` and `host` "contexts" used for cross-building. The use-cases for it
are not the most common workflows, so we'll try to clarify the purpose here.

The most common way to build tools as `build_requires` in Conan is to list them
as such in a `conanfile` or in a `profile`. In these cases, it's easy for Conan
to understand that those packages belong to the `build` context, and use the
`build` profile for those packages. So, we don't need the `--build-require` flag
at all in these cases.

However, there are cases when users want to work with the recipe or package for
the build tool all by itself. For example, when you install it via reference
with run `conan install build_tool/1.0.0 ...` . Or, alternatively, when you're
creating or modifying/testing the recipe for the build tool with `test_package`.
In these cases, you call `conan create` on the build tool recipe, and you could
pass a separate "host profile" (`-pr:h windows`) and "build profile" (`-pr:b
linux`), but Conan will have no way to know that the recipe being created should
use the "build profile" instead of the "host profile". These are the reasons for
the `--build-require` flag. It tells Conan that the recipe or package being
installed or created should use the "build profile" (`-pr:b`).

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#June-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
