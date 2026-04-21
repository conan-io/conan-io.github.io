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
way. [PEP 517](https://peps.python.org/pep-0517/) defined a contract between
Python build frontends (`pip`, `build`, `uv`) and the build backend
that produces the wheel. That standard is what makes it possible today to
connect a `CMakeLists.txt` to a `pyproject.toml`, declare a backend, and let
`pip wheel .` drive the build.

The C/C++ dependency layer is a different story. Somewhere between
`pyproject.toml` and `CMakeLists.txt`, a `find_package(OpenSSL)` has to resolve.
In practice, most projects solve that outside the wheel build: through system
packages, vendored source trees, `FetchContent` or a separate native package
manager install step. That means a separate step to manage before the Python
build, often duplicated across CI configurations and developer setups.

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
3. Builds the extension using your project's build system
4. When the extension links against shared libraries, copies those runtime
   dependencies next to the extension module and patches RPATH on Linux and
   macOS where applicable
5. Packages the result into a standard Python wheel

Because it is a PEP 517 backend, it plugs into `pip`, `build`, and `uv`
directly, and fits into `cibuildwheel`-based CI workflows for multi-platform
builds.

## Getting Started

> The example below uses CMake for illustration. `conan-py-build` is agnostic of
> the build system, so Meson, Autotools, and others work the same way.

Let's build a tiny Python package that exposes a single function, `greet(name)`,
which prints a colored greeting to the terminal. The formatting and the ANSI
color output come from [{fmt}](https://fmt.dev), a C++ library we pull in
through Conan, and the Python bindings are built with pybind11.

The project layout:

```
mypackage/
├── pyproject.toml
├── conanfile.py
├── CMakeLists.txt
└── src/
    ├── mypackage/
    │   └── __init__.py
    └── mypackage.cpp
```

`pyproject.toml` declares the build backend and the project metadata:

```toml
[build-system]
requires = ["conan-py-build"]
build-backend = "conan_py_build.build"

[project]
name = "mypackage"
version = "0.1.0"
```

`conanfile.py` describes the C/C++ side: its dependencies (`pybind11` and `fmt`)
and how they are built and packaged.

```python
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout

class MyPackageConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        self.requires("pybind11/3.0.1")
        self.requires("fmt/12.1.0")

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
```

`CMakeLists.txt` builds the extension against pybind11 and fmt and installs
the resulting module into the Python package directory so the backend picks it
up when assembling the wheel:

```cmake
cmake_minimum_required(VERSION 3.15)
project(mypackage LANGUAGES CXX)

set(PYBIND11_FINDPYTHON ON)
find_package(pybind11 CONFIG REQUIRED)
find_package(fmt REQUIRED)

pybind11_add_module(_core src/mypackage.cpp)
target_link_libraries(_core PRIVATE fmt::fmt)

install(TARGETS _core DESTINATION mypackage)
```

The C++ source defines `greet(name)` using fmt's color support and exposes it
as a compiled `_core` module:

```cpp
#include <pybind11/pybind11.h>
#include <fmt/color.h>

void greet(const std::string& name) {
    fmt::print(fmt::fg(fmt::color::green), "Hello, {}!\n", name);
}

PYBIND11_MODULE(_core, m) {
    m.def("greet", &greet);
}
```

And `src/mypackage/__init__.py` re-exports it so callers see `mypackage.greet`:

```python
from mypackage._core import greet

__all__ = ["greet"]
```

With that in place, building the wheel is the standard Python packaging
command:

```bash
$ pip install conan-py-build
$ pip wheel . -w dist/
```

Conan resolves `pybind11` and `fmt` from Conan Center Index, CMake compiles the
extension against them, and you get a platform-specific wheel in `dist/`.
Install it and try it:

```bash
$ pip install dist/mypackage-*.whl
$ python -c "import mypackage; mypackage.greet('world')"
Hello, world!
```

That last line comes out in green.

## What conan-py-build is really for

Driving the build system is the mechanical part. The goal of `conan-py-build` is
to pull the surrounding responsibilities into the backend so they do not leak
into shell scripts and CI configuration:

- **Dependency resolution inside the build.** `pip wheel .` resolves the C/C++
  graph, configures the toolchain, builds the extension, and produces the wheel.
  No separate install step before the Python frontend.
- **Build-system agnostic.** The backend drives your `conanfile.py` regardless
  of whether your project uses CMake, Meson, Autotools, or anything else.
- **Conan Center Index.** Hundreds of recipes for widely-used libraries (OpenSSL,
  Boost, Qt, FFmpeg, and many more), tested across a broad compiler and OS
  matrix, available with a `self.requires()` line.
- **Binary caching.** Compiled dependencies are reused across builds, Python
  versions, and CI runs — rebuilt only when settings actually change.
- **Profiles and lockfiles.** The same Conan profiles your team uses for C/C++
  work apply to the wheel build. Lockfiles pin exact versions and revisions of
  every transitive dependency so developer and CI builds use the same graph.
- **Shared library handling.** Runtime dependencies from Conan are deployed next
  to the extension module and RPATH-patched on Linux and macOS. Not a
  replacement for `auditwheel`/`delocate` when you need full manylinux auditing,
  but it covers the common "imports locally, crashes elsewhere" case without an
  extra repair step.

## More Examples

The [examples/](https://github.com/conan-io/conan-py-build/tree/main/examples)
directory has complete, working projects covering a range of scenarios: Meson as
the build system, nanobind bindings, shared library dependencies, C++ sources
fetched at build time via `source()`, and a full multi-platform
[cibuildwheel](https://github.com/conan-io/conan-py-build/tree/main/examples/cibw-example)
setup for Linux, macOS, and Windows. If you are targeting multiple platforms,
that last one is particularly worth reading.

## Project Status and Call for Feedback

`conan-py-build` is currently in **beta**, available on
[PyPI](https://pypi.org/project/conan-py-build/) and tested on Linux, macOS,
and Windows. Some workflows (editable installs, complex multi-extension layouts,
fuller manylinux repair) are still being worked on, and there are almost
certainly cases we have not seen yet.

We are releasing now to get feedback from real projects. If something does not
work as expected, or there is a workflow you wish were supported, please open
an issue on
[GitHub](https://github.com/conan-io/conan-py-build/issues).

## Conclusions

`conan-py-build` pulls the C/C++ dependency layer inside the PEP 517 build so
the Python build and the C/C++ build are one problem, not two. If you have been
maintaining a separate dependency step alongside your Python packaging, it is
worth a look.

Check out the [documentation](https://conan-py-build.conan.io), browse the
[examples](https://github.com/conan-io/conan-py-build/tree/main/examples), and
let us know where it fits — or where it does not yet.

Happy coding!
