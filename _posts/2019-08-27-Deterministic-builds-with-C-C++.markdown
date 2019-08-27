---
layout: post
comments: false
title: "An introduction to deterministic builds with C/C++"
---

## What are deterministic builds ?

A deterministic build is the process of building the same source code with the same build environment
and build instructions producing exactly the same binary in two builds, even if they are made on
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
   invisible for the original authors. This can be fatal in safety critical environments such as
   medical, aerospace and automotive. Promising identical results for given inputs allows third
   parties to come to a consensus on a *correct* result.

- **Traceability and binary management**. If you want to have a repository to store your binaries you
  do not want to generate binaries with random checksums from sources at the same revision. That
  could lead the repository system to store different binaries as different versions when they should
  be the same. For example, if you are working in Windows or MacOs the most simple library will lead
  binaries with different checksums because of the timestamps included in the library formats for
  these Operating Systems.

## Sources of variation

There are many different factors that can make your builds *non-deterministic*. Factors will vary
between different operating systems and compilers. Each compiler has specific options to fix the
sources of indeterminism. To date `gcc` and `clang` are the ones that incorporate more options to fix
the sources of variation. For `msvc` there are some undocumented options that you can try but in the
end you will probably need to patch the binaries to get deterministic builds.

### Timestamps introduced by the compiler / linker

There are two main reasons for that our binaries could end up containing time information that will
make them not reproducible:

- The use of `__DATE__` or `__TIME__` macros in the sources.

- When the definition of the file format forces to store time information in the object files. This
  is the case of `Portable Executable` format in Windows and `Mach-O` in MacOs. In Linux `ELF` files
  do not encode any kind of timestamp. 

#### Possible solutions for Microsoft Visual Studio

Microsoft Visual Studio has an linker flag `/Brepro` that is undocumented by Microsoft. That flag
sets the timestamps from the `Portable Executable` format to a `-1` value as can be seen in the
attached images. 

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-08-27/conan-bin-with-brepro.png" align="center" alt="With BRepro flag"/>
</p>

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-08-27/conan-bin-without-brepro.png" align="center" alt="Without BRepro flag"/>
</p>

To activate that flag with CMake we will have to add this lines if creating a `.exe`:

```CMake
add_link_options("/Brepro")
```

or this for `.lib`

```CMake
set_target_properties(
    TARGET
    PROPERTIES STATIC_LIBRARY_OPTIONS "/Brepro"
)
```

The problem is that this flag makes the binaries reproducible (regarding timestamps in the file
format) if our final binary is a `.exe` but will not remove all timestamps if we are compiling a
`.lib`. In fact it does not remove the `TimeDateStamp` field from the  [COFF File
Header](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#file-headers) for the `.lib`
files. The only way to remove this information from the `.lib` binaries is patching the `.lib`
substituting the bytes corresponding to the `TimeDateStamp` field with any known value. This patching
process can be done in the `post_build` step.

#### Possible solutions for GCC and CLANG

- `gcc` detects the existence of the `SOURCE_DATE_EPOCH` environment variable. If this variable is
  set, its value specifies a UNIX timestamp to be used in replacement of the current date and time in
  the `__DATE__` and `__TIME__` macros, so that the embedded timestamps become reproducible. The
  value can be set to a known timestamp such as the last modification time of the source or package.

- `clang` makes use of `ZERO_AR_DATE` that if set, resets the timestamp that is introduced in the
  binary setting it to `epoch 0`.

These variables can be set by the Conan hook in the `pre_build` step calling a function like
`set_environment` and the restored if necessary in the `post_build` step with something like
`reset_environment`. 

```python
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
```

## Build folder information propagated to binaries

If the same sources are compiled in different folders sometimes folder information is propagated to
the binaries. This can happen mainly for two reasons:

- Use of macros that contain current file information like `__FILE__` macro.
- Creating debug binaries that store information of where the sources are.

### Possible solutions

Again the solutions will depend on the compiler used:

- `msvc` can't set options to avoid the propagation of this information to the binary files. The only
  way to get reproducible binaries is again using a Hook to strip this information in the build step.
  Note that as we are patching the binaries to achieve reproducible binaries the folders used for
  different builds should have the same length in characters.

- `gcc` has three compiler flags to work around the issue:
    - `-fdebug-prefix-map=OLD=NEW` can strip directory prefixes from debug info.
    - `-fmacro-prefix-map=OLD=NEW` is available since `gcc 8` and addresses irreproducibility due to
      the use of `__FILE__` macro.
    - `-ffile-prefix-map=OLD=NEW` is available sice `gcc 8` and is the union of `-fdebug-prefix-map`
      and `-fmacro-prefix-map`

- `clang` supports `-fdebug-prefix-map=OLD=NEW` from version 3.8 and is working on supporting the
  other two flags for future versions.

The best way to solve this is adding the flags to compiler options, for example is using `CMake`:

```CMake
add_compile_options("-ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
```

## Randomness created by the compiler

This problem arises for example in `gcc` when [Link-Time
Optimizations](https://gcc.gnu.org/wiki/LinkTimeOptimization) are activated (with the `-flto` flag).
This options introduces random generated names in the binary files. The only way to avoid this
problem is to use `-frandom-seed` flag. This option provides a seed that `gcc` uses when it would
otherwise use random numbers. It is used to generate certain symbol names that have to be different
in every compiled file. It is also used to place unique stamps in coverage data files and the object
files that produce them. This setting has to be different for each source file. One option would be
to set it to the checksum of the file so the probability of collision is very low. For example in
CMake it could be made with a function like this:

```CMake
set(LIB_SOURCES
    ./src/source1.cpp
    ./src/source2.cpp
    ./src/source3.cpp)

foreach(_file ${LIB_SOURCES})
    file(SHA1 ${_file} checksum)
    string(SUBSTRING ${checksum} 0 8 checksum)
    set_property(SOURCE ${_file} APPEND_STRING PROPERTY COMPILE_FLAGS "-frandom-seed=0x${checksum}")
endforeach()
```

## File order feeding to the build system

File ordering can be a problem if directories are read to return the files contain. For example Unix
does not have a deterministic order in which `readdir()` and `listdir()` should return the contents
of a directory, so trusting in this functions to feed the build system could produce non
deterministic builds.

The same problem arises for example if your build system stores the files for the linker in a
container that can return the elements in a non-deterministic order. This would make that each time
files were linked in different order and produce different binaries.

## References

- [https://www.chromium.org/developers/testing/isolated-testing/deterministic-builds]()
- [https://reproducible-builds.org/]()
- [https://wiki.yoctoproject.org/wiki/Reproducible_Builds]()
- [https://stackoverflow.com/questions/1180852/deterministic-builds-under-windows]()
- [https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#archive-library-file-format]()
- [https://devblogs.microsoft.com/oldnewthing/20180103-00/?p=97705]()
- [https://www.geoffchappell.com/studies/msvc/link/link/options/brepro.htm?tx=37&ts=0,267]()

## Tools

- [https://diffoscope.org/]()
- [https://salsa.debian.org/reproducible-builds/strip-nondeterminism]()
- [https://github.com/erocarrera/pefile]()
- [https://github.com/trailofbits/pe-parse]()
- [https://github.com/smarttechnologies/peparser]()
- [https://github.com/google/syzygy]()
- [https://github.com/llvm-mirror/llvm/tree/master/tools]()
- [https://github.com/nh2/ar-timestamp-wiper]()
- [https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fc]()
- [https://try.diffoscope.org/]()
