---
layout: post
comments: false
title: "C++ Modules: The Packaging Story"
meta_title: "Experimenting with C++ Modules"
description: "Experimenting with C++ Modules from the package management and build system perspective"
---

## Introduction

For the longest time, textual inclusion of header files has been the way to share declarations across multiple translation units. Thus, the concept of a packaged library has always involved “include files”, as well as the binary library files themselves, and this is how libraries are packaged for development. In order to make calls to functions provided by a library, we must first include the header that declares the funcion, for example:

```c++
#include <fmt/core.h>

int main() {
  fmt::print("Hello, world!\n");
}
```

C++ 20 introduces Modules as a new way to share declarations (and definitions!) across multiple translation units. With modules, we would have something like this on the calling side:

```c++
import fmt;       // < ---- new!

int main() {
  fmt::print("Hello, world!\n");
}
```

Unlike the `#include` preprocessor directive, which simply performs textual inclusion of the referenced file, the `import` keyword is a C++ language feature which behaves differently. Modules have advantages over legacy headers, by providing better isolation: 
- Importers can only see entities that are explicitly exported
- Importers cannot affect the code being imported
- The imported code cannot affect the state of the preprocessor in the importing code
- Import order does not matter, and importing “twice” does not require special care

With modules, we could avoid issues such as headers [defining commonly named identifiers as macro functions](https://stackoverflow.com/questions/13416418/define-nominmax-using-stdmin-max), [rogue “using namespace” directives in header files](https://stackoverflow.com/questions/5849457/using-namespace-in-c-headers) and we could finally put the recurrent [#pragma once vs include guards](https://stackoverflow.com/questions/1143936/pragma-once-vs-include-guards) debate to rest.


## Binary Module Interfaces

Let’s assume we have a library that already supports C++ modules - what are the packaging considerations? In order to answer this question, we should first have a look at how the compiler resolves an import in the first place by trying to compile the "Hello, World!" example above:

```bash
clang++ -std=c++20 -o hello_world.cpp.o -c hello_world.cpp   
hello_world.cpp:1:8: fatal error: module 'fmt' not found
import fmt;
~~~~~~~^~~
1 error generated.
```

In order to resolve `import fmt`, the compiler needs to locate the binary module interface (BMI) for the module named `fmt`. BMIs are files that are generated _in addition_ to object files, and encodes the information for the exported declarations. For clang, we need to tell the compiler where this file is for this named module, in this case with the `-fmodule-file=fmt=/path/to/fmt.pcm` flag. Note that there are other flags and mechanisms for the compiler to locate modules, and these vary per compiler (see [GCC](https://gcc.gnu.org/onlinedocs/gcc/C_002b_002b-Module-Mapper.html), [msvc](https://devblogs.microsoft.com/cppblog/using-cpp-modules-in-msvc-from-the-command-line-part-1/)). For illustration purposes, an example of a module interface could be:

`fmt.cc` (illustration only!):
```c++
export module fmt;

export namespace fmt { 
   void print(const char*);
}
```

Here’s where the workflow differs significantly from good old header files:

* The binary module interfaces need to be generated (from the module interface units, in this case `fmt.cc`), ahead of the compilation of any importers. This introduces dependencies between C++ sources involved with modules.
* BMIs are not compatible across compilers (they are implementation specific) and are also not expected to be compatible across different versions of the same compiler. Inconsistent compiler flags can also render a BMI invalid for the importer - that is, if the importer is being compiled with different (potentially incompatible) flags than when the BMI was first generated.

Solving the first problem (correct compilation order), has required giving the compilers the ability to scan source files for module dependencies and expressing them in a json file (see [p1689r5](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p1689r5.html)). This information can then be used by the build system to derive the correct build order. CMake started experimenting with this [earlier this year](https://www.kitware.com/import-cmake-c20-modules/) with version 3.25, and the feature will be available in the [upcoming 3.28 release](https://www.kitware.com/cmake-3-28-0-rc1-is-ready-for-testing/).

For the second problem, keep reading below!

## Experimenting with packaged module libraries

With traditional libraries with header files, we know that the compiler needs to find the directory that contains the included files - either implicitly (by placing the header files in locations the compiler already searches), or explicitly (via `-I` flags). These days, build system abstractions around the usage of libraries mean that developers don’t have to manually pass these to the compiler. For example, Conan models the [package information for consumers](https://docs.conan.io/2/reference/conanfile/attributes.html?highlight=cpp_info#package-information-for-consumers) in the `package_info()` method. For C++ in particular, this is captured in the [`cpp_info`](https://docs.conan.io/2/reference/conanfile/methods/package_info.html#conan-conanfile-model-cppinfo) attribute. Conan then uses this information when generating the specific build system integrations.

Note: the code for these experiments is available [on GitHub](https://github.com/jcar87/cxx-module-packaging).

### Packaging the BMIs (don't do it!)

While compiler documentation around C++ modules specify that BMIs are only compatible for the same compiler, compiler version and flags - we could take advantage of the Conan binary package model and package the BMIs alongside the binary libraries. 

For compilers like Clang and msvc that allow passing flags to specify the location of the BMIs for specific named modules, we can rely on existing abstractions to propagate this information to the consumer, for example - in the `package_info()` method of a Conan recipe (full recipe [here](https://github.com/jcar87/cxx-module-packaging/blob/main/experiments/02-bmi-packaging/fmt-recipe/conanfile.py)):

```python
if is_msvc(self):
    bmi_dir = os.path.join(self.package_folder, "bmi").replace('\\','/')
    self.cpp_info.cxxflags = ["/reference fmt=fmt.cc.ifc", f"/ifcSearchDir{bmi_dir}"]
elif self.settings.compiler == "clang":
    self.cpp_info.cxxflags = [f"-fmodule-file=fmt={self.package_folder}/bmi/fmt.pcm"]
```

While the package contents are roughly like this (for Clang on Linux):
```
|-- bmi
|   `-- fmt.pcm
`-- lib
    `-- libfmt.a
```

For this to work - we would need to use Conan in a way that enforces strict compatibility. A package like the above would _only_ be compatible with that specific compiler and version. Rougly, this means ensuring that for Conan, a package compiled with GCC 13.1 is different and _not compatible_ with one compiled with GCC 13.2, and that a package built with C++20 is different and _not compatible_ with one built with C++ 23. In order to do this, we would have to:
* Ensure the `compiler.version` setting specifies the exact version of the compiler, and not just the major version. For `msvc`, this also needs the `compiler.update` setting (see [docs](https://docs.conan.io/2/reference/config_files/settings.html#compilers)).

* Disable the default logic shipped with Conan 2.0 for the `compatibility` plugin, which encodes the behaviour for considering other binary packages as compatible candidates ([docs](https://docs.conan.io/2/reference/extensions/binary_compatibility.html) here). 

Does this work? Well, yes! But there are scenarios where it didn't work:
* For a library such as {fmt} that is built with `-fvisibility=hidden`, Clang rejects a BMI when the importer does not have this flag enabled and is using the default visibility.
* Clang will reject BMIs where the original source file does not exist in the local filesystem - this would make it impossible to build packages on one machine (e.g. CI) and consume it on another. For a lot of our users, this is a deal breaker. Strictly speaking, the importer only needs a BMI and not the original sources. But we need to take into account that the source files are still referenced by the compiler when reporting errors.
* GCC does not currently support compiler flags to specify where the BMIs are for specific modules, but rather, it supports a global module mapper. While we could create this with Conan, we would still need to cooperate with the build system on the consumer side. 

On the other hand, msvc appeard to be more forgiving and reusing the repackaged BMI appeared to work just fine in the scenarios we tested. 

While this approach may be useful for teams that have a strict and total control of their dependencies, the exact compiler and compiler version used (in all environments!) - packaging BMIs is not something that we would recommend in order to use modules.

### Packaging the module interfaces

From the above experiment, it is clear that we would need to package the module interface alongside the library binaries. From the packaging perspective, this isn’t too dissimilar from packaging a header file: it’s still text files with C++ source code. 

We would go from this:
```
|-- include/foo
|   `-- foo.hpp          ---> this is a header file
`-- lib
    `-- libfoo.a
```

to the following:
```
`-- lib
    |-- cxx
    |   `-- foo.cppm     ---> this is a module interface (does `export module foo`)
    `-- libfoo.a
```

However, this changes everything on the consumer side. If we have a project that imports modules from external libraries, we now need full cooperation from our build system: it needs to be aware of the module interfaces, and the compiler needs to be invoked at the right time in order to produce the BMIs before the importers require them.

Support for C++ modules in `IMPORTED` targets has been implemented in the upcoming CMake 3.28 release - you can see an experiment [here](https://github.com/jcar87/cxx-module-packaging/blob/main/experiments/03-imported-targets/) where this is working using CMake's generated `fmt-config.cmake` and `fmt-targets.cmake`. 

CMake now includes this information if an exported target also has modules:

```cmake
add_library(fmt::fmt SHARED IMPORTED)

# ... 

target_sources(fmt::fmt
  INTERFACE
  FILE_SET "fmt_module"
  TYPE "CXX_MODULES"
  BASE_DIRS "${_IMPORT_PREFIX}/lib/cxx/miu"
  FILES "${_IMPORT_PREFIX}/lib/cxx/miu/src/fmt.cc"
)

```

So far, CMake 3.28 (still a Release Candidate at time of writing) is the only build system that implements dependency scanning and the ability to consume external libraries that provide modules, and the BMIs are built locally rather than distributed. A fairly modern setup is required as well! The compilers must support p1689r5 (Clang >= 16.0, msvc from the 14.34 toolset, and the yet-to-be-released gcc 14), as well as the build tool (Ninja 1.11.1 or MSBuild). All very bleeding edge!

## What's next

We're currently working on updating the `cpp_info` attribute to acommodate information pertaining to C++ modules, so that the Conan generators can include this for build systems with C++ Module support. In the case described here, this means CMake 3.28 initially. In the future, C++ module information will need to be expanded to inform the consumer which build flags or macro definitions should be used when producing the BMI. But today, hopefully this is useful to users who are currently eager to try out C++ modules, as more libraries start supporting them (see [here](https://github.com/jcar87/cxx-module-packaging/tree/main#c-libraries-with-module-support) for a list). This should only help and drive adoption!

## Resources

* "C++20 Modules: The Packaging and Binary Redistribution Story" (Cppcon 2023 [slides](https://github.com/jcar87/cxx-module-packaging/blob/main/cppcon-talk/modules-the-packaging-and-binary-redistribution-story.pdf))
* Packaging libraries with C++ modules (experiments) - [GitHub repository](https://github.com/jcar87/cxx-module-packaging/tree/main)