---
layout: post
comments: false
title: "Introducing conan-py-build: Build Python Wheels with C/C++ Extensions Using Conan"
description: "conan-py-build is a new PEP 517 build backend that brings Conan's native C/C++ dependency management into the Python wheel build. Try it and share your feedback!"
meta_title: "Introducing conan-py-build: Build Python Wheels with C/C++ Extensions Using Conan - Conan Blog"
keywords: "conan, C++, python, wheel, pep 517, build backend, extension, pybind11, nanobind, cibuildwheel"
categories: [cpp, conan, python]
---

Packaging Python extensions that contain native C or C++ code has come a long
way. [PEP 517](https://peps.python.org/pep-0517/) defined a clean contract
between Python build frontends (`pip`, `build`, `uv`) and the build backend
that produces the wheel. That standard is what makes it possible today to
connect a `CMakeLists.txt` to a `pyproject.toml`, declare a backend, and let
`pip wheel .` drive the build.

The C/C++ dependency layer is a different story. Somewhere between
`pyproject.toml` and `CMakeLists.txt`, a `find_package(OpenSSL)` has to resolve.
In practice, most projects solve that outside the wheel build: through system
packages, vendored source trees, `FetchContent`, a separate native package
manager install step, or platform-specific scripts in CI. That means a separate
step to manage before the Python build, often duplicated across CI
configurations and developer setups.

Today, we are happy to introduce **conan-py-build**, a PEP 517 build backend
that brings Conan's C/C++ dependency management directly into the Python wheel
build.

The project is still in active development, and we are releasing it now to
gather early feedback. We would love for you to try it and tell us what you
think.

## What is conan-py-build?

`conan-py-build` is a build backend for Python packages that contain native
C/C++ extensions. You declare it in `pyproject.toml`, provide a `conanfile.py`
that describes the C/C++ build and its dependencies, and build wheels through
standard Python packaging commands such as `pip wheel .`.

When a build runs, `conan-py-build`:

1. Resolves the C/C++ dependency graph through Conan, downloading precompiled
   binaries where available and building the rest from source
2. Prepares the build toolchain through the corresponding Conan generators
   (for example `CMakeToolchain` and `CMakeDeps` for CMake, or `MesonToolchain`
   and `PkgConfigDeps` for Meson)
3. Builds the extension using your project's build system
4. Copies runtime shared libraries from Conan dependencies next to the extension
   module and patches RPATH on Linux and macOS where applicable
5. Packages the result into a standard Python wheel

Because it is a PEP 517 backend, it plugs into `pip`, `build`, and `uv` directly, and fits into `cibuildwheel`-based CI workflows for multi-platform builds.

## What conan-py-build is really for

Driving the underlying build system is largely a mechanical step. Where `conan-py-build` focuses its design attention is on the layer around it: the parts that typically leak out of the wheel build and into shell scripts, CI configuration, or manual steps. These are the responsibilities it takes into the backend:

**Native dependencies resolved inside the PEP 517 build.** The common workflow today is to run a separate native-dependency step (for example `conan install`, or `vcpkg install`, or a custom CMake `FetchContent` chain) before invoking the Python build frontend. `conan-py-build` collapses that into a single entry point: `pip wheel .` resolves the C/C++ graph, configures the toolchain, builds the extension, and produces the wheel. One command, one configuration source.

**Not tied to a single build system.** `conan-py-build` drives your `conanfile.py` the same way Conan always does, whether your project uses CMake, Meson, Autotools, MSBuild, or a custom build. The backend does not assume CMake. Use whatever build system your project already has, and let Conan handle the integration through the corresponding toolchain and dependency generators.

**A recipe ecosystem for C/C++ libraries.** Conan Center Index ships hundreds of recipes for widely-used libraries (OpenSSL, Boost, ICU, Qt, FFmpeg, HDF5, GDAL, and many more) with canonical patches, options, and cross-platform support. Your `conanfile.py` consumes those with `self.requires("openssl/3.x.y")` instead of reimplementing each library's build in FetchContent wrappers or vendoring its source tree into your repo. Those recipes are continuously tested across a wide matrix of compilers, operating systems, and architectures, so their builds are validated in configurations close to what your wheel matrix targets.

**Binary caching that survives across projects and CI runs.** Conan caches compiled dependencies keyed by settings, options, and compiler. The same `openssl/3.x.y` binary is reused across wheel builds, Python versions, and CI matrices, rebuilt only when those settings actually change. For non-trivial graphs, this is the difference between seconds and hours on each build, and it works the same way whether you use Conan Center, a self-hosted Artifactory, or any other Conan remote.

**Conan profiles as build configuration.** Host and build profiles describe compiler, runtime, architecture, OS version, and the resolved settings of every transitive dependency in the graph. The same profiles your team uses for regular C/C++ work apply to the wheel build. That means the ABI of your dependencies stays consistent between a standalone Conan build of your library and a Python wheel build of the same code, with no drift between what your C/C++ CI produces and what your Python CI produces.

**Reproducibility of the native graph.** Conan lockfiles pin exact versions, options, and revisions of every transitive C/C++ dependency. A wheel built from a locked graph on a developer laptop and on CI uses the same native libraries, not just the same Python source.

**Runtime shared library handling inside the backend.** Shared libraries from Conan dependencies are deployed next to the extension module during the build and RPATH-patched on Linux and macOS, so the wheel carries what it needs to load at runtime. This is not a replacement for `auditwheel`/`delocate`/`delvewheel` when you need full manylinux compliance and system-library auditing, but it removes the most common "imports locally, crashes on another machine" failure mode without needing an extra repair step.

If any of this was already part of your workflow through external scripts and glue, `conan-py-build` pulls that responsibility into the backend itself. If none of it was, you get it by default.

## Getting Started

Getting started requires just three files alongside your existing C++ code.

**pyproject.toml**

```toml
[build-system]
requires = ["conan-py-build"]
build-backend = "conan_py_build.build"

[project]
name = "mypackage"
version = "0.1.0"
```

**conanfile.py**

```python
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout

class MyPackageConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        self.requires("pybind11/2.13.6")

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
```

**CMakeLists.txt (excerpt)**

The extension module must be installed into the Python package directory so that `conan-py-build` can include it in the wheel:

```cmake
install(TARGETS _core DESTINATION mypackage)
```

**Building the wheel**

```bash
$ pip install conan-py-build
$ pip wheel . -w dist/
```

Conan resolves `pybind11` from Conan Center Index, CMake compiles your extension, and you get a platform-specific wheel in `dist/` ready for distribution.

## Real-World Examples

The [examples/](https://github.com/conan-io/conan-py-build/tree/main/examples) directory contains complete, working projects for the most common scenarios:

- **[basic](https://github.com/conan-io/conan-py-build/tree/main/examples/basic)** — Minimal C extension using the `fmt` library
- **[basic-pybind11](https://github.com/conan-io/conan-py-build/tree/main/examples/basic-pybind11)** — pybind11 bindings with dynamic versioning and PEP 639 license files
- **[basic-meson-pybind11](https://github.com/conan-io/conan-py-build/tree/main/examples/basic-meson-pybind11)** — the same pybind11 example, but using Meson instead of CMake as the build system
- **[basic-nanobind](https://github.com/conan-io/conan-py-build/tree/main/examples/basic-nanobind)** — nanobind bindings with a custom Conan profile for C++17
- **[external-sources](https://github.com/conan-io/conan-py-build/tree/main/examples/external-sources)** — C++ sources fetched by the `source()` method, not bundled
- **[cibw-example](https://github.com/conan-io/conan-py-build/tree/main/examples/cibw-example)** — Full multi-platform CI with cibuildwheel on Linux, macOS, and Windows

The `cibw-example` is particularly worth reading if you are targeting multiple platforms, since it shows how Conan profiles map onto a cibuildwheel matrix with much less platform-specific build glue.

## Project Status and Call for Feedback

`conan-py-build` is currently in **beta**. The core build workflow is tested on Linux, macOS, and Windows across the Python versions currently supported by the project, and the package is available today on [PyPI](https://pypi.org/project/conan-py-build/). That said, this is still early-stage software with rough edges. Some workflows we care about (editable installs, more complete manylinux repair scenarios, complex multi-extension layouts) are still being smoothed out, and there are almost certainly cases we have not seen yet.

We are releasing now precisely because real-world usage is the fastest path to a well-rounded tool. We are especially interested in feedback from projects with unusual package layouts, complex C/C++ dependency trees, cross-compilation requirements, or existing CI constraints that make native wheel builds painful today.

Did something not work as expected? Is there a workflow you wish were supported? Please open an issue on [GitHub](https://github.com/conan-io/conan-py-build/issues). Every report, question, and suggestion helps us reach a stable release faster.

## Conclusions

PEP 517 has made the Python-packaging side of building wheels with C/C++ extensions a well-supported workflow. `conan-py-build` builds on that foundation and pulls the native C/C++ dependency layer *inside* the PEP 517 build, backed by Conan's recipe ecosystem, binary cache, profiles, and lockfiles, so the Python build and the C/C++ build stop being two separate problems held together by glue.

If your extension has non-trivial native dependencies, or if you have been maintaining a separate native-dependency step alongside your Python build, we think it is worth a look.

Check out the [documentation](https://conan-py-build.conan.io), browse the [examples](https://github.com/conan-io/conan-py-build/tree/main/examples), try it on a real project, and let us know where it fits, or where it does not yet.

Happy coding!
