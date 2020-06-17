---
layout: post
comments: false
title: "An introduction to deterministic builds with C/C++"
---

## What are deterministic builds?

A deterministic build is a process of building the same source code with the same build environment
and build instructions producing the same binary in two builds, even if they are made on
different machines, build directories and with different names. They are also sometimes called
reproducible or hermetic builds if it is guaranteed to produce the same binaries even compiling from
different folders.

Deterministic builds are not something that happens naturally. Normal projects do not produce
deterministic builds and the reasons that they are not produced can be different for each operating
system and compiler.

Deterministic builds should be guaranteed for a given *build environment*. That means that certain
variables such as the *operating system*, *build system versions* and *target architecture* are
assumed to remain the same between different builds.

There are lots of efforts coming from different organizations in the past years to achieve
deterministic builds such as
[Chromium](https://www.chromium.org/developers/testing/isolated-testing/deterministic-builds),
[Reproducible builds](https://reproducible-builds.org/), or
[Yocto](https://wiki.yoctoproject.org/wiki/Reproducible_Builds).

## The importance of deterministic builds

There are two main reasons why deterministic builds are important:

 - **Security**. Modifying binaries instead of the upstream source code can make the changes
   invisible for the original authors. This can be fatal in safety-critical environments such as
   medical, aerospace and automotive. Promising identical results for given inputs allows third
   parties to come to a consensus on a *correct* result.

- **Traceability and binary management**. If you want to have a repository to store your binaries you
  do not want to generate binaries with random checksums from sources at the same revision. That
  could lead the repository system to store different binaries as different versions when they should
  be the same. For example, if you are working on Windows or MacOs the most simple library will lead
  binaries with different checksums because of the timestamps included in the library formats for
  these Operating Systems.

## Binaries involved in the building process in C/C++

There are different types of binaries that are created during the building process in C/C++ depending
on the operating system. 

 - **Microsoft Windows**. The most important files are the ones with `.obj`, `.lib`,`.dll` and `.exe`
   extensions. All of them follow the specification of the Portable Executable format (PE). This
   files can be analyzed with tools such as
   [dumpbin](https://docs.microsoft.com/en-us/cpp/build/reference/dumpbin-reference?view=vs-2019). 

 - **Linux**. Files with `.o`, `.a`,`.so` and `none` (for executable binaries) extensions follow the
   Executable and Linkable Format (ELF). The contents of ELF files can be analyzed by
   [readelf](https://sourceware.org/binutils/docs/binutils/readelf.html).   

 - **Mac OS**. Files with `.o`, `.a`,`.dylib` and `none` (for executable binaries) extensions follow
   the Mach-O format specification. These files can be inspected with the
   [otool](https://opensource.apple.com/source/cctools/cctools-921/otool/) application that is part
   of the XCode toolchain in MacOs.

## Sources of variation

Many different factors can make your builds *non-deterministic*. Factors will vary
between different operating systems and compilers. Each compiler has specific options to fix the
sources of indeterminism. To date `gcc` and `clang` are the ones that incorporate more options to fix
the sources of variation. For `msvc` there are some undocumented options that you can try but in the
end, you will probably need to patch the binaries to get deterministic builds.

### Timestamps introduced by the compiler/linker

There are two main reasons for that our binaries could end up containing time information that will
make them not reproducible:

- The use of `__DATE__` or `__TIME__` macros in the sources.

- When the definition of the file format forces to store time information in the object files. This
  is the case of *Portable Executable* format in Windows and `Mach-O` in MacOs. In Linux `ELF` files
  do not encode any kind of timestamp. 

Let's put an example of where does this information ends with a basic hello world project linking a
static library in MacOs. 

{% highlight console %}
.
├── CMakeLists.txt
├── hello_world.cpp
├── hello_world.hpp
├── main.cpp
└── run_build.sh
{% endhighlight %}

The library prints a message in the terminal:

{% highlight cpp %}
#include "hello_world.hpp"
#include <iostream>
void HelloWorld::PrintMessage(const std::string & message)
{
    std::cout << message << std::endl;
}
{% endhighlight %}

And the application will use it to print a "Hello World!" message:

{% highlight cpp %}
#include <iostream>
#include "hello_world.hpp"
int main(int argc, char** argv)
{
    HelloWorld hello;
    hello.PrintMessage("Hello World!");
    return 0;
}
{% endhighlight %}

We will use CMake to build the project:

{% highlight cmake %}
cmake_minimum_required(VERSION 3.0)
project(HelloWorld)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_library(HelloLibA hello_world.cpp)
add_library(HelloLibB hello_world.cpp)
add_executable(helloA main.cpp)
add_executable(helloB main.cpp)
target_link_libraries(helloA HelloLibA)
target_link_libraries(helloB HelloLibB)
{% endhighlight %}

We build two different libraries with the exact same sources and two binaries with the same sources
as well. If we build the project and execute md5sum to show the checksums of all the binaries:

{% highlight console %}
mkdir build && cd build
cmake ..
make
md5sum helloA
md5sum helloB
md5sum CMakeFiles/HelloLibA.dir/hello_world.cpp.o
md5sum CMakeFiles/HelloLibB.dir/hello_world.cpp.o
md5sum libHelloLibA.a
md5sum libHelloLibB.a
{% endhighlight %}

We get an output like this:

{% highlight console %}
b5dce09c593658ee348fd0f7fae22c94  helloA
b5dce09c593658ee348fd0f7fae22c94  helloB
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibA.dir/hello_world.cpp.o
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibB.dir/hello_world.cpp.o
adb80234a61bb66bdc5a3b4b7191eac7  libHelloLibA.a
5ac3c70d28d9fdd9c6571e077131545e  libHelloLibB.a
{% endhighlight %}

This is interesting because the executables files `helloA` and `helloB` have the same checksums as well
as the intermediate Mach-O object files `hello_world.cpp.o` but that is not the case of the `.a` files.
That is because they store the information of the intermediate object files in `archive format`. The
definition of the header of this format includes a field named `st_time` set by a `stat` system
call. If we inspect the `libHelloLibA.a` and `libHelloLibB.a` using `otool` to show the headers:

{% highlight console %}
> otool -a libHelloLibA.a   
Archive : libHelloLibA.a
0100644 503/20    612 1566927276 #1/20
0100644 503/20  13036 1566927271 #1/28
> otool -a libHelloLibB.a   
Archive : libHelloLibB.a
0100644 503/20    612 1566927277 #1/20
0100644 503/20  13036 1566927272 #1/28
{% endhighlight %}

We can see that the file includes several time fields that will make our build non-deterministic.
Let's note that those fields are not propagated to the final executable because they have the same
checksum. This problem would also happen if building in Windows with Visual Studio but with the
`Portable Executable` instead of `Mach-O`.

At this point we could try to make things even worse and force our binaries to be non-deterministic as well. If we change `main.cpp` file to include the `__TIME__` macro:

{% highlight cpp %}
#include <iostream>
#include "hello_world.hpp"
int main(int argc, char** argv)
{
    HelloWorld hello;
    hello.PrintMessage("Hello World!");
    std::cout << "At time: " << __TIME__ << std::endl;
    return 0;
}
{% endhighlight %}

Getting the checksums of the files again:

{% highlight console %}
625ecc7296e15d41e292f67b57b04f15  helloA
20f92d2771a7d2f9866c002de918c4da  helloB
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibA.dir/hello_world.cpp.o
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibB.dir/hello_world.cpp.o
b7801c60d3bc4f83640cadc1183f43b3  libHelloLibA.a
4ef6cae3657f2a13ed77830953b0aee8  libHelloLibB.a
{% endhighlight %}

We see that now we have different binaries as well. We could analyze the executable file with a tool
such as [diffoscope](https://diffoscope.org/) that shows us the difference between the two binaries:

{% highlight console %}
> diffoscope helloA helloB
--- helloA
+++ helloB
├── otool -arch x86_64 -tdvV {}
│┄ Code for architecture x86_64
│ @@ -16,15 +16,15 @@
│  00000001000018da	jmp	0x1000018df
│  00000001000018df	leaq	-0x30(%rbp), %rdi
│  00000001000018e3	callq	0x100002d54 ## symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev
│  00000001000018e8	movq	0x1721(%rip), %rdi ## literal pool symbol address: __ZNSt3__14coutE
│  00000001000018ef	leaq	0x162f(%rip), %rsi ## literal pool for: "At time: "
│  00000001000018f6	callq	0x100002d8a ## symbol stub for: __ZNSt3__1lsINS_11char_traitsIcEEEERNS_13basic_ostreamIcT_EES6_PKc
│  00000001000018fb	movq	%rax, %rdi
│ -00000001000018fe	leaq	0x162a(%rip), %rsi ## literal pool for: "19:40:47"
│ +00000001000018fe	leaq	0x162a(%rip), %rsi ## literal pool for: "19:40:48"
│  0000000100001905	callq	0x100002d8a ## symbol stub for: __ZNSt3__1lsINS_11char_traitsIcEEEERNS_13basic_ostreamIcT_EES6_PKc
│  000000010000190a	movq	%rax, %rdi
│  000000010000190d	leaq	__ZNSt3__1L4endlIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_(%rip), %rsi #
{% endhighlight %}

That shows that the `__TIME__` information was inserted in the binary making it non-deterministic. Let's see what we could do to avoid this.

#### Possible solutions for Microsoft Visual Studio

Microsoft Visual Studio has a linker flag `/Brepro` that is undocumented by Microsoft. That flag
sets the timestamps from the `Portable Executable` format to a `-1` value as can be seen in the
image below. 

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-09-02/conan-brepro.png" align="center" alt="With BRepro flag"/>
</p>

To activate that flag with CMake we will have to add this lines if creating a `.exe`:

{% highlight cmake %}
add_link_options("/Brepro")
{% endhighlight %}

or this for `.lib`

{% highlight cmake %}
set_target_properties(
    TARGET
    PROPERTIES STATIC_LIBRARY_OPTIONS "/Brepro"
)
{% endhighlight %}

The problem is that this flag makes the binaries reproducible (regarding timestamps in the file
format) in our final binary is a `.exe` but will not remove all timestamps from the `.lib` (the same
problem that we talked about with the Mach-O object files above). The `TimeDateStamp` field from the
[COFF File Header](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#file-headers) for
the `.lib` files will stay. The only way to remove this information from the `.lib` binary is
patching the `.lib` substituting the bytes corresponding to the `TimeDateStamp` field with any known
value.

#### Possible solutions for GCC and CLANG

- `gcc` detects the existence of the `SOURCE_DATE_EPOCH` environment variable. If this variable is
  set, its value specifies a UNIX timestamp to be used in replacement of the current date and time in
  the `__DATE__` and `__TIME__` macros so that the embedded timestamps become reproducible. The
  value can be set to a known timestamp such as the last modification time of the source or package.

- `clang` makes use of `ZERO_AR_DATE` that if set, resets the timestamp that is introduced in the
  `archive files` setting it to `epoch 0`. Take into account that this will not fix the `__DATE__` or
  `__TIME__` macros. If we want to fix the effect of this macros we should either patch the binaries
  or fake the system time.

Let's continue with our example project for MacOs and see what the results are when setting
`ZERO_AR_DATE` environment variable. 

{% highlight console %}
export ZERO_AR_DATE=1
{% endhighlight %}

Now, if we build our executable and libraries (omitting the `__DATE__` macro in the sources), we get:

{% highlight console %}
b5dce09c593658ee348fd0f7fae22c94  helloA
b5dce09c593658ee348fd0f7fae22c94  helloB
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibA.dir/hello_world.cpp.o
0a4a0de3df8cc7f053f2fcb6d8b75e6d  CMakeFiles/HelloLibB.dir/hello_world.cpp.o
9f9a9af4bb3e220e7a22fb58d708e1e5  libHelloLibA.a
9f9a9af4bb3e220e7a22fb58d708e1e5  libHelloLibB.a
{% endhighlight %}

All the checksums are now the same. And analyzing the `.a` files headers:

{% highlight console %}
> otool -a libHelloLibA.a
Archive : libHelloLibA.a
0100644 503/20    612 0 #1/20
0100644 503/20  13036 0 #1/28
> otool -a libHelloLibB.a
Archive : libHelloLibB.a
0100644 503/20    612 0 #1/20
0100644 503/20  13036 0 #1/28
{% endhighlight %}

We can see that the timestamp field of the library header has been set to zero value.

### Build folder information propagated to binaries

If the same sources are compiled in different folders sometimes folder information is propagated to
the binaries. This can happen mainly for two reasons:

- Use of macros that contain current file information like `__FILE__` macro.

- Creating debug binaries that store information of where the sources are.

Continuing with our hello world MacOs example let's separate the sources so we can show the effect over the final binaries. The project structure will be like the one below.

{% highlight console %}
.
├── run_build.sh
├── srcA
│   ├── CMakeLists.txt
│   ├── hello_world.cpp
│   ├── hello_world.hpp
│   └── main.cpp
└── srcB
    ├── CMakeLists.txt
    ├── hello_world.cpp
    ├── hello_world.hpp
    └── main.cpp
{% endhighlight %}

If we build our binaries in `Debug` mode.

{% highlight console %}
cd srcA/build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make
cd .. && cd ..
cd srcB/build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make
cd .. && cd ..
md5sum srcA/build/hello
md5sum srcB/build/hello
md5sum srcA/build/CMakeFiles/HelloLib.dir/hello_world.cpp.o
md5sum srcB/build/CMakeFiles/HelloLib.dir/hello_world.cpp.o
md5sum srcA/build/libHelloLib.a
md5sum srcB/build/libHelloLib.a
{% endhighlight %}

We get the following checksums:

{% highlight console %}
3572a95a8699f71803f3e967f92a5040  srcA/build/hello
7ca693295e62de03a1bba14853efa28c  srcB/build/hello
76e0ae7c4ef79ec3be821ccf5752730f  srcA/build/CMakeFiles/HelloLib.dir/hello_world.cpp.o
5ef044e6dcb73359f46d48f29f566ae5  srcB/build/CMakeFiles/HelloLib.dir/hello_world.cpp.o
dc941156608b578c91e38f8ecebfef6d  srcA/build/libHelloLib.a
1f9697ef23bf70b41b39ef3469845f76  srcB/build/libHelloLib.a
{% endhighlight %}

The folder information is propagated from the object files to the final executables
making our builds non-reproducible. We could show the differences between binaries using diffoscope
to see where the folder information is embedded.

{% highlight console %}
> diffoscope helloA helloB
--- srcA/build/hello
+++ srcB/build/hello
@@ -1282,20 +1282,20 @@
...
 00005070: 5f77 6f72 6c64 5f64 6562 7567 2f73 7263  _world_debug/src
-00005080: 412f 006d 6169 6e2e 6370 7000 2f55 7365  A/.main.cpp./Use
+00005080: 422f 006d 6169 6e2e 6370 7000 2f55 7365  B/.main.cpp./Use
 00005090: 7273 2f63 6172 6c6f 732f 446f 6375 6d65  rs/carlos/Docume
 000050a0: 6e74 732f 6465 7665 6c6f 7065 722f 7265  nts/developer/re
 000050b0: 7072 6f64 7563 6962 6c65 2d62 7569 6c64  producible-build
 000050c0: 732f 7361 6e64 626f 782f 6865 6c6c 6f5f  s/sandbox/hello_
-000050d0: 776f 726c 645f 6465 6275 672f 7372 6341  world_debug/srcA
+000050d0: 776f 726c 645f 6465 6275 672f 7372 6342  world_debug/srcB
 000050e0: 2f62 7569 6c64 2f43 4d61 6b65 4669 6c65  /build/CMakeFile
 000050f0: 732f 6865 6c6c 6f2e 6469 722f 6d61 696e  s/hello.dir/main
 00005100: 2e63 7070 2e6f 005f 6d61 696e 005f 5f5a  .cpp.o._main.__Z
...
@@ -1336,15 +1336,15 @@
...
 000053c0: 6962 6c65 2d62 7569 6c64 732f 7361 6e64  ible-builds/sand
 000053d0: 626f 782f 6865 6c6c 6f5f 776f 726c 645f  box/hello_world_
-000053e0: 6465 6275 672f 7372 6341 2f62 7569 6c64  debug/srcA/build
+000053e0: 6465 6275 672f 7372 6342 2f62 7569 6c64  debug/srcB/build
 000053f0: 2f6c 6962 4865 6c6c 6f4c 6962 2e61 2868  /libHelloLib.a(h
 00005400: 656c 6c6f 5f77 6f72 6c64 2e63 7070 2e6f  ello_world.cpp.o
 00005410: 2900 5f5f 5a4e 3130 4865 6c6c 6f57 6f72  ).__ZN10HelloWor
...
{% endhighlight %}

#### Possible solutions

Again the solutions will depend on the compiler used:

- `msvc` can't set options to avoid the propagation of this information to the binary files. The only
  way to get reproducible binaries is again using a patching tool to strip this information in the
  build step. Note that as we are patching the binaries to achieve reproducible binaries the folders
  used for different builds should have the same length in characters.

- `gcc` has three compiler flags to work around the issue:
    - `-fdebug-prefix-map=OLD=NEW` can strip directory prefixes from debug info.
    - `-fmacro-prefix-map=OLD=NEW` is available since `gcc 8` and addresses irreproducibility due to
      the use of `__FILE__` macro.
    - `-ffile-prefix-map=OLD=NEW` is available sice `gcc 8` and is the union of `-fdebug-prefix-map`
      and `-fmacro-prefix-map`

- `clang` supports `-fdebug-prefix-map=OLD=NEW` from version 3.8 and is working on supporting the
  other two flags for future versions.

The best way to solve this is by adding the flags to compiler options. If we are using `CMake`:

```CMake
target_compile_options(target PUBLIC "-ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
```
### File order feeding to the build system

File ordering can be a problem if directories are read to list their files. For example Unix does not
have a deterministic order in which `readdir()` and `listdir()` should return the contents of a
directory, so trusting in these functions to feed the build system could produce non-deterministic
builds.

The same problem arises for example if your build system stores the files for the linker in a
container (like a regular python dictionary) that can return the elements in a non-deterministic
order. This would make that each time files were linked in a different order and produce different
binaries.

We can simulate this problem changing the order of files in CMake. If we modify the previous example
to have more than just one source file for the library:

{% highlight console %}
.
├── CMakeLists.txt
├── CMakeListsA.txt
├── CMakeListsB.txt
├── hello_world.cpp
├── hello_world.hpp
├── main.cpp
├── sources0.cpp
├── sources0.hpp
├── sources1.cpp
├── sources1.hpp
├── sources2.cpp
└── sources2.hpp
{% endhighlight %}

We can see that the results of the compilation are different if we change the order of files in the `CMakeLists.txt`:

{% highlight cmake %}
cmake_minimum_required(VERSION 3.0)
project(HelloWorld)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_library(HelloLib hello_world.cpp 
                     sources0.cpp 
                     sources1.cpp 
                     sources2.cpp)
add_executable(hello main.cpp)
target_link_libraries(hello HelloLib)
{% endhighlight %}

If we make two consecutive builds named `A` and `B` swapping `sources0.cpp` and `sources1.cpp` in the files list the resulting checksums will be:

{% highlight console %}
30ab264d6f8e1784282cd1a415c067f2  helloA
cdf3c9dd968f7363dc9e8b40918d83af  helloB
707c71bc2a8def6885b96fb67b84d79c  hello_worldA.cpp.o
707c71bc2a8def6885b96fb67b84d79c  hello_worldB.cpp.o
694ff3765b688e6faeebf283052629a3  sources0A.cpp.o
694ff3765b688e6faeebf283052629a3  sources0B.cpp.o
0db24dc6a94da1d167c68b96ff319e56  sources1A.cpp.o
0db24dc6a94da1d167c68b96ff319e56  sources1B.cpp.o
fd0754d9a4a44b0fcc4e4f3c66ad187c  sources2A.cpp.o
fd0754d9a4a44b0fcc4e4f3c66ad187c  sources2B.cpp.o
baba9709d69c9e5fd51ad985ee328172  libHelloLibA.a
72641dc6fc4f4db04166255f62803353  libHelloLibB.a
{% endhighlight %}

Object files `.o` are identical but `.a` libraries and executables are not. That is because the insertion order in the libraries depends on the order the files were listed.

### Randomness created by the compiler

This problem arises for example in `gcc` when [Link-Time
Optimizations](https://gcc.gnu.org/wiki/LinkTimeOptimization) are activated (with the `-flto` flag).
This option introduces randomly generated names in the binary files. The only way to avoid this
problem is to use `-frandom-seed` flag. This option provides a seed that `gcc` uses when it would
otherwise use random numbers. It is used to generate certain symbol names that have to be different
in every compiled file. It is also used to place unique stamps in coverage data files and the object
files that produce them. This setting has to be different for each source file. One option would be
to set it to the checksum of the file so the probability of collision is very low. For example in
CMake it could be made with a function like this:

{% highlight cmake %}
set(LIB_SOURCES
    ./src/source1.cpp
    ./src/source2.cpp
    ./src/source3.cpp)

foreach(_file ${LIB_SOURCES})
    file(SHA1 ${_file} checksum)
    string(SUBSTRING ${checksum} 0 8 checksum)
    set_property(SOURCE ${_file} APPEND_STRING PROPERTY COMPILE_FLAGS "-frandom-seed=0x${checksum}")
endforeach()
{% endhighlight %}

## Some tips using Conan

Conan [hooks](https://docs.conan.io/en/latest/extending/hooks.html) can help us in the process of
making our builds reproducible. This feature makes it possible to customize the client behavior at
determined points.

One use of hooks could be setting environment variables in the `pre_build` step. The example below is
calling a function `set_environment` and then restoring the environment in the `post_build` step with
`reset_environment`. 

{% highlight python %}
def set_environment(self):
    if self._os == "Linux":
        self._old_source_date_epoch = os.environ.get("SOURCE_DATE_EPOCH")
        timestamp = "1564483496"
        os.environ["SOURCE_DATE_EPOCH"] = timestamp
        self._output.info(
            "set SOURCE_DATE_EPOCH: {}".format(timestamp))
    elif self._os == "Macos":
        os.environ["ZERO_AR_DATE"] = "1"
        self._output.info(
            "set ZERO_AR_DATE: {}".format(timestamp))

def reset_environment(self):
    if self._os == "Linux":
        if self._old_source_date_epoch is None:
            del os.environ["SOURCE_DATE_EPOCH"]
        else:
            os.environ["SOURCE_DATE_EPOCH"] = self._old_source_date_epoch
    elif self._os == "Macos":
        del os.environ["ZERO_AR_DATE"]
{% endhighlight %}

Hooks can also be useful to patch binaries in the `post_build` step. There are different binary files
analysis and patching tools like [ducible](https://github.com/jasonwhite/ducible),
[pefile](https://github.com/erocarrera/pefile), [pe-parse](https://github.com/trailofbits/pe-parse)
or [strip-nondeterminism](https://salsa.debian.org/reproducible-builds/strip-nondeterminism). An
example of a hook for patching a `PE` binary using *ducible* could be like this one:

{% highlight python %}
class Patcher(object):
...
    def patch(self):
        if self._os == "Windows" and self._compiler == "Visual Studio":
            for root, _, filenames in os.walk(self._conanfile.build_folder):
                for filename in filenames:
                    filename = os.path.join(root, filename)
                    if ".exe" in filename or ".dll" in filename:
                        self._patch_pe(filename)

    def _patch_pe(self, filename):
        patch_tool_location = "C:/ducible/ducible.exe"
        if os.path.isfile(patch_tool_location):
            self._output.info("Patching {} with md5sum: {}".format(filename,md5sum(filename)))
            self._conanfile.run("{} {}".format(patch_tool_location, filename))
            self._output.info("Patched file: {} with md5sum: {}".format(filename,md5sum(filename)))
...

def pre_build(output, conanfile, **kwargs):
    lib_patcher.init(output, conanfile)
    lib_patcher.set_environment()

def post_build(output, conanfile, **kwargs):
    lib_patcher.patch()
    lib_patcher.reset_environment()

{% endhighlight %}

## Conclusions

Deterministic builds are a complex problem highly coupled with the operating system and toolchain used. This introduction should have served to understand the most common causes of indeterminism and how to avoid them. 

## References

### General info

- [https://www.chromium.org/developers/testing/isolated-testing/deterministic-builds](https://www.chromium.org/developers/testing/isolated-testing/deterministic-builds)
- [https://reproducible-builds.org/](https://reproducible-builds.org/)
- [https://wiki.yoctoproject.org/wiki/Reproducible_Builds](https://wiki.yoctoproject.org/wiki/Reproducible_Builds)
- [https://stackoverflow.com/questions/1180852/deterministic-builds-under-windows](https://stackoverflow.com/questions/1180852/deterministic-builds-under-windows)
- [https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#archive-library-file-format](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#archive-library-file-format)
- [https://devblogs.microsoft.com/oldnewthing/20180103-00/?p=97705](https://devblogs.microsoft.com/oldnewthing/20180103-00/?p=97705)
- [https://www.geoffchappell.com/studies/msvc/link/link/options/brepro.htm?tx=37&ts=0,267](https://www.geoffchappell.com/studies/msvc/link/link/options/brepro.htm?tx=37&ts=0,267)

### Tools

#### Tools for comparing binaries

- [https://diffoscope.org/](https://diffoscope.org/)
- [https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fc](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fc)

#### Tools for patching files

- [https://salsa.debian.org/reproducible-builds/strip-nondeterminism](https://salsa.debian.org/reproducible-builds/strip-nondeterminism)
- [https://github.com/erocarrera/pefile](https://github.com/erocarrera/pefile)
- [https://github.com/trailofbits/pe-parse](https://github.com/trailofbits/pe-parse)
- [https://github.com/smarttechnologies/peparser](https://github.com/smarttechnologies/peparser)
- [https://github.com/google/syzygy](https://github.com/google/syzygy)
- [https://github.com/nh2/ar-timestamp-wiper](https://github.com/nh2/ar-timestamp-wiper)

#### Tools for analyzing files

- [https://docs.microsoft.com/en-us/cpp/build/reference/dumpbin-reference?view=vs-2019](https://docs.microsoft.com/en-us/cpp/build/reference/dumpbin-reference?view=vs-2019)
- [https://sourceware.org/binutils/docs/binutils/readelf.html](https://sourceware.org/binutils/docs/binutils/readelf.html)
- [https://github.com/llvm-mirror/llvm/tree/master/tools](https://github.com/llvm-mirror/llvm/tree/master/tools)
- [https://github.com/lief-project/LIEF](https://github.com/lief-project/LIEF)

