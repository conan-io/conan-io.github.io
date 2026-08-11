---
layout: post
comments: false
title: "Calling a Conan-Managed C++ Library Directly from Swift"
description: "A Swift app calls an unmodified C++ ConanCenter package, LunaSVG, directly through Swift's native C++ interoperability, with no hand-written wrapper."
meta_title: "Swift C++ Interop with a Conan-Managed Dependency - Conan Blog"
categories: [cpp, conan, swift, macos, cmake]
---

Swift's C++ interoperability makes an appealing promise: import a C++ library
through a Clang module and call its APIs directly from Swift, without first
building a C wrapper. But a real C++ library is more than a header. It also
brings compiled binaries, transitive dependencies, build options, a C++ standard
library, and ABI constraints.

That is where Conan fits.

## From C Interoperability to C++ Interoperability

Swift's native interoperability story started with C and Objective-C. Those APIs
are imported through Clang by default: functions, structures, enumerations, and
pointers declared in headers become declarations that Swift can call, while the
implementation remains in the original native library. That made C the usual
common denominator for exposing an existing native library to Swift.

C++ was a harder boundary. Namespaces, overloaded functions, templates,
constructors and destructors, value semantics, the C++ standard library, and
platform-specific ABI rules all have to be represented correctly. Before
supported C++ interoperability arrived in [Swift
5.9](https://www.swift.org/blog/swift-5.9-released/), the usual approach was to
put a C facade or an Objective-C++ wrapper in front of a C++ library. That
works, but it also creates another API surface to design, build, and maintain.

Swift 5.9 introduced bidirectional C++ interoperability for a useful subset of
the language. [Swift 6](https://www.swift.org/blog/announcing-swift-6/) expanded
it with move-only C++ types, virtual methods, default arguments, and more
standard-library types. [Swift
6.2](https://www.swift.org/blog/swift-6.2-released/) then added opt-in safety
facilities for pointers and view types. The feature continues to evolve, but a
large class of libraries can now be consumed without first reducing their API to
C.

This example exercises that C++ path end to end: LunaSVG exposes C++ classes,
returns a `std::unique_ptr`, and is called from Swift without ever reducing its
API to C.

In this post, we will build a small Swift application around one unmodified
package from ConanCenter:

- [LunaSVG](https://conan.io/center/recipes/lunasvg), a C++ SVG renderer.

The application builds an SVG scene as a Swift string, hands it to LunaSVG to
parse and rasterize under two different CSS stylesheets, and writes each result
to a PNG file. LunaSVG knows nothing about Swift, ships no Swift module map, and
there is no wrapper library between Swift and the library.

The complete example is available in the [Conan examples
repository](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop).

## Why This Example Is Interesting

A trivial interop sample can stop at a header-only function. This one crosses
most of the boundaries that matter in a real project:

- Conan resolves and, when necessary, builds an ordinary ConanCenter package.
- CMake receives package configuration and an imported target from Conan.
- A small generated Clang module map makes the library importable by Swift.
- Swift calls a C++ namespace, a static method, and instance methods directly.
- A C++ static method returns a `std::unique_ptr`, and a C++ method returns a
  value type by value.
- The resulting executable links the native library and writes real output
  files.

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
configuration into the native build. Running the binary writes `summer.png` and
`winter.png` to the working directory.

## What Swift's C++ Interoperability Does — and What It Does Not Do

Swift does not translate a C++ library's implementation into Swift. It imports
the declarations in the public C++ headers and emits calls that follow the
target C++ ABI. At link time, those calls are resolved against the already
compiled library supplied by Conan.

As the [Swift documentation](https://www.swift.org/documentation/cxx-interop/)
puts it: "The Swift compiler embeds the Clang compiler. This allows Swift to
import C++ header files using Clang modules." Public C++ classes normally appear
as Swift value types; constructors become initializers, member functions become
methods, and namespaces remain available. The compiler then lowers those
operations to calls that follow the target C++ ABI, and the linker resolves
their symbols in the Conan package binary. Compiler-generated adapters may still
be needed for particular language features, but there is no separately
maintained or compiled C wrapper library in this example.

This division of responsibilities is useful:

- Swift interoperability handles the language boundary.
- Conan handles the dependency and binary boundary.

A [Clang module map](https://clang.llvm.org/docs/Modules.html) only tells the
importer which headers form a module. It does not contain bindings, compile the
library, or make an arbitrary binary ABI-compatible. Conan still has to provide
the matching headers, library, transitive requirements, and build configuration.

## Describing the Native Dependency with Conan

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

    def generate(self):
        CMakeDeps(self).generate()
        CMakeToolchain(self).generate()
```

[`CMakeDeps`](https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html)
generates the package configuration consumed by `find_package()`.
[`CMakeToolchain`](https://docs.conan.io/2/reference/tools/cmake/cmaketoolchain.html)
translates the Conan configuration into CMake toolchain data and presets. That
part is independent of Swift: from Conan's perspective, this is a native
executable consuming a single C++ dependency.

## Generating the Missing Module Map

Swift imports C and C++ headers as Clang modules. For that, it must be able to
find a `module.modulemap`. LunaSVG is a regular C++ package and does not ship
one for this use case, so the recipe generates a tiny shim module map:

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
```

The generated file is intentionally simple. Conceptually, it contains only this:

```
module LunaSVGMod {
    header "/path/to/conan/package/include/lunasvg/lunasvg.h"
    export *
}
```

There are two details worth calling out.

First, the recipe takes the header location from LunaSVG's `cpp_info` instead of
guessing a path in the Conan cache. This works with whatever package layout
Conan selects, and the same call would work for a package that exposes its
headers through Conan components instead of a single `includedirs` entry.

Second, this is a **Clang module**, not the named modules introduced by C++20.
As the same documentation states plainly: "Swift currently cannot import C++
modules introduced in the C++20 language standard."

In a library designed specifically for Swift consumption, a maintained module
map can live beside the public headers. Generating one in the consumer is a
pragmatic bridge for an existing, Swift-unaware package.

## Connecting Conan, CMake, and `swiftc`

The CMake project enables both Swift and C++ and consumes the target generated
by Conan:

```cmake
cmake_minimum_required(VERSION 3.28)
project(swift_cpp_demo LANGUAGES CXX Swift)

find_package(lunasvg REQUIRED)

add_executable(demo main.swift)

target_link_libraries(demo PRIVATE
  lunasvg::lunasvg
)
```

That imported target is important. It carries much more than a library filename:
include paths, transitive link requirements, and other usage information modeled
by the package.

The Swift-specific part enables C++ interoperability and forwards the module map
to the Clang instance embedded in the Swift compiler:

```cmake
get_filename_component(
  _conan_generators_dir
  "${CMAKE_TOOLCHAIN_FILE}"
  DIRECTORY
)

target_compile_options(demo PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -std=c++${CMAKE_CXX_STANDARD}>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -fmodule-map-file=${_conan_generators_dir}/shim/lunasvg.modulemap>"
)
```

`-cxx-interoperability-mode=default` switches on C++ importing. `-Xcc` forwards
the following argument to embedded Clang. `CMAKE_CXX_STANDARD` is not
hardcoded here — `CMakeToolchain` already sets it from the active profile's
`compiler.cppstd` when it generates `conan_toolchain.cmake`, the same setting
that determined which C++ dialect lunasvg itself was built with. Reading it
back is a one-line habit, not a fix for an active bug in this particular
library: LunaSVG's header has no code conditioned on the active C++ standard,
so a hardcoded `c++17` would behave identically here. But some libraries do
gate declarations behind `#if __cplusplus` — GCC's libstdc++ famously did this
for years with its ["dual
ABI"](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) for
`std::string`, and modern libraries such as Abseil still gate parts of their
public API on the active standard. For those, letting this value silently
drift from what Conan resolved is how you get a linker error, or worse, a
mismatched layout that never surfaces as one. CMake generator expressions keep
the resulting flags attached only to Swift compilation.

With those pieces in place, the module name from the generated map becomes an
ordinary Swift import, alongside `CxxStdlib`, the overlay module Swift provides
for bridging C++ standard-library types such as `std::string`:

```swift
import CxxStdlib
import LunaSVGMod
```

## Calling an Unmodified C++ API from Swift

Once the module is visible, the LunaSVG calls are close to a transcription of
the C++ API. The example renders the same SVG scene twice, once per season, by
loading a fresh `Document`, applying a different CSS stylesheet, and rendering
the result to a bitmap:

```swift
let seasons = [
    (name: "summer", css: ".sky{fill:#8ECBEB} .hills{fill:#8FA89B} .ground{fill:#8FC77E} .cloud{fill:#FFFFFF}"),
    (name: "winter", css: ".sky{fill:#C9D6E3} .hills{fill:#9FAFAF} .ground{fill:#F2F5F7} .cloud{fill:#E7EEF3}"),
]

for season in seasons {
    let document = lunasvg.Document.loadFromData(std.string(svg))
    document.pointee.applyStyleSheet(std.string(season.css))

    let bitmap = document.pointee.renderToBitmap()
    _ = bitmap.writeToPng(std.string("\(season.name).png"))

    print("Generated \(season.name).png")
}
```

A fresh `Document` is loaded for each season rather than reused, because
`applyStyleSheet` mutates the document it is called on; there is no way to undo
a stylesheet once applied.

Several interoperability features appear in these few lines:

- The C++ `lunasvg` namespace is available directly in Swift.
- `Document::loadFromData` is imported as a static method. LunaSVG returns a
  `std::unique_ptr<Document>`, which Swift dereferences through `pointee` while
  the smart pointer keeps ownership of the object.
- `applyStyleSheet` and `renderToBitmap` are called as ordinary instance methods
  on that dereferenced value.
- `renderToBitmap` returns a `Bitmap` by value — a C++ object constructed on the
  C++ side and handed back into Swift.
- `writeToPng` is a `const` C++ member function that writes to disk.

The `std.string(...)` calls are not decoration. As the [Swift
documentation](https://www.swift.org/documentation/cxx-interop/) states: "Swift
does not convert C++ `std::string` type to Swift's `String` type automatically."
Every Swift `String` crossing into an API that expects `std::string` — the SVG
markup, the CSS, the output filename — goes through an explicit
`std.string(...)` initializer from the `CxxStdlib` overlay module. That
conversion allocates and copies; it is not free, and it is not automatic, only
explicit and predictable.

## Direct Calls Make ABI Compatibility More Important, Not Less

Avoiding a C wrapper removes boilerplate and an extra API surface, but it does
not create an ABI firewall. The generated Swift code calls the C++ ABI expected
by the imported declarations. The headers used during Swift compilation
therefore need to agree with the linked binary on the details that affect that
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
that describe how the package is meant to be consumed.

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
- **Pointers and views still need explicit lifetime reasoning.** Even though
  this example only crosses a `std::unique_ptr`, many C++ APIs hand back raw
  pointers or views instead; Swift's `withUnsafeBytes` and
  `withUnsafeMutableBytes` scope such access explicitly, but Swift cannot prove
  that an arbitrary third-party function will not retain a pointer past that
  scope. The C++ API contract still matters.
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
Production code should additionally check `loadFromData`'s result for a null
pointer before dereferencing it through `pointee`, and check the boolean
returned by `writeToPng`.

## The Reusable Pattern

Although this demo renders a small illustrated landscape, the integration
pattern is not graphics-specific:

1. Declare the native library and relevant settings in Conan.
2. Let Conan select or build a compatible binary.
3. Generate a Clang module map when a package does not provide one.
4. Link the Conan-generated CMake target normally.
5. Enable Swift C++ interoperability and pass the module map to embedded Clang.
6. Treat ownership, lifetimes, error models, and ABI options as part of the API
   boundary.

Pure C libraries follow the same general dependency pattern: Conan provides the
headers and the binary, and a Clang module map makes the headers importable.
They do not, however, require C++ interoperability mode or the C++ ABI
guarantees described above — Swift has been able to import a plain C API through
Clang since long before C++ interoperability existed.

That opens a large body of existing C and C++ libraries to Swift without
requiring each upstream project to publish a separate Swift wrapper. A
purpose-built wrapper can still be valuable when an API is unsafe,
exception-heavy, or awkward to import, but it is now an architectural choice
rather than an automatic prerequisite.

Try the [complete
example](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop),
then take a look at the official [Swift C++ interoperability
guide](https://www.swift.org/documentation/cxx-interop/) for the complete
mapping and safety rules. If you have questions or feedback, please open an
issue on [GitHub](https://github.com/conan-io/conan/issues).

Happy coding!

*This post was written with AI assistance and reviewed by humans.*
