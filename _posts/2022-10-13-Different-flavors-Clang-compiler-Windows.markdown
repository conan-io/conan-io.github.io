---
layout: post
comments: false
title: "Understanding the different flavors of Clang C and C++ compilers in Windows"
meta_title: "Understanding the different flavors of Clang C and C++ compilers in Windows" 
meta_description: "This article will explain the different flavors of Clang C and C++ compiler you might encounter in Windows, and give you some suggestions about which ones might be right for you, together with detailed instructions on how to use them with CMake and Conan."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Understanding the different flavors of Clang C and C++ compilers in Windows",
 "alternativeHeadline": "How to setup CMake and Conan for Windows Clang C++ compiler",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Diego Rodriguez-Losada, Conan co-founder", 
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan clang compiler windows", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
},
 "datePublished": "2022-10-13",
 "description": "This article will explain the different flavors of Clang C and C++ compiler you might encounter in Windows, and give you some suggestions about which ones might be right for you, together with detailed instructions on how to use them with CMake and Conan.",
 }
</script>

This article will explain the different flavors of Clang C and C++ compiler you might encounter in Windows, and give you some suggestions about which ones might be right for you, together with detailed instructions on how to use them with CMake and Conan.

## Introduction

The Microsoft C and C++ compiler (msvc or cl.exe) has been predominant for the last decades on Windows, and while the MinGW tools have been providing a working GNU ecosystem (with gcc/g++ compilers) for Windows for many years, it never gained widespread traction.

The Clang compiler, built on the shoulders of the LLVM giant has been gaining traction in the last years, first powering the C and C++ Apple development (now they have their own apple-clang fork), then gaining the attention of many developers for its excellent developer tools, parser infrastructure, sanitizers, formatters, and code quality and security frameworks. This trend has finally started catching on in Windows too, with more and more developers wanting to have a common compiler infrastructure in all OS, being even bundled and distributed in Microsoft Visual Studio IDE.

However, there are a few different variants of the Clang compiler in Windows, and it is not always evident what their differences are or when/how to use them so let’s take a deeper look at them. 

## The different flavors

There are several different ways to install the Clang compiler on Windows, let’s enumerate and name them:

