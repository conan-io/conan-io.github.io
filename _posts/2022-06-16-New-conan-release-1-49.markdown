---
layout: post
comments: false
title: "Conan 1.49: Removed Python2 support, improved CMakePresets, new [layout] section in conanfile.txt, new tools.apple.fix_apple_shared_install_name tool, new can_run() and check_min_vs helpers."
meta_title: "Version 1.49 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include removal of Python2 support, improved CMakePresets, new [layout] section in conanfile.txt and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.49 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.49 Conan C/C++ package manager version",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Conan Team", 
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan release", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
},
 "datePublished": "2022-06-16",
 "description": "Removed Python2 support, improved CMakePresets, new [layout] section in conanfile.txt, new tools.apple.fix_apple_shared_install_name tool, new "can_run()", "check_min_vs" helpers.",
 }
</script>

We are pleased to announce that [Conan 1.49 is
out](https://github.com/conan-io/conan/releases/tag/1.49.0) and comes with some
significant new features and bug fixes. First, it's worth menetioning that we finally
removed support for Python2 in Conan. Also, we made some improvements to the CMakePresets
support and now the layout can be parameterized by different settings and options. The
XcodeDeps generator now has components support. Now you can use layouts in the
conanfile.txt adding the [layout] section. We also added a new
tools.apple.fix_apple_shared_install_name tool, to fix packages that do not set the
correct `LC_ID_DYLIB` field for shared libraries. Finally, there are two new helpers
that can be used in recipes: `can_run()` and `check_min_vs`.

## Removed Python2 support

From version 1.49, Conan will not work with Python 2. This is because security
vulnerabilities of Conan dependencies that haven't been addressed in Python 2, so the only
alternative moving forward is to finally remove Python 2 suport.

Python 2 was officially declared End Of Life 2 years and a half now, and Conan 1.22
already declared Python 2 as not supported. Extra blockers have been added in previous
Conan releases to make everyone aware. Now the security vulnerabilities that are out of
our scope, makes impossible to move forward support for Python 2. Please upgrade to
Python>=3.6 to continue using Conan>=1.49. 

## New [layout] section in conanfile.txt

Until Conan 1.49 you could only use the layouts
[feature](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html) defining
the method in a *conanfile.py*. Conan 1.49 comes with basic support for layouts in the
*conanfile.txt* as well. You can now add a new [layou] section in your conanfile to add
one of the following pre-defined layouts:

- [cmake_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)
- [vs_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)
- [bazel_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)

In the case of the `cmake_layout`, this features enables that consumers that use
*conanfile.txt* can take advantage of the CMakePresets integration. Let's see an example
for a simple consumer project that builds a *compressor* application with the following
structure:

```txt
├── CMakeLists.txt
├── conanfile.txt
└── src
    └── compressor.c
```

Where the **conanfile.txt** declares the **cmake_layout**, requires
[zlib/1.2.11](https://conan.io/center/zlib) and uses the **CMakeDeps** and
**CMakeToolchain** generators:

```txt
[requires]
zlib/1.2.12

[generators]
CMakeDeps
CMakeToolchain

[layout]
cmake_layout
```

If you do a `conan install .`, you can see that the files are generated according the
default cmake_layout and the *CMakeUserPresets.json* is created in the base folder,
besides the *CMakeLists.txt*.

```txt
├── CMakeLists.txt
├── CMakeUserPresets.json
├── build
│   └── generators
│       ├── CMakePresets.json
│       ├── FindZLIB.cmake
│       ├── ...
│       └── module-ZLIBTargets.cmake
├── conanfile.txt
└── src
    └── compressor.c
```

Then you can invoke the presets calling CMake:

```txt
cmake --preset release
cmake --build --preset release      
```

The results of the build will end in the same folder as if we were using a *conanfile.py*
with the `cmake_layout` defined in the `layout()` method:

```txt
.
├── CMakeLists.txt
├── CMakeUserPresets.json
├── build
│   ├── Release
│   │   ├── CMakeCache.txt
│   │   ├── CMakeFiles
│   │   │   └── ...
│   │   ├── Makefile
│   │   ├── cmake_install.cmake
│   │   └── compressor
│   └── generators
│       ├── CMakePresets.json
│       ├── ...
│       └── module-ZLIBTargets.cmake
├── conanfile.txt
└── src
    └── compressor.c
```

You can check that the *compressor* application was built in the `/build/Release` folder as
expected.

## Improved CMakePresets with parameterized layout

Conan has incrementally improved the support for CMakePresets during the last releases.
Since Conan 1.49 you can use the new `tools.cmake.cmake_layout:build_folder_vars`
configuration to modify the
[cmake_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake_layout.html#cmake-layout)
default values for the `conanfile.folders.build` and `conanfile.folders.generators`
attributes and also the default presets names for CMakePresets. Let's begin from the
previous `[layout]` example to see how this works.

As you know, by default the name of the presets and output folders are named after the
`build_type` setting, so they are `Release` or `Debug` by default. Let's change that
default so that those folders and names for the presets take other settings into account,
like for example the `arch` setting. Do a conan install setting the
`tools.cmake.cmake_layout:build_folder_vars` configuration.


```txt
conan install . -c tools.cmake.cmake_layout:build_folder_vars='["settings.arch", "settings.build_type"]'
```

Now, if you list the available presets, you will see a new preset including the
architecture and the builds will output the files to the corresponding folder containing
the used archicture and build type in the name.

```txt
$ cmake --list-presets
Available configure presets:

  "x86_64-release-release" - 'x86_64-release-release' config
  "release"                - 'release' config
$ cmake --preset x86_64-release-release
...
$ cmake --build --preset x86_64-release-release
...
```

## New tools.apple.fix_apple_shared_install_name tool 

We have added the new tool `tools.apple.fix_apple_shared_install_name` to help users
address problems that can occur when using Apple's shared libraries. As we explained in
the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotools.html#a-note-about-relocatable-shared-libraries-in-macos-built-the-autotools-build-helper)
making relocatable shared libraries in Apple platforms requires an extra effort, because
it's typicall that  when these kind of libraries are built two sections called
`LC_ID_DYLIB` and `LC_LOAD_DYLIB` are added to the information embedded in the library.
These sections will usually point to an absolute shared library location in the
filesystem, and this will make the library load fail when it's loaded in a different
system without the library in that location. 

The best solution to avoid this problem is to pass the appropiate flags for the linker so
that the absolute folder is substituted with the `@rpath` value. The `@rpath` special
keyword will tell the loader to search a list of paths to find the library. These paths
can be defined by the consumer of that library by defining the `LC_RPATH` field, embedded
in the binary. But this is something that not all libraries do, so if you happen to need
packaging a library whose binaries are not relocatable, you have only two options, either
patching the libraries build scripts to make them relocatable, or fixing the binaries
after the build. 

The `tools.apple.fix_apple_shared_install_name` tool can help with the second option.
You would normally invoke this tool in the package() method of the recipe, right after
moving the binaries to the package folder.Let's see how to use it with an example of a
library that uses Autotools as the build system:

```python
from conan.tools.apple import fix_apple_shared_install_name

class HelloConan(ConanFile):

  ...

  def package(self):
      autotools = Autotools(self)
      autotools.install()
      fix_apple_shared_install_name(self)
```

This tool will search for all the shared libraries in the package folder and fix the
values for LC_ID_DYLIB and LC_LOAD_DYLIB so that they point to libraries using the
`@rpath` keyword instead of absolute folders. This way you can install this package in
different systems with different locations and be sure the the library will load.

## New "can_run()" and "check_min_vs" helpers.

Finally, two new tools deserve a mention here:

* [conan.tools.build.can_run(conanfile)](https://docs.conan.io/en/latest/reference/conanfile/tools/build.html#conan-tools-build-can-run):
  This can be an useful tool to use in a test_package, instead of checking if the binary
  has been cross compiled using the
  [cross_building()](https://docs.conan.io/en/latest/reference/conanfile/tools/build.html#conan-tools-build-cross-building)
  tool, you can use can_run() to cover the cases where the host platform can run binaries
  built for other architectures, such is the case for Mac M1 machines that can run both
  `armv8` and `x86_64` executables.

*  [conan.tools.microsoft.check_min_vs(conanfile,
   version)](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#check-min-vs):
   This tool checks if we are using at least the minimum required version when using the
   recipe. The important thing is that it will accept both version arguments from `Visual
   Studio` (1.x) and `msvc` (2.0) compilers, thus allowing the migration of recipes from
   1.X to 2.0 without breaking.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
