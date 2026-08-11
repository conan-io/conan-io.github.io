---
layout: post
comments: false
title: "Calling a C++ Library Directly from Swift"
description: "Swift can call supported C++ APIs without a hand-written wrapper. We use Conan to supply an ordinary LunaSVG package and connect its headers, binary, and build settings to Swift."
meta_title: "Calling a C++ Library Directly from Swift with Conan - Conan Blog"
categories: [cpp, conan, swift, macos, cmake]
---

Swift has been able to import C and Objective-C APIs since its early releases.
C++ was more difficult to support because Swift's C importer could not represent
features such as namespaces, overloaded functions, templates, constructors,
destructors, and standard-library types. Calling a C++ library from Swift
therefore usually meant putting a C facade or an Objective-C++ wrapper in front
of it.

[Swift 5.9](https://www.swift.org/blog/swift-5.9-released/) changed that by
introducing direct C++ interoperability, allowing Swift to import C++ headers
and call supported C++ APIs without first exposing them through a C facade or an
Objective-C++ wrapper.

To try this with an existing package, we use
[LunaSVG](https://conan.io/center/recipes/lunasvg), a C++ SVG renderer from
ConanCenter. The application creates an SVG scene in Swift and asks LunaSVG to
render it with two different styles.

Swift knows how to call supported C++ APIs, while Conan provides LunaSVG, its
transitive dependencies, and the information needed to compile and link the
application. A small Clang module map makes LunaSVG's headers importable from
Swift.

The complete project is available in the [Conan examples
repository](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop):

```text
cxx_interop/
├── conanfile.py
├── CMakeLists.txt
├── main.swift
├── ci_test_example.py
└── README.md
```

## Starting with the C++ API

Before looking at Swift, it helps to see how the LunaSVG API would normally be
used from C++. Given `svg` and `css` as `std::string` values holding an SVG
document and a stylesheet, and `output` as the destination PNG path, rendering
and writing the file looks like this:

```cpp
auto document = lunasvg::Document::loadFromData(svg);
document->applyStyleSheet(css);

auto bitmap = document->renderToBitmap();
bitmap.writeToPng(output);
```

Although short, this fragment already touches several C++ features: a
namespace, a static method, a `std::unique_ptr<Document>`, member functions,
and a `Bitmap` returned by value.

## Making the C++ API Visible to Swift

Before Swift can call this API, it needs to know which C++ header to import and
the module name it should use. Swift gets this information through a Clang
module map.

```text
module LunaSVGMod {
    header "/path/to/include/lunasvg/lunasvg.h"
    export *
}
```

This gives the LunaSVG header a module name, `LunaSVGMod`. The build must also
enable C++ interoperability and pass the module map to the Clang importer used
by the Swift compiler. Once that is configured, Swift can import the module and
use the supported declarations from the header.

<div markdown="1" style="border-left: 3px solid #e0e0e0; padding: 0.4em 1em; color: #555; font-size: 0.95em; margin: 1.5em 0;">
<strong>Note:</strong> Despite the similar terminology, this is a [Clang
module](https://clang.llvm.org/docs/Modules.html), not a named C++20 module.
Swift does not currently import C++20 modules.
</div>

## Calling the Same API from Swift

With the C++ standard library and `LunaSVGMod` imported, `main.swift` calls the
same API to render the demo scene once per season:

```swift
import CxxStdlib
import LunaSVGMod

for season in seasons {
    let document = lunasvg.Document.loadFromData(std.string(svg))
    document.pointee.applyStyleSheet(std.string(season.css))

    let bitmap = document.pointee.renderToBitmap()
    _ = bitmap.writeToPng(std.string("\(season.name).png"))
}
```

`svg` holds the SVG markup and `seasons` pairs each season name with its
stylesheet; both are ordinary Swift values defined earlier in `main.swift`. The
loop body closely follows the C++ version above.

The mapping is visible in the code:

- The C++ namespace `lunasvg` remains visible in Swift.
- `Document::loadFromData` becomes a static method.
- The returned `std::unique_ptr<Document>` owns the C++ object; Swift accesses
  that object through `pointee`.
- `renderToBitmap` returns a C++ `Bitmap` by value.
- `writeToPng` remains an ordinary member-function call.

The `std.string(...)` conversions are explicit for a reason. Swift does not
automatically bridge a dynamic Swift `String` to C++ `std::string`. `CxxStdlib`
exposes supported standard-library types, but creating these C++ strings still
allocates and copies data. Direct interop removes the wrapper; it does not make
every conversion free.

Running the loop with the summer and winter styles produces the following
LunaSVG output:

<div style="display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
  <img src="/assets/post_images/2026-08-12/summer.png" alt="summer.png: LunaSVG rendering of the demo scene with the summer stylesheet applied" width="45%"/>
  <img src="/assets/post_images/2026-08-12/winter.png" alt="winter.png: the same SVG document rendered again with the winter stylesheet applied" width="45%"/>
</div>

## What "Direct" Means

Swift does not translate LunaSVG into Swift, and this project does not compile a
hand-written C wrapper. Instead, the path looks like this:

```text
C++ headers -> Clang module -> declarations visible to Swift
Swift calls  -> platform C++ ABI -> compiled LunaSVG library
```

The Swift compiler uses Clang to parse LunaSVG's public headers and imports the
supported declarations into Swift. It then emits native calls that follow the
target's C++ ABI, and the linker resolves those calls against the library
provided by Conan.

This is why the header is only half of the dependency. Swift also needs a binary
built for a compatible target, C++ standard library, ABI, and set of options. A
module map makes headers importable; it does not make an arbitrary binary
compatible.

Pure C libraries follow the same broad dependency pattern: Conan can provide
their headers and binaries, and a Clang module map can expose the headers to
Swift. The difference is that Swift imports C by default, so a C library does
not need C++ interoperability mode or the additional C++ ABI constraints
discussed here. That is also why C facades were historically the common route
from Swift to C++.

## Generating the Module Map with Conan

The module map shown above contains a package-specific include path. Rather
than hard-coding that path, the Conan consumer recipe obtains it from the
selected LunaSVG package and generates the file during `conan install`:

```python
import os

from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import save


class SwiftCppDemo(ConanFile):
    settings = "os", "arch", "compiler", "build_type"

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        self.requires("lunasvg/3.5.0")

    def generate(self):
        CMakeDeps(self).generate()
        CMakeToolchain(self).generate()

        include_dir = self.dependencies["lunasvg"].cpp_info.includedirs[0]
        header = f"{include_dir}/lunasvg/lunasvg.h"
        module_map = (
            "module LunaSVGMod {\n"
            f'    header "{header}"\n'
            "    export *\n"
            "}\n"
        )
        save(
            self,
            os.path.join(
                self.generators_folder,
                "shim",
                "lunasvg.modulemap",
            ),
            module_map,
        )
```

The recipe gets the include directory from LunaSVG's `cpp_info` instead of
guessing a path inside the Conan cache. This keeps the shim tied to the package
Conan actually selected.

## Connecting Conan, CMake, and `swiftc`

The CMake project links the Conan target as it would for a C++ executable, then
adds three Swift-specific compiler options:

```cmake
cmake_minimum_required(VERSION 3.28)
project(swift_cpp_demo LANGUAGES CXX Swift)

find_package(lunasvg REQUIRED)

add_executable(demo main.swift)
target_link_libraries(demo PRIVATE lunasvg::lunasvg)

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

Each piece has one job:

- `lunasvg::lunasvg`, generated by `CMakeDeps`, carries the native link and
  usage requirements modeled by the Conan package.
- `-cxx-interoperability-mode=default` enables C++ imports in Swift.
- `-Xcc` forwards the C++ language mode and module-map path to the embedded
  Clang compiler.

`CMakeToolchain` derives `CMAKE_CXX_STANDARD` from the consumer profile's
`compiler.cppstd`. Forwarding it to Clang keeps the imported headers in the same
requested language mode. That matters for libraries whose public declarations
change according to `__cplusplus`.

## Build and Run

The example currently targets macOS. It requires the Xcode command-line tools,
CMake 3.28 or newer, and Ninja. CMake supports Swift with its Ninja and Xcode
generators; this example selects Ninja explicitly through the Conan toolchain.

Use a recent Swift toolchain. C++ interoperability began in Swift 5.9, but that
initial release is not sufficient for this exact example: support for the
`std::unique_ptr` returned by LunaSVG was added later.

```bash
git clone https://github.com/conan-io/examples2.git
cd examples2/examples/languages/swift/cxx_interop

conan install . --build=missing \
  -c tools.cmake.cmaketoolchain:generator=Ninja
cmake --preset conan-release
cmake --build --preset conan-release
./build/Release/demo
```

`conan install` resolves LunaSVG and selects a package matching the active
profile. If no suitable binary is available, `--build=missing` builds one from
source. Running the executable writes `summer.png` and `winter.png` to the
working directory.

The same integration model can be used on other Swift platforms, but the exact
supported C++ surface still varies. For example, the current Swift status page
lists `std::shared_ptr` and `std::unique_ptr` as unsupported on Windows.

## What Direct Interoperability Does Not Solve

The Swift syntax is pleasantly ordinary, but direct interop is neither a stable
C ABI nor an automatic safety boundary.

### Headers and binary must agree

The headers parsed by Swift and the linked library must agree on every choice
that affects the C++ ABI, including:

- Target platform, architecture, and deployment target.
- Compiler ABI and C++ standard-library implementation.
- Dependency versions and transitive libraries.
- Defines or package options that change public declarations or object layout.

Conan profiles, package IDs, and dependency metadata make these choices explicit
and let Conan select or build a compatible artifact. They cannot fix an
ABI-changing option that a package recipe fails to model, so accurate package
metadata still matters.

### Ownership does not disappear

C++ classes are generally imported as Swift value types. Copying one can invoke
its C++ copy constructor, and destroying it invokes its C++ destructor. A
`std::unique_ptr` remains a unique owner, so it must stay alive while Swift uses
`pointee`.

Raw pointers, references, and view types require the same lifetime reasoning as
they do in C++. Swift 6.2 introduced experimental safe-interoperability features
that can improve this for annotated APIs, but they do not make every existing
pointer API safe automatically.

C++ exceptions are another important boundary: Swift cannot catch them. An
exception that escapes C++ into Swift terminates the program, so a production
API should catch and translate errors on the C++ side.

Finally, interoperability still covers a growing subset of C++, not every
possible header. Some template patterns and standard-library types remain
unsupported. Check the current [Swift C++ interoperability status
page](https://www.swift.org/documentation/cxx-interop/status/) when evaluating a
library.

The sample also keeps error handling short to make the interop visible.
Production code should verify that `loadFromData` did not return a null pointer
before dereferencing it and should check the result of `writeToPng`.

## When a Wrapper Is Still the Better Boundary

Direct interoperability removes boilerplate, but it does not make wrappers
obsolete. A small C or C++ adapter can still be the better design when the
upstream API:

- exposes unsupported C++ constructs;
- relies heavily on exceptions, raw pointers, or ambiguous lifetimes;
- has a large template-heavy surface that should not leak into the Swift code;
  or
- needs to be isolated behind a narrower, more stable ABI.

The difference is that a wrapper is now an architectural choice for shaping the
boundary, rather than an automatic prerequisite for calling any C++ code.

## A Reusable Pattern

The LunaSVG example reduces to five steps:

1. Let Conan select or build the native dependency for the active profile.
2. Describe the public headers with a Clang module map when upstream does not
   provide one.
3. Link the Conan-generated CMake target normally.
4. Enable Swift C++ interoperability and give embedded Clang the same header
   configuration.
5. Treat ABI, ownership, lifetime, and errors as part of the API boundary.

Swift now makes the direct C++ call possible. Conan handles the less visible but
equally important part: making sure there is a suitable native artifact behind
that call.

Try the [complete
example](https://github.com/conan-io/examples2/tree/main/examples/languages/swift/cxx_interop)
and consult the official [Swift C++ interoperability
guide](https://www.swift.org/documentation/cxx-interop/) for the complete
mapping and safety rules.

Happy coding!

*This post was written with AI assistance and reviewed by humans.*