- **LLVM/Clang**: The Clang compiler provided by the LLVM project, with official releases in [LLVM Github](https://github.com/llvm/llvm-project/releases)
- **Visual Studio CangCL**: the ClangCL toolset from the Visual Studio 16 2019 (v142) or Visual Studio 17 2022 (v143) [installers](https://learn.microsoft.com/en-us/cpp/build/clang-support-msbuild?view=msvc-170)
- **Msys2 Clang**: Clang compiler provided by the [Msys2 Windows subsystem](https://www.msys2.org/), that is the [clang64 environment](https://www.msys2.org/docs/environments/) 
- **Msys2 MinGW Clang**: Clang compiler provided by the [Msys2 MinGW64 environment](https://www.msys2.org/docs/environments/). Note this is different from the above **Msys2 Clang** compiler
- **Cygwin Clang**: Clang installed with the graphical user interface of [Cygwin](https://www.cygwin.com/)

We can group them in 2 big families:

- Visual Studio based: The **LLVM/Clang** and the **Visual Studio ClangCL**, as we will check later, are actually the same, just bundled and distributed in a different way. They use and link the Visual Studio runtime, and are intended to be compatible with the Visual studio msvc compiler
- Windows subsystems based: They are all different compilers using different runtime libraries with potentially different compilation/linking flags. They do not intend to be compatible with msvc, nor even between the different subsystems.

### Different runtimes

One of the major and important differences between these compilers is what C++ standard library implementation and what runtime libraries they are going to use. Checking the runtime dependencies can be done with the following setup (doing this with Conan is detailed later):

A static library that implements one single method ``hello()`` that outputs several preprocessor definitions:

```cpp
#include <iostream>
#include "hello.h"
 
void hello(){
    // ARCHITECTURES
    #ifdef _M_X64
    std::cout << "  hello/0.1: _M_X64 defined\n";
    #endif
 
    // COMPILER VERSIONS
    #if _MSC_VER
    std::cout << "  hello/0.1: _MSC_VER" << _MSC_VER<< "\n";
    #endif
 
    #if _MSVC_LANG
    std::cout << "  hello/0.1: _MSVC_LANG" << _MSVC_LANG<< "\n";
    #endif
 
     // MORE FLAGS
}
```

An executable that uses the library:

```cpp
#include "hello.h"
 
int main() {
    hello();
}
```

A CMakeLists.txt to build it:

```cmake
cmake_minimum_required(VERSION 3.15)
project(hello CXX)
 
add_library(hello src/hello.cpp)
target_include_directories(hello PUBLIC include)
 
add_executable(example src/example.cpp)
target_link_libraries(example hello)
```

When the ``example.exe`` executable is built, it is possible to use the ``dumpbin`` command to list its required shared libraries:

```bash
$ dumpbin /nologo /dependents "./path/to/example.exe"
```

This ``dumpbin`` command is not in the ``PATH`` by default, so it needs to be run in a Visual Studio prompt, or activate such prompt with the ``vcvars`` batch file (or any alternative solution, see dumpbin reference for details):

```bash
$ set "VSCMD_START_DIR=%CD%" && call "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvarsall.bat" amd64 && dumpbin /nologo /dependents "./path/to/example.exe"
```

This is the summary of the runtime dependencies of such executable for the different flavors (including the msvc compiler as a reference):

***

<style>
    table {font-size:75%;}
    td { border-bottom: 1px solid #dddddd;}
    thead { background-color:#dddddd;}
</style>
<table>
  <colgroup>
    <col width="10%" />
    <col width="25%" />
    <col width="20%" />
    <col width="45%" />
  </colgroup>
  <thead>
    <tr>
      <th>Flavor</th>
      <th>C++ stdlib</th>
      <th>Runtime</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>msvc</td>
      <td>MSVCP140(D).dll<br> VCRUNTIME140(D).dll<br> VCRUNTIME140_1(D).dll<br> ucrtbased.dll (only debug)</td>
      <td> api-ms-win-crt-*.dll</td>
      <td>The base reference Visual Studio cl.exe compiler. The api-ms-win-crt-*.dll is the modern one, default in Windows 10, but not by default in older Windows versions</td>
    </tr>
    <tr>
      <td>LLVM/ Clang</td>
      <td>MSVCP140(D).dll<br> VCRUNTIME(D).dll<br> ucrtbased.dll<br> (only debug) </td>
      <td>api-ms-win-crt-*.dll</td>
      <td>Identical runtime than msvc, aims to be binary compatible</td>
    </tr>
    <tr>
      <td>Visual Studio ClangCL</td>
      <td>MSVCP140(D).dll<br> VCRUNTIME(D).dll<br> ucrtbased.dll (only debug) </td>
      <td>api-ms-win-crt-*.dll</td>
      <td> Identical runtime than msvc, aims to be binary compatible (same compiler as LLVM/Clang)</td>
    </tr>
    <tr>
      <td>Msys2 Clang</td>
      <td>libc++.dll<br> libunwind.dll </td>
      <td>api-ms-win-crt-*.dll</td>
      <td>Depends on the libc++ specific Msys2 Clang library, binary incompatible with msvc one</td>
    </tr>
    <tr>
      <td>Msys2 MinGW Clang</td>
      <td>libstdc++6.dll</td>
      <td>msvcrt.dll</td>
      <td>Depends on the same stdlib as MinGW gcc compiler, can actually use libstdc++ and libstdc++11 variants. It uses the older msvcrt.dll, which comes in older WindowsAlso binary incompatible with msvc.</td>
    </tr>
    <tr>
      <td>Cygwin Clang (obsolete)</td>
      <td>cygstdc++-6.dll </td>
      <td>cygwin1.dll</td>
      <td>Specific stdlib from cygwin, binary incompatible with both msvc, and msys2 different runtimes.</td>
    </tr>
  </tbody>
</table>

***

Note: the ``KERNEL32.dll`` is always a system runtime dependency, in all cases, it has been omitted in the table.

Let's have a look and explain these results. The first relevant item is that all **msvc**, **LLVM/Clang** and **Visual Studio ClangCL** are using the same runtimes. This is because the **LLVM/Clang** compiler uses the MSVC APIs and libraries implementations. While this is more evident or expected from **Visual Studio ClangCL**, it is a bit more surprising for the **LLVM/Clang** release. It happens that such a release implements the location of the MSVC libraries in the system. Latest **LLVM/Clang** releases default to using Visual Studio 17 2022, but it is possible to force using other installations by defining the appropriate Visual Studio environment.

The MSVC libraries have different Release and Debug versions. The Debug versions append a D, like in ``MSVCP140D.dll``, and the Debug builds can introduce runtime dependencies to other libraries like ``ucrtbased.dll``, that aren’t necessarily used in the Release builds.

Also, the three **msvc**, **LLVM/Clang** and **Visual Studio ClangCL** compilers use the ``api-ms-win-crt-*.dll`` libraries at runtime. These libraries can be found installed in the Windows systems folders, but **LLVM/Clang** also redistributes a copy that can be found in its "bin" folder, together with the ``clang.exe`` and ``clang++.exe`` executable files.

The **Msys2 MinGW Clang** links with the GNU ``libstdc++`` (it can link with ``libstdc++`` or ``libstdc++11``), resulting in a runtime dependency to ``libstdc++6.dll`` and ``msvcrt.dll``, instead of the ``libc++.dll`` that **Msys2 Clang** uses. It might be worth noting that the ``msvcrt.dll`` is considered to be an older Windows API compared with ``api-ms-win-crt-*.dll``, but also more backwards compatible with older Windows OS versions (7, 8), while the latter only comes by default in Windows 10.

It is noticeable that Cygwin Clang is no longer being maintained, the latest version available there is clang 8.0.1. It is still added here for reference, and for those still having to deal with such legacy systems. The executables built with this **Cygwin Clang** compiler, use the ``cygstdc++-6.dll`` and ``cygwin1.dll`` runtimes when being instructed to use the ``libstdc++`` (or ``libstdc++11``). But they can also be told to use ``libc++``, and that results in using a different runtime, depending on ``cygc++-1.dll, cygc++abi-1.dll, cyggcc_s-seh-1.dll, cygwin1.dll`` instead.

It is possible for all flavors to statically link the C++ standard libraries statically inside executables, in that case the C++ runtime libraries are no longer an explicit dependency, and only the system runtime will be reported by ``dumpbin``. This can also happen if we build a pure C application. However, this doesn’t mean that we can mix different libraries that depend on different runtimes in our applications, as they will be binary incompatible.


### Compiler differences

The runtime libraries used are not the only difference between the different Clang compilers, but there are also ABI differences between the flavors, like the size of some types as ``long double``. It is also very important to note that each flavor will use different preprocessor directives, which can have a very heavy impact on the created binaries, specially for multi-platform, multi-compiler optimized code that will rely on such preprocessor definitions.

Here is a table summarizing some different preprocessor definitions (details on how to reproduce this table are explained below):

***

<table>
  <colgroup>
    <col width="10%" />
    <col width="13%" />
    <col width="20%" />
    <col width="20%" />
    <col width="17%" />
    <col width="20%" />
  </colgroup>
  <thead>
    <tr>
      <th>Flavor</th>
      <th>Arch</th>
      <th>Version</th>
      <th>Standard</th>
      <th>Subsystem</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>msvc</td>
      <td>_M_X64</td>
      <td>_MSC_VER=1933</td>
      <td>_MSVC_LANG=201402<br> __cplusplus=199711</td>
      <td></td>
      <td>The standard __cplusplus is not correct by default, need extra /Zc flag</td>
    </tr>
    <tr>
      <td>LLVM/ Clang</td>
      <td>_M_X64<br> __x86_64__ </td>
      <td>_MSC_VER=1933<br> __clang_major__=13</td>
      <td>_MSVC_LANG=201402<br> __cplusplus=201402</td>
      <td></td>
      <td>The _MSC_VER by default is 19.3/v143 from VS 17 2022, but can be changed using other version </td>
    </tr>
    <tr>
      <td>Visual Studio ClangCL</td>
      <td>_M_X64<br> __x86_64__ </td>
      <td>_MSC_VER=1933<br> __clang_major__=14</td>
      <td>_MSVC_LANG=201402<br> __cplusplus=201402</td>
      <td></td>
      <td>Same flags as LLVM/CLang</td>
    </tr>
    <tr>
      <td>Msys2 Clang</td>
      <td>_M_X64<br> __x86_64__</td>
      <td>__GNUC__=4<br> __GNUC_MINOR__=2<br> __clang_major__=14</td>
      <td>__cplusplus=201402</td>
      <td>__MINGW32__=1<br> __MINGW64__=1</td>
      <td>The MSVC related flags are replaced with GNU and standard ones. MinGW Makefiles are used to build</td>
    </tr>
    <tr>
      <td>Msys2 MinGW Clang</td>
      <td>_M_X64<br> __x86_64__</td>
      <td>__GNUC__=4<br> __GNUC_MINOR__=2<br> __clang_major__=14</td>
      <td>__cplusplus=201402<br> _GLIBCXX_USE_CXX11_ABI=1</td>
      <td>__MINGW32__=1<br> __MINGW64__=1</td>
      <td>Definition of _GLIBCXX_USE_CXX11_ABI evidence the libstdc++/libstdc++11 stdlib</td>
    </tr>
    <tr>
      <td>Cygwin Clang (obsolete)</td>
      <td>__x86_64__</td>
      <td>__GNUC__=4<br> __GNUC_MINOR__=2<br> __clang_major__=8</td>
      <td>__cplusplus=201402</td>
      <td>__CYGWIN__=1</td>
      <td>The bundled clang is 8.0, which is an old release.</td>
    </tr>
  </tbody>
</table>

***

On the architecture side, all Clang versions, except the obsolete Cygwin one, will declare both the MSVC specific ``_M_X64`` and the GNU and Clang ``__x86_64__`` one.

The compiler version varies between the 2 major families. The VS based ones will define ``_MSC_VER=1933``, (that belongs to v143 or 19.3 compiler version, the default one in Visual Studio 17 2022), together with the ``__clang_major__=13`` one for the Clang compiler. Note how the **Visual Studio ClangCL** and the **LLVM/Clang** versions are different, in this case, we are using the **LLVM/Clang** 13.0 version so we can manually check our build used the correct compiler (the **Visual Studio ClangCL** bundled one is version 14)

It is completely possible to use a different VS version when using **LLVM/Clang**. By default it will use the latest v143 runtime, but by activating the environment (via ``vcvars`` or running in another VS version prompt) it is possible to use that version instead. We will see it later in the tests, but in essence it is evidenced by a preprocessor definition like ``_MSC_VER=192X``. It is also possible to alter the default MSVC compatibility behavior with the compiler option ``-fms-compatibility-version``, which makes clang behave like other MSVC version, or ``-fmsc-version`` to just override the ``_MSC_VER`` value.

On the other hand, the Msys2 based Clang compilers will define ``__GNUC__`` flags instead, while still using the ``__clang_major__=13`` definitions. These definitions can be controlled with the ``-fgnuc-version`` compiler option, but note that it doesn’t really activate or deactivate the GNU extensions in Clang, just change the values of the preprocessor definitions.

Something similar happens with the C++ standard. The VS based Clang compilers will define both the VS specific ``_MSVC_LANG=201402`` (C++14 standard), and the C++ standard ``__cplusplus=201402``. Note however, how the Msys2 MinGW Clang  might also define the ``_GLIBCXX_USE_CXX11_ABI`` to instruct to use the ``libstdc++`` or the ``libstdc++11`` C++ standard library.

Note how the vanilla **msvc** will report ``__cplusplus199711``, even if the ``_MSVC_LANG=201402`` is correct to represent C++14. You would need to explicitly define ``/Zc:__cplusplus`` to have ``__cplusplus`` correctly defined.


## Configuring and testing different setups with CMake and Conan

This section illustrates how to test the different Clang flavors using CMake and Conan, as it provides a good abstraction layer over them, and allows to summarize the different configurations that are needed.

It requires having CMake>=3.23 and Conan>=1.53 installed in the system. Every individual subsection will describe the specific of the Clang installation.

Let's start with a simple C++ "hello" world project, that can be created with the predefined template:

```bash
$ conan new hello/0.1 -m=cmake_lib
```

Note that this is a CMake based project, that contains something very similar to the code posted above, and such a project is agnostic of Conan, its CMakeLists.txt does not contain anything Conan related. The ``conanfile.py`` recipe will allow us to build the project easily with different configurations (in this case different Clang variants).

Let's start with the "vanilla" **msvc** build, and there learn about the necessary configuration changes. The profile that we will use is:

**msvc.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=msvc
compiler.version=193
compiler.cppstd=14
compiler.runtime=dynamic
compiler.runtime_type=Release
```

Where ``compiler.version=193`` is the default compiler version (19.3, toolset v143) of Visual Studio 17 2022

This profile can be passed in the command line:

```sh
$ conan create . -pr=msvc.profile
...

hello/0.1: Hello World Release!
  hello/0.1: _M_X64 defined
  hello/0.1: _MSC_VER1933
  hello/0.1: _MSVC_LANG201402
  hello/0.1: __cplusplus199711
```

### LLVM/Clang

To install this, go to the [LLVM Github downloads](https://github.com/llvm/llvm-project/releases), fetch the Windows installer, for example the [LLVM/Clang 13 release](https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/LLVM-13.0.1-win64.exe) used in this blog post, and install it to some location as ``C:/ws/LLVM/Clang13``. It is not necessary to put it in the system PATH, and probably it is not recommended if you are using different compilers.

To build and test this project we will use the following profile (explained below):

**llvm_clang.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=clang
compiler.version=13
compiler.cppstd=gnu14
compiler.runtime=dynamic
compiler.runtime_type=Release
compiler.runtime_version=v143
 
[buildenv]
PATH=+(path)C:/ws/**LLVM/Clang**13/bin
PATH+=(path)C:/ws/msys64/mingw64/bin
 
[conf]
tools.env.virtualenv:auto_use=True
```

And apply it with

```sh
$ conan create . -pr=llvm_clang.profile

...
hello/0.1: Hello World Release!
  hello/0.1: _M_X64 defined
  hello/0.1: __x86_64__ defined
  hello/0.1: _MSC_VER1933
  hello/0.1: _MSVC_LANG201402
  hello/0.1: __cplusplus201402
  hello/0.1: __clang_major__13
```

Lets explain some interesting details of the profile.  The architecture, compiler, and compiler version should be self explanatory.

- ``compiler.cppstd=gnu14``. This can be different from **msvc**, because the clang compiler supports GNU extensions. It is also possible to leave ``compiler.cppstd=14`` if we don’t use those extensions
- ``compiler.runtime=dynamic``. In Windows, it is possible to link with the runtime statically or dynamically. Conan translates this to CMake to with ``CMAKE_MSVC_RUNTIME_LIBRARY``, which can take values as  ``MultiThreadedDLL``, ``MultiThreadedDebug`` which will be converted to the corresponding VS flags ``/MT /MTd /MD /MDd``. this profile configuration will select between the static and dynamic runtimes
- ``compiler.runtime_type=Release``. To complement the static/dynamic runtime, this profile setting will define if the runtime will be Debug or Release. In the general case, this should follow the ``build_type`` setting.
- ``compiler.runtime_version=v143``. As commented above, **LLVM/Clang** will use the latest Visual Studio 17 runtime from v143. We will change it later and see the effect.

As the ``[buildenv]`` section is showing, it is necessary to add a couple of things to the system ``PATH``:

- The path to the Clang compiler itself, the location where the executables are. Note that this is using the ``PATH=+(path)`` syntax, which means **prepend** to the ``PATH``. As Visual Studio might have a Clang compiler installed, and the Visual Studio environment might be activated, it would be possible to accidentally use the Visual Studio bundled ClangCL toolset instead of our own installed one.
- The path to MinGW. To build this CMake project, we can use the ``MinGW Makefiles``, ``Ninja`` or ``NMake Makefiles`` CMake generators. If we try to use a ``Visual Studio`` CMake generator, it will assume that it will use the Visual Studio bundled Clang, and not our own. In theory it is possible to define to MSBuild a custom location with
  ```xml
  <Project>
    <PropertyGroup>
      <LLVMInstallDir>C:\MyLLVMRootDir</LLVMInstallDir>
      <LLVMToolsVersion>15.0.0</LLVMToolsVersion>
    </PropertyGroup>
  </Project> 
  ```
  But up to our knowledge this is not possible using just CMake. This addition to the PATH will make the ``mingw32-make`` available to the build, as it is necessary, and we don’t have it installed at the system level either, because this could also interact in other ways, like bringing its own compilers. So this value is appended to the PATH, instead of prepended.

  The good thing of defining such PATH env-vars in a profile, is that they are not permanently defined, and only applied for the command using such a profile.

Finally, the conf ``tools.env.virtualenv:auto_use=True`` helps to emulate the Conan 2.0 behavior, in which it is not necessary to explicitly define in recipes the Environment generators. It will be equivalent to adding ``generators = "VirtualBuildEnv", "VirtualRunEnv"`` to the conanfiles.


#### LLVM/Clang with different generators and runtimes:

Changing the CMake generator can be done passing the appropriate ``conf``, either in command line or in the profile:

```sh
$ conan create . -pr=llvm_clang.profile -c tools.cmake.cmaketoolchain:generator=Ninja
```

The result should be exactly the same as the above one, which by default was using ``MinGW Makefiles``. It is also possible to define ``-c tools.cmake.cmaketoolchain:generator="NMake Makefiles"`` with identical results.

If we wanted to link the runtime statically, we can do:

```sh
$ conan create . -pr=llvm_clang.profile -s compiler.runtime=static
```

The program output would be still the same, but if we inspect the resulting ``\test_package\build\Release\example.exe`` executable with ``dumpbin``, we will realize that now it only depends on KERNEL32.dll, and none of the other runtime dynamic libraries.

Finally, if we wanted to use the same compiler, but using the Visual Studio 16 2019 runtime (the v142 toolset), we could do:

```sh
$ conan create . -pr=llvm_clang.profile -s compiler.runtime_version=v142
hello/0.1: Hello World Release!
  …
  hello/0.1: _MSC_VER1929
  …
```

Note how the MSVC version is the desired 19.2 now instead of the above with the default 19.3


### Visual Studio ClangCL

The way to install the Clang compiler inside Visual Studio is to use their own VS Installer application, and select the "Clang" compiler there. Read the [Microsoft Clang install docs](https://learn.microsoft.com/en-us/cpp/build/clang-support-msbuild?view=msvc-170#install) for more details. It will use it via the ``clang-cl.exe`` compiler driver that is compatible with the MSVC compiler command line arguments. The compiler is still the same internally (the same as **LLVM/Clang**), just it will accept Visual Studio arguments compatible with **msvc** ``cl.exe`` compiler.

The profile that we are going to use in this case carries over a lot of the same settings and configurations as we saw previously:

**vs_clang.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=clang
compiler.version=14
compiler.cppstd=gnu14
compiler.runtime=dynamic
compiler.runtime_type=Release
compiler.runtime_version=v143
 
[conf]
tools.env.virtualenv:auto_use=True
tools.cmake.cmaketoolchain:generator=Visual Studio 17
```

But there are a couple of differences:
It doesn’t need to define the PATH to the compiler, nor the path to ``mingw32-make``, as it will be using a "Visual Studio" CMake generator
The way to define it is going to use the **Visual Studio ClangCL** is to specify it in the ``tools.cmake.cmaketoolchain:generator=Visual Studio 17``, then CMake knows how to locate everything

Note the ``[settings]`` are identical to the previous **LLVM/Clang** profile, and indeed they result in the same final ``package_id``, because the final binary is supposed to be the same (not necessarily bit by bit, check about this in this [non-deterministic builds blog post](https://blog.conan.io/2019/09/02/Deterministic-builds-with-C-C++.html)). The settings ``compiler.runtime=dynamic``, ``compiler.runtime_type=Release``, ``compiler.runtime_version=v143``, regarding the runtime are still necessary, and should match the CMake ``Visual Studio`` generator being used. Even if it is not fully necessary from the toolchain perspective, it is still necessary to identify the binary and obtain that same ``package_id``.

With:

```sh
$ conan create . -pr=vs_clang.profile
```

We will obtain the same output as the above with the **LLVM/Clang** tooling.

### Msys2 Clang

The first step to use this compiler is to install Msys2, it can be done following the instructions at the [Msys2 site](https://www.msys2.org/). To install and uninstall things inside the different Msys2 environments, the ``pacman`` system package manager can be used. To install the development Clang toolchain, inside the clang64 environment, it is possible to install it with ``$ pacman -S mingw-w64-clang-x86_64-toolchain``

This will be the profile to use for this case:

**msys2_clang.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=clang
compiler.version=14
compiler.cppstd=gnu14
compiler.libcxx=libc++
 
[buildenv]
PATH+=(path)C:/ws/msys64/clang64/bin
 
[runenv]
PATH+=(path)C:/ws/msys64/clang64/bin
 
[conf]
tools.env.virtualenv:auto_use=True
```

There are some important differences with respect to the previous MSVC-based Clang compilers:
The ``compiler.runtime`` settings are no longer defined. Such runtime settings refer to Windows and MSVC runtime. And it not relevant to the GNU toolchain
In Clang and GNU compilers, the stdlib is managed by the ``compiler.libcxx`` which in this case is set to ``libc++``
Besides the ``[buildenv]`` PATH pointing to the location of the Clang compiler inside Msys2, it is necessary the equivalent in runtime ``[runenv]``, so when the ``conanfile.py`` executes the executable, it can find the ``libc++.dll`` and ``libunwind.dll`` dynamic libraries. The above compilers runtimes were in the system and automatically picked up.

When executing the ``conan create`` we should see:

```sh
$ conan create . -pr=msys2_clang.profile
hello/0.1: Hello World Release!
  hello/0.1: _M_X64 defined
  hello/0.1: __x86_64__ defined
  hello/0.1: __cplusplus201402
  hello/0.1: __GNUC__4
  hello/0.1: __GNUC_MINOR__2
  hello/0.1: __clang_major__14
  hello/0.1: __MINGW32__1
  hello/0.1: __MINGW64__1
```

### Msys2 MinGW Clang

This compiler is installed with ``pacman -S mingw-w64-x86_64-clang`` inside the Msys2 MinGW64 terminal. Note the command is not exactly the same as the above (that uses the ``mingw-w64-clang-x86_64-toolchain`` package instead).

The profile used for this configuration is:

**msys2_mingw_clang.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=clang
compiler.version=14
compiler.cppstd=gnu14
compiler.libcxx=libstdc++11
 
[buildenv]
PATH+=(path)C:/ws/msys64/mingw64/bin
 
[runenv]
PATH+=(path)C:/ws/msys64/mingw64/bin
 
[conf]
tools.env.virtualenv:auto_use=True
```

The main differences with the above **Msys2 Clang** are:
- ``PATH+=(path)C:/ws/msys64/mingw64/bin`` points to a different location, the one of MinGW64, not the one of clang
- ``compiler.libcxx=libstdc++11`` now uses the gcc ``libstdc++`` or ``libstdc++1`` C++ standard library instead of the ``libc++`` used by **Msys2 Clang**

And running ``conan create`` with that profile, will result in:

```sh
$ conan create . -pr=msys2_mingw_clang.profile
hello/0.1: Hello World Release!
  hello/0.1: _M_X64 defined
  hello/0.1: __x86_64__ defined
  hello/0.1: _GLIBCXX_USE_CXX11_ABI 1
  hello/0.1: __cplusplus201402
  hello/0.1: __GNUC__4
  hello/0.1: __GNUC_MINOR__2
  hello/0.1: __clang_major__14
  hello/0.1: __MINGW32__1
  hello/0.1: __MINGW64__1
```

Where we can appreciate that everything is the same, except the preprocessor definition ``_GLIBCXX_USE_CXX11_ABI 1`` indicating the usage of ``libstdc++11``.

### Cygwin Clang

Cygwin itself can be installed from [Cygwin site](https://www.cygwin.com/install.html), and installing Clang compiler inside it, can be done with its GUI installer, selecting the ``clang`` compiler and clicking on "install" button.

The profile used in this case is also similar:

**cygwin_clang.profile**

```ini
[settings]
os=Windows
arch=x86_64
build_type=Release
compiler=clang
compiler.version=8
compiler.cppstd=gnu14
compiler.libcxx=libstdc++
 
[buildenv]
PATH+=(path)C:/ws/cygwin64/bin
 
[runenv]
PATH+=(path)C:/ws/cygwin64/bin
 
[conf]
tools.env.virtualenv:auto_use=True
tools.cmake.cmaketoolchain:generator=Unix Makefiles
```

But with some minor changes:

- The path location of the environments point to the cygwin "bin" folder
- It is necessary to indicate that ``Unix Makefiles`` are necessary, as the default ``MinGW Makefiles`` will not work
- The compiler version is 8, because that matches the one installed in cygwin
- The ``compiler.libcxx`` here is ``libstdc++``, but it can also be ``libstdc++11`` and even ``libc++``, resulting in this later case in using different runtime libraries (check the "Different runtime" section)

The result of creating this package shows:

```sh
$ conan create . -pr=cygwin_clang.profile
hello/0.1: Hello World Debug!
  hello/0.1: __x86_64__ defined
  hello/0.1: _GLIBCXX_USE_CXX11_ABI 0
  hello/0.1: __cplusplus201402
  hello/0.1: __GNUC__4
  hello/0.1: __GNUC_MINOR__2
  hello/0.1: __clang_major__8
  hello/0.1: __CYGWIN__1
```

It can be seen how the message prints ``hello/0.1: Hello World Debug!``, instead of ``Release`` like the other flavors, this is because the common ``NDEBUG`` preprocessor definition is not defined in this environment (but it is in all the others).

## Conclusions

The **Cygwin Clang** has been overwhelmingly replaced by the Msys2 flavors for this reason we are suggesting starting new efforts using the other flavors.

To decide between the MSVC based Clang flavors (**LLVM/Clang** and **Visual Studio ClangCL**) and the Msys2 based ones, the decision should be made depending on the other project constraints. In general the MSVC based Clang provides better compatibility with other Windows binary libraries and the system in general, while using the Msys2 subsystem flavor can work better if there are some other dependencies that heavily rely on GNU tools and wouldn’t work well with the MSVC compiler.

Between **Msys2 Clang** and **Msys2 MinGW Clang**, the decision should be made similarly. If there are other dependencies of the project that rely on ``libstdc++`` runtime that have to play together, **Msys2 MinGW Clang** is probably the way to go, but otherwise, it seems that **Msys2 Clang** with ``libc++`` could be the way to go.

In MSVC-based Clang, between **LLVM/Clang** and **Visual Studio ClangCL**, the final decision is probably the IDE. If a lot of development happens on Windows and developers want to use Visual Studio IDE, then the **Visual Studio ClangCL** will be better. If on the contrary most development happens in Linux, and Windows devs are happy with VS Code editor and using Ninja (which many developers love because of it being very fast), then **LLVM/Clang** could be a better choice.
