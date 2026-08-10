---
layout: post
comments: false
title: "Calling Conan-Managed C and C++ Libraries Directly from Swift"
description: "A Swift app calls two unmodified ConanCenter packages, LunaSVG and SDL, directly through Swift's C++ interoperability mode, with no hand-written C wrapper."
meta_title: "Swift C++ Interop with Conan-Managed Dependencies - Conan Blog"
categories: [cpp, conan, swift, macos, cmake]
---

Swift's C++ interoperability makes an appealing promise: import a C++ module and
call its APIs directly from Swift, without first building a C wrapper. But a
real C++ library is more than a header. It also brings compiled binaries,
transitive dependencies, build options, a C++ standard library, and ABI
constraints.

That is where Conan fits.

In this post, we will build a small Swift application with two unmodified
packages from ConanCenter:

- [LunaSVG](https://conan.io/center/recipes/lunasvg), a C++ SVG renderer.
- [SDL](https://conan.io/center/recipes/sdl), whose SDL3 C API creates the
  window and displays the rendered pixels.

The application generates an animated SVG scene in Swift, asks LunaSVG to
rasterize it into a Swift-owned pixel buffer, and uploads that buffer to an SDL
texture. Neither dependency knows anything about Swift, neither ships a Swift
module map, and there is no wrapper library between Swift and C++.

The complete example is available in the [Conan examples
repository](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop).

## Why This Example Is Interesting

A trivial interop sample can stop at a header-only function. This one crosses
most of the boundaries that matter in a real project:

- Conan resolves and, when necessary, builds two ordinary ConanCenter packages.
- CMake receives package configuration and imported targets from Conan.
- Small generated Clang module maps make the libraries importable by Swift.
- Swift calls C++ classes, static methods, constructors, and member functions
  directly.
- A C++ object writes into memory owned by a Swift `Array`.
- The resulting executable links the native libraries and their platform
  requirements.

The result is deliberately visual: a window with clouds drifting over a horizon.

## Build and Run It

The example currently targets macOS and requires the Xcode command-line tools,
CMake 3.28 or newer, and Ninja. We select Ninja explicitly because CMake's Swift
support does not work with the Unix Makefiles generator that some CMake versions
choose by default on macOS. C++ interoperability was introduced in Swift 5.9 and
has continued to evolve; use a recent Swift toolchain for the full set of
features exercised here, including importing the `std::unique_ptr` returned by
LunaSVG.

```bash
git clone https://github.com/conan-io/examples2.git
cd examples2/examples/languages/swift/cxx_interop

conan install . --build=missing \
  -c tools.cmake.cmaketoolchain:generator=Ninja
cmake --preset conan-release
cmake --build --preset conan-release
./build/Release/demo
```

`conan install` resolves the dependency graph and obtains binaries matching the
active Conan profile. If a suitable binary is unavailable, `--build=missing`
builds it from source. The generated CMake preset then carries that
configuration into the native build.

## What Swift's C++ Interoperability Does — and What It Does Not Do

Swift does not translate a C++ library's implementation into Swift. It imports
the declarations in the public C++ headers and emits calls that follow the
target C++ ABI. At link time, those calls are resolved against the already
compiled libraries supplied by Conan.

The Swift compiler embeds Clang, so it can parse the headers as a Clang module
and expose their declarations to Swift. Public C++ classes normally appear as
Swift value types; constructors become initializers, member functions become
methods, and namespaces remain available. The compiler then lowers those
operations to calls that follow the target C++ ABI, and the linker resolves
their symbols in the Conan package binaries. Compiler-generated adapters may
still be needed for particular language features, but there is no separately
maintained or compiled C wrapper library in this example.

This division of responsibilities is useful:

- Swift interoperability handles the language boundary.
- Conan handles the dependency and binary boundary.

A [Clang module map](https://clang.llvm.org/docs/Modules.html) only tells the
importer which headers form a module. It does not contain bindings, compile the
library, or make an arbitrary binary ABI-compatible. Conan still has to provide
the matching headers, libraries, transitive requirements, and build
configuration.

## Describing the Native Dependencies with Conan

The recipe starts like a conventional CMake-based Conan consumer:

```python
from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout


class SwiftCppDemo(ConanFile):
    settings = "os", "arch", "compiler", "build_type"

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        self.requires("lunasvg/3.5.0")
        self.requires("sdl/3.2.14")

    def generate(self):
        CMakeDeps(self).generate()
        CMakeToolchain(self).generate()
```

[`CMakeDeps`](https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html)
generates the package configuration consumed by `find_package()`.
[`CMakeToolchain`](https://docs.conan.io/2/reference/tools/cmake/cmaketoolchain.html)
translates the Conan configuration into CMake toolchain data and presets. That
part is independent of Swift: from Conan's perspective, this is a native
executable consuming two C and C++ dependencies.

## Generating the Missing Module Maps

Swift imports C and C++ headers as Clang modules. For that, it must be able to
find a `module.modulemap`. LunaSVG and SDL are regular C/C++ packages and do not
ship one for this use case, so the recipe generates two tiny shim module maps:

```python
import os

from conan.tools.files import save


def _write_modulemap(self, filename, module_name, header_path):
    content = (
        f'module {module_name} {{\n'
        f'    header "{header_path}"\n'
        '    export *\n'
        '}\n'
    )
    save(
        self,
        os.path.join(self.generators_folder, "shim", filename),
        content,
    )


def generate(self):
    CMakeDeps(self).generate()
    CMakeToolchain(self).generate()

    lunasvg_include = self.dependencies["lunasvg"].cpp_info.includedirs[0]
    self._write_modulemap(
        "lunasvg.modulemap",
        "LunaSVGMod",
        f"{lunasvg_include}/lunasvg/lunasvg.h",
    )

    sdl_include = (
        self.dependencies["sdl"]
        .cpp_info.components["sdl3"]
        .includedirs[0]
    )
    self._write_modulemap(
        "sdl3.modulemap",
        "SDL3Mod",
        f"{sdl_include}/SDL3/SDL.h",
    )
```

The generated files are intentionally simple. Conceptually, the LunaSVG one
contains only this:

```
module LunaSVGMod {
    header "/path/to/conan/package/include/lunasvg/lunasvg.h"
    export *
}
```

There are two details worth calling out.

First, the recipe takes header locations from each dependency's `cpp_info`
instead of guessing paths in the Conan cache. This works with the package layout
selected by Conan and also respects component metadata — in SDL's case, the
`sdl3` component.

Second, these are **Clang modules**, not the named modules introduced by C++20.
Swift's C++ importer currently consumes headers through Clang module maps; it
does not import C++20 modules directly.

In a library designed specifically for Swift consumption, a maintained module
map can live beside the public headers. Generating one in the consumer is a
pragmatic bridge for an existing, Swift-unaware package.

## Connecting Conan, CMake, and `swiftc`

The CMake project enables both Swift and C++ and consumes the targets generated
by Conan:

```cmake
cmake_minimum_required(VERSION 3.28)
project(swift_cpp_demo LANGUAGES CXX Swift)

find_package(lunasvg REQUIRED)
find_package(SDL3 REQUIRED)

add_executable(demo main.swift)

target_link_libraries(demo PRIVATE
  lunasvg::lunasvg
  sdl::sdl
)
```

Those imported targets are important. They carry much more than a library
filename: include paths, transitive link requirements, and other usage
information modeled by the packages.

The Swift-specific part enables C++ interoperability and forwards the module
maps to the Clang instance embedded in the Swift compiler:

```cmake
get_filename_component(
  _conan_generators_dir
  "${CMAKE_TOOLCHAIN_FILE}"
  DIRECTORY
)

target_compile_options(demo PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -std=c++17>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -fmodule-map-file=${_conan_generators_dir}/shim/lunasvg.modulemap>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -fmodule-map-file=${_conan_generators_dir}/shim/sdl3.modulemap>"
)
```

`-cxx-interoperability-mode=default` switches on C++ importing. Each `-Xcc`
forwards the following argument to embedded Clang, in this case selecting C++17
and loading a module map. CMake generator expressions keep these flags attached
only to Swift compilation.

With those pieces in place, the module names from the generated maps become
ordinary Swift imports:

```swift
import LunaSVGMod
import SDL3Mod
```

### A Small macOS Linker Wrinkle

Real dependency graphs occasionally expose assumptions made by one compiler
driver that another driver does not share. SDL3 exports a raw
`-Wl,-weak_framework,CoreHaptics` option on macOS, but the `swiftc` driver
cannot parse that form. The example removes this single option from SDL's
imported target and adds the framework using arguments that `swiftc`
understands:

```cmake
get_target_property(_sdl3_link_opts SDL3::SDL3 INTERFACE_LINK_OPTIONS)
if(_sdl3_link_opts)
  list(FILTER _sdl3_link_opts EXCLUDE REGEX "weak_framework")
  set_target_properties(
    SDL3::SDL3
    PROPERTIES INTERFACE_LINK_OPTIONS "${_sdl3_link_opts}"
  )
endif()

target_link_options(
  demo PRIVATE
  "SHELL:-Xlinker -framework -Xlinker CoreHaptics"
)
```

This is not a Swift binding layer. It is a narrow adaptation between
linker-driver syntaxes, and a useful reminder that direct language
interoperability still sits inside a complete native toolchain.

## Calling an Unmodified C++ API from Swift

Once the module is visible, the LunaSVG calls are almost a transcription of the
C++ API:

```swift
let svg = sceneSVG(cloud1X: cloud1X, cloud2X: cloud2X)
let doc = lunasvg.Document.loadFromData(svg)

pixels.withUnsafeMutableBytes { storage in
    let address = storage.bindMemory(to: UInt8.self).baseAddress!
    var bitmap = lunasvg.Bitmap(
        address,
        winW,
        winH,
        Int32(stride)
    )
    bitmap.clear(0x00000000)
    doc.pointee.render(&bitmap, lunasvg.Matrix())
}
```

Several interoperability features appear in these few lines:

- The C++ `lunasvg` namespace is available directly in Swift.
- `Document::loadFromData` is imported as a static method. LunaSVG returns a
  `std::unique_ptr<Document>`, which Swift can dereference through `pointee`
  while the smart pointer retains ownership.
- The `Bitmap` C++ constructor is called directly.
- `Matrix()` constructs another C++ value in Swift.
- `render` invokes a C++ member function on the document.

Direct does not mean that every operation is zero-copy. Passing a Swift `String`
to an API that expects `std::string`, for example, can require a conversion and
an allocation. The useful property here is that the integration does not require
a hand-written C facade; normal costs implied by the two type systems still
apply.

The most interesting boundary is the pixel buffer. Swift owns `[UInt8]`, while
LunaSVG receives a pointer to its storage and renders into it.
`withUnsafeMutableBytes` scopes that pointer access: the pointer must not escape
the closure, and the array must not be resized while C++ is using its storage.

After rendering, the same bytes go to SDL:

```swift
pixels.withUnsafeBytes { storage in
    _ = SDL_UpdateTexture(
        texture,
        nil,
        storage.baseAddress,
        Int32(stride)
    )
}

_ = SDL_RenderClear(renderer)
_ = SDL_RenderTexture(renderer, texture, nil, nil)
_ = SDL_RenderPresent(renderer)
```

SDL exposes a C API, which Swift has long been able to import through Clang. The
C++ interoperability mode is needed for LunaSVG, while the module-map and
dependency-management pattern applies to both libraries. Using explicit types
such as `CFloat`, `Int32`, and `UInt8` also keeps the native widths visible at
the boundary.

LunaSVG is a static SVG renderer, so the sample regenerates the SVG text with
new cloud positions for each frame. That keeps the animation intentionally
simple and keeps the focus on the native interoperability path.

## Direct Calls Make ABI Compatibility More Important, Not Less

Avoiding a C wrapper removes boilerplate and an extra API surface, but it does
not create an ABI firewall. The generated Swift code calls the C++ ABI expected
by the imported declarations. The headers used during Swift compilation
therefore need to agree with the linked binaries on the details that affect that
ABI.

That includes:

- Target operating system, architecture, and deployment target.
- Compiler ABI and C++ standard-library choice.
- Debug/Release and other relevant build settings.
- Dependency versions and transitive dependencies.
- Preprocessor definitions or package options that change public declarations or
  layouts.

The Swift and C++ sides must also use the same C++ standard library. On Apple
platforms that normally means libc++. Conan profiles, package IDs, and
dependency metadata help keep these decisions explicit. `CMakeToolchain` carries
the selected build configuration into CMake, and `CMakeDeps` gives CMake targets
that describe how each package is meant to be consumed.

This is the deeper value of putting Conan underneath Swift/C++ interoperability:
the language feature lets Swift express the call, while the package manager
makes the native artifact behind that call reproducible.

Conan cannot infer every compatibility rule automatically. If a library has an
ABI-changing macro or option that its recipe does not model, the recipe still
needs to expose it correctly. Direct C++ interoperability rewards accurate
package metadata.

## Ownership and Safety Still Cross the Boundary

The syntax can look very Swift-like, but the semantics still come from both
languages. A few rules are especially important when moving beyond a demo:

- **C++ classes are generally imported as Swift value types.** Copies can run
  C++ copy constructors, and destruction runs C++ destructors. For large
  containers, an innocent-looking Swift copy or iteration can therefore have a
  real cost.
- **Pointers and views need explicit lifetime reasoning.** `withUnsafeBytes` and
  `withUnsafeMutableBytes` make the valid scope clear in this example, but Swift
  cannot prove that an arbitrary third-party function will not retain the
  pointer. The C++ API contract still matters.
- **Noncopyable ownership should remain visible.** A `std::unique_ptr` is not a
  shared reference. Keeping the owner alive while using `pointee` is part of the
  program's correctness.
- **C++ exceptions are not Swift errors.** Swift cannot catch a C++ exception. A
  production boundary should prevent exceptions from escaping C++ into Swift.
- **Interop supports a growing subset of C++.** Rvalue-reference APIs, some
  template patterns, and C++20 named modules still have limitations. Check the
  current [Swift C++ interoperability
  status](https://www.swift.org/documentation/cxx-interop/status/) when
  evaluating a library.

Swift 6.2 also added stricter memory-safety checking and new safe-interop
facilities for annotated C++ APIs. Those features can improve bounds and
lifetime checking when you control or can adapt the C++ interface, but they do
not retroactively make every raw-pointer API safe.

The sample keeps error handling short to make the interop mechanics visible.
Production code should additionally check the nullable results from window,
renderer, texture, and document creation and report the corresponding SDL or
parse errors.

## The Reusable Pattern

Although this demo renders moving clouds, the integration pattern is not
graphics-specific:

1. Declare the native libraries and relevant settings in Conan.
2. Let Conan select or build a compatible dependency graph.
3. Generate a Clang module map when a package does not provide one.
4. Link the Conan-generated CMake targets normally.
5. Enable Swift C++ interoperability and pass the module map to embedded Clang.
6. Treat ownership, lifetimes, error models, and ABI options as part of the API
   boundary.

That opens a large body of existing C and C++ libraries to Swift without
requiring each upstream project to publish a separate Swift wrapper. A
purpose-built wrapper can still be valuable when an API is unsafe,
exception-heavy, or awkward to import, but it is now an architectural choice
rather than an automatic prerequisite.

In short: Swift can speak to the C++ API, and Conan can make sure the right
native implementation is there to answer.

Try the [complete
example](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop),
then take a look at the official [Swift C++ interoperability
guide](https://www.swift.org/documentation/cxx-interop/) for the complete
mapping and safety rules. If you have questions or feedback, please open an
issue on [GitHub](https://github.com/conan-io/conan/issues).

Happy coding!

*This post was written with AI assistance and reviewed by humans.*
