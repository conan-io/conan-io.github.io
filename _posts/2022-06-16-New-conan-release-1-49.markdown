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
significant new features and bug fixes. First, it's worth mentioning that we have finally
removed support for Python2 in Conan. Also, we have made some improvements to the CMakePresets
support to allow parameterizing the output folders using the value of the recipe settings
and options. Now you can use layouts feature in the *conanfile.txt* adding the `[layout]`
section. A new `tools.apple.fix_apple_shared_install_name` tool has been introduced, to fix shared
libraries that do not set the correct `LC_ID_DYLIB` and `LC_LOAD_DYLIB` fields. Finally,
we have added two new helpers: `conan.tools.build.can_run()` and
`conan.tools.microsoft.check_min_vs()`.


## Removed Python2 support

Starting with version 1.49, Conan will no longer work with Python 2. This is because [security
vulnerabilities of Conan dependencies](https://github.com/advisories/GHSA-ffqj-6fqr-9h24)
that haven't been addressed in Python 2, so the only alternative moving forward is to
finally remove Python 2 suport.

Python 2 was officially declared End Of Life two years and a half ago, and [Conan
1.22](https://docs.conan.io/en/latest/changelog.html#id1006) already declared Python 2 as
not supported. Extra blockers have been added in previous Conan releases to make everyone
aware. Now the security vulnerabilities that are out of our scope, makes impossible to
move forward support for Python 2. 

**Please upgrade to Python>=3.6 to continue using Conan>=1.49.** 

## New [layout] section in conanfile.txt

Until Conan 1.49 you could only use the layouts
[feature](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html) defining
the method in a *conanfile.py*. Conan 1.49 comes with support for layouts in the
*conanfile.txt* as well. You can now add a new [layout] section in your conanfile to add
one of the following pre-defined layouts:

- [cmake_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)
- [vs_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)
- [bazel_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts)

In the case of the `cmake_layout`, this feature enables consumers that use conanfile.txt
to take advantage of the CMakePresets integration. Let's see an example of a simple
consumer project that builds a *compressor* application with the following structure:

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

If you do a `conan install .`, you can see that the files are generated according to the
default `cmake_layout` and the *CMakeUserPresets.json* is created in the base folder,
next to the *CMakeLists.txt*.

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
defined in the `cmake_layout`.

## Improved CMakePresets with parameterized layout

Conan has incrementally improved the support for CMakePresets in the most recent releases.
Since Conan 1.49 you can use the new `tools.cmake.cmake_layout:build_folder_vars`
configuration to modify the
[cmake_layout](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake_layout.html#cmake-layout)
default values for the `conanfile.folders.build` and `conanfile.folders.generators`
attributes and also the default preset names for CMakePresets. Let's begin from the
previous `[layout]` example to see how this works.

As you know, the name of the presets and output folders by default is set to the value of
the `build_type` setting, so they are named `Release` or `Debug` by default. Let's use
this configuration to change that default, so that those folders and preset names take
other settings into account, like for example the `arch` setting. 

Let's to do a `conan install` and pass the `tools.cmake.cmake_layout:build_folder_vars`
configuration as an argument:

```bash
conan install . -c tools.cmake.cmake_layout:build_folder_vars='["settings.arch"]'
```

Now, if you list the available presets, you will see a new preset including the
architecture and the builds will output the files to the corresponding folder containing
the used archicture and build type in the name.

```bash
$ cmake --list-presets
Available configure presets:

  "Release"        - 'Release' config
  "Release-x86_64" - 'Release-x86_64' config

$ cmake --preset Release-x86_64
...

$ cmake --build --preset Release-x86_64
...
```

## New tools.apple.fix_apple_shared_install_name tool

We have added the new tool
[tools.apple.fix_apple_shared_install_name](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#conan-tools-apple-fix-apple-shared-install-name)
to help users address problems that can occur when shared libraries in Apple platforms.

As we explained in the [Conan documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotools.html#a-note-about-relocatable-shared-libraries-in-macos-built-the-autotools-build-helper)
making shared libraries relocatable in Apple platforms requires an extra effort because
when shared libraries are built, two fields called `LC_ID_DYLIB` and
`LC_LOAD_DYLIB`  containing the "install name" are embedded in the library header information, usually pointing to
an absolute shared library location in the filesystem. This absolute location will make
the library load fail when it's loaded in a different system without the library in that
location. 

The best solution to avoid this problem is to pass the appropriate flags for the linker so
that the absolute folder is substituted with the `@rpath` value. The `@rpath` special
keyword will tell the loader to search a list of paths to find the library. These paths
can be defined by the consumer of that library by defining the `LC_RPATH` field through
linker options. It's worth noting that, for example, CMake will do this by default,
searching the libraries your are linking against and adding the `LC_RPATH` entries
pointing at those.

Not all libraries are prepared to provide relocatable shared libraries, so if you make a
package for a library whose binaries are not relocatable, you have only two options,
either patching the libraries' build scripts to make them relocatable or fixing the
binaries after the build. 

The `tools.apple.fix_apple_shared_install_name` tool can help fix the binaries after
the build step. You would normally invoke this tool in the `package()` method of the recipe,
after moving the binaries to the package folder. Let's see how to use it with an example
of a library that uses Autotools as the build system:

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
values for `LC_ID_DYLIB` and `LC_LOAD_DYLIB` so that they point to libraries using the
`@rpath` keyword instead of absolute folders. This way you can install this package in
different systems with different locations and be sure the the library will load.

For a more detailed explanation on how this tool works, please read the [Conan documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#conan-tools-apple-fix-apple-shared-install-name).

## New can_run() and check_min_vs helpers

Finally, two new tools deserve a mention here:

* [conan.tools.build.can_run(conanfile)](https://docs.conan.io/en/latest/reference/conanfile/tools/build.html#conan-tools-build-can-run):
  This can be an useful tool to use in a test_package, instead of checking if the binary
  has been cross compiled using the
  [cross_building()](https://docs.conan.io/en/latest/reference/conanfile/tools/build.html#conan-tools-build-cross-building)
  tool, you can use `can_run()` to cover the cases where the host platform can run
  binaries built for other architectures. This is the case for Mac M1 machines that can
  run both `armv8` and `x86_64` executables.

*  [conan.tools.microsoft.check_min_vs(conanfile,version)](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#check-min-vs):
   This tool checks if we are using at least the minimum required version for the `msvc`
   or `Visual Studio` compilers. The important thing is that it will accept both version
   arguments for `Visual Studio` (1.x) and `msvc` (2.0) compilers, allowing the
   migration of recipes from 1.X to 2.0 without breaking.


---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
