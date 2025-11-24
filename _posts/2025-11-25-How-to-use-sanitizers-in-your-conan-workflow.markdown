---
layout: post
comments: false
title: "How to Use Compiler Sanitizers in Your Conan C/C++ Workflow"
description: "Learn how to integrate compiler sanitizers into your Conan projects."
meta_title: "How to Use Compiler Sanitizers in Your Conan C/C++ Workflow"
categories: [sanitizers, toolchain, tools, conan]
---

Modern C and C++ projects may grow fast, and be developed in parallel. Keeping them correct and safe is a huge challenge
when releasing to production and serving several users.

In order to enlighten the dark corners of undefined behavior, memory corruption, and data races, compiler sanitizers are invaluable tools, but they can also introduce complexity and confusion if not managed properly.

Using Conan to manage your C/C++ dependencies and builds can help in terms of consistency and reproducibility, and integrating sanitizers into a Conan workflow can be straightforward and effective.

Let's explore how to do this effectively, traceably, and safely.

---

## TL;DR - Key Takeaways

- **Sanitizers are runtime tools** that detect memory errors, undefined behavior, and data races in C/C++ code
- **Start with ASan + UBSan** for general debugging; use TSan for threading issues, MSan for uninitialized memory
- **Model sanitizers as Conan settings** (`compiler.sanitizer`) to ensure ABI compatibility across your dependency graph
- **Use Conan profiles** to configure sanitizer flags and environment variables in one place
- **Expect performance overhead:** ASan adds ~2-3x slowdown, TSan ~5-15x, MSan ~3x
- **Never ship sanitized builds to production** - they're for development and testing only
- **Build all dependencies with sanitizers** when using MSan to avoid false positives

---

## What Are Compiler Sanitizers (and Why Should You Care)?

Compiler sanitizers are runtime instrumentation tools built into your toolchain. These checks, along with a special runtime library, can detect many common programming mistakes such as:

- **Buffer overflows:** When a program tries to write data beyond the allocated space in memory.
- **Use-after-free:** When a program tries to use memory that has already been released.
- **Data races:** When multiple parts of a program try to access and modify the same data at the same time, leading to unpredictable results.
- **Memory leaks:** When a program allocates memory but fails to free it, leading to a gradual consumption of available memory.
- **Undefined behavior:** When a program performs an operation that the C++ standard doesn't define, which can lead to unexpected and often buggy behavior.


Nowadays, most compilers support a suite of sanitizers that can be enabled via simple command-line flags. The most commonly used sanitizers include:

- **AddressSanitizer (ASan):** Detects memory errors such as buffer overflows and use-after-free.
- **UndefinedBehaviorSanitizer (UBSan):** Catches undefined behavior like integer overflows and invalid casts.
- **ThreadSanitizer (TSan):** Identifies data races in multithreaded programs.
- **MemorySanitizer (MSan):** Detects uninitialized memory reads.
- **LeakSanitizer (LSan):** Finds memory leaks.

You don’t have to use every sanitizer at once. Here’s a quick decision guide:

- If you’re **starting from zero:** Use **ASan + UBSan** as a baseline.
- If you suspect **race conditions:** Use **TSan**.
- If you suspect **uninitialized memory:** Use **MSan**, consider rebuilding everything with it to avoid false positives.
- If you want **leak checks:** Use **LSan**, but is usually bundled with ASan.

Under the hood, sanitizers rewrite your code to insert checks, like replacing memory access instructions with instrumented versions that validate the access. When an error is detected, the sanitizer runtime reports it, often with a stack trace and detailed information about the violation.

> ⚠️ **Warning:** Do **NOT** use sanitizer builds for production binaries, especially ones with elevated privileges (e.g., SUID). Sanitizer runtimes rely on environment variables and can enable privilege escalation. Use them for development and testing only.

As very basic illustration, compiling with ASan on GCC/Clang looks like this:

```bash
g++ -fsanitize=address -g -o my_sanitized_program my_program.cpp
```

As a side note, MSVC also supports AddressSanitizer on x86, x64 and ARM64 with a similar flag: `/fsanitize=address`.

### Performance Impact

Sanitizers add runtime overhead, so it's important to understand the performance implications:

<div class="table-responsive">
  <table class="table table-bordered table-striped table-hover mb-3 align-middle border-top">
    <thead class="table-light">
      <tr>
        <th scope="col" class="fw-semibold text-nowrap">Sanitizer</th>
        <th scope="col" class="fw-semibold text-nowrap">Typical Slowdown</th>
        <th scope="col" class="fw-semibold text-nowrap">Memory Overhead</th>
        <th scope="col" class="fw-semibold">Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>ASan</strong></td>
        <td>2–3x</td>
        <td>2–3x</td>
        <td>Best balance of speed and detection</td>
      </tr>
      <tr>
        <td><strong>UBSan</strong></td>
        <td>~1.2x</td>
        <td>Minimal</td>
        <td>Very lightweight, combine with ASan</td>
      </tr>
      <tr>
        <td><strong>TSan</strong></td>
        <td>5–15x</td>
        <td>5–10x</td>
        <td>Expensive but essential for threading</td>
      </tr>
      <tr>
        <td><strong>MSan</strong></td>
        <td>~3x</td>
        <td>Minimal</td>
        <td>Requires full rebuild of dependencies</td>
      </tr>
      <tr>
        <td><strong>LSan</strong></td>
        <td>Minimal</td>
        <td>Minimal</td>
        <td>Usually runs at program exit</td>
      </tr>
    </tbody>
  </table>
</div>

These numbers are approximate and vary based on your code patterns. Memory-intensive applications may see higher overhead with ASan and TSan.

---

### ABI Compatibility and the Dependency Graph

Sanitizers don’t just add a couple of checks in your binaries; they can change several aspects of your program’s behavior and ABI.
As a result, when using sanitizers, you need to be aware of how they affect your entire dependency graph to avoid issues like crashes or false positives/negatives. Some of the aspects that sanitizers can affect include: memory layout, function behavior, and ABI.

In some cases, non-instrumented code may not interoperate correctly with instrumented code (e.g. MemorySanitizer), but in some other cases (e.g. AddressSanitizer) it might work enough for basic functionality.

Also, some sanitizers can be combined (e.g. ASan + UBSan), while others cannot (e.g. ASan + MSan). For example, AddressSanitizer and MemorySanitizer are incompatible because they both modify memory access behavior in conflicting ways. The compiler will usually emit an error if you try to combine incompatible sanitizers.

Here's a compatibility matrix for common sanitizer combinations:

| Combination  | Compatible? | Notes                                |
|--------------|-------------|--------------------------------------|
| ASan + UBSan | Yes         | Recommended baseline combination     |
| ASan + LSan  | Yes         | LSan is typically included with ASan |
| TSan + UBSan | Yes         | Good for multithreaded code          |
| ASan + TSan  | No          | Conflicting memory instrumentation   |
| ASan + MSan  | No          | Conflicting memory tracking          |
| TSan + MSan  | No          | Incompatible runtime requirements    |

As a result, the produced binaries have a different ABI and behavior depending on the sanitizer configuration used during compilation.

When using Conan to manage your C/C++ projects, it is crucial to ensure that all dependencies are mapped to ensure ABI compatibility across the entire dependency graph. This means that if you are building your main application with a specific sanitizer configuration, all its dependencies must also be built with a compatible configuration to avoid runtime issues.

---

## Model Sanitizers as Conan Settings (So Conan Can Track Them)

Conan generates unique [package ID](https://docs.conan.io/2/reference/binary_model/package_id.html) for each combination of settings, options and dependencies. If we want “Debug + ASan” to be a different binary than “Debug + no sanitizer”, we should make sanitizers part of the settings.

Instead of modifying `settings.yml`, you can define custom sub‑settings in your own [settings_user.yml](https://docs.conan.io/2/examples/config_files/settings/settings_user.html):

```yaml
# settings_user.yml

compiler:
 clang:
   sanitizer: [null, Address, Leak, Thread, Memory, UndefinedBehavior,
               HardwareAssistanceAddress, KernelAddress,
               AddressUndefinedBehavior, ThreadUndefinedBehavior]
 gcc:
   sanitizer: [null, Address, Leak, Thread, UndefinedBehavior,
               KernelAddress, AddressUndefinedBehavior, ThreadUndefinedBehavior]
 msvc:
   sanitizer: [null, Address, KernelAddress]
```

Conan will now understand `compiler.sanitizer` as part of the build configuration, but will not configure any flags or behavior by itself.

Also, in order to combine more than one sanitizer (e.g., ASan + UBSan), we provide combined tags like `AddressUndefinedBehavior`.

Now, using Conan profiles, you can create configurations that include sanitizers flags and settings. For example, you can have a `gcc_asan` profile for GCC Debug + ASan builds:


```ini
# gcc_asan

[settings]
arch=x86_64
os=Linux
build_type=Debug
compiler=gcc
compiler.cppstd=gnu20
compiler.libcxx=libstdc++11
compiler.version=15
compiler.sanitizer=Address

[conf]
tools.build:cflags+=["-fsanitize=address", "-fno-omit-frame-pointer"]
tools.build:cxxflags+=["-fsanitize=address", "-fno-omit-frame-pointer"]
tools.build:exelinkflags+=["-fsanitize=address"]
tools.build:sharedlinkflags+=["-fsanitize=address"]

[runenv]
ASAN_OPTIONS="halt_on_error=1:detect_leaks=1"
```

This profile not only sets `compiler.sanitizer=Address`, but also injects the necessary flags to enable ASan instrumentation during compilation and linking. Additionally, it configures the `ASAN_OPTIONS` environment variable to stop on the first error and enable leak detection at runtime.

---

## Building and Using Sanitized Packages with Conan

With the sanitizer profiles defined, building and using sanitized packages becomes a matter of selecting the appropriate profile during the Conan install step. In order to exercise the `gcc_asan` profile, let's visit a [known bug in Boost.JSON 1.86.0](https://github.com/boostorg/json/issues/1047) that ASan can catch. The issue was fixed in later versions, but serves as a good example.

First, create a simple application that uses Boost.JSON and has the buffer overflow bug:

```cpp
#include <boost/json/parse_into.hpp>
#include <boost/describe/class.hpp>

struct Test
{
 std::array<std::int64_t, 3> arr;
};

BOOST_DESCRIBE_STRUCT(Test, (), (arr))

int main()
{
 Test object{};
 std::error_code ec;

 std::string data = R"({"arr":[977,775500052916,9216,77552916,9216]})";
 boost::json::parse_into(object, data, ec);

 return 0;
}
```

Then, let's add a CMakeLists.txt to build it:

```cmake
cmake_minimum_required(VERSION 3.15)
project(BoostJsonAsanExample LANGUAGES CXX)

find_package(Boost REQUIRED COMPONENTS json)

add_executable(example main.cpp)
target_link_libraries(example PRIVATE Boost::json)
target_compile_features(example PRIVATE cxx_std_11)
```

And a `conanfile.txt` to declare the dependency:

```ini
[requires]
boost/1.86.0

[generators]
CMakeToolchain
CMakeDeps

[layout]
cmake_layout
```

Now, with all files in place, let's install the dependencies, setup the project, and build it:

```bash
conan install . -pr=gcc_asan -b=missing
cmake --preset conan-debug -DCMAKE_VERBOSE_MAKEFILE=ON
cmake --build --preset=conan-debug
```

The `-pr=gcc_asan` flag tells Conan to use the ASan profile we defined earlier, ensuring that both our application and its dependencies (Boost.JSON in this case) are built with ASan instrumentation. The `-b=missing` flag instructs Conan to build any missing packages from source, which is necessary here to ensure Boost.JSON is built with the correct sanitizer settings. Using Conan to [build with CMake Presets](https://docs.conan.io/2/examples/tools/cmake/cmake_toolchain/build_project_cmake_presets.html) requires CMake +3.23, but greatly simplifies the build commands. Also, enabling `CMAKE_VERBOSE_MAKEFILE` helps to see the actual compiler commands being executed, including the sanitizer flags that we expect to see. Those flags are injected by Conan, coming from the CMake toolchain generated from the profile, so we do not need to add them to the CMakeLists.txt either.


Finally, run the application:

```bash
build/Debug/example
```

This example used `Unix Makefiles` generator with CMake, and the output binary is located in `build/Debug/example` according to the CMake presets layout. But may vary depending on your generator and configuration.

The test application will run the `boost::json::parse_into()` function, which will reach a buffer overflow. When running the application, ASan should detect the error and report it:

```bash
=================================================================
==1445592==ERROR: AddressSanitizer: stack-buffer-overflow on address 0x6c78e4600038 at pc 0x5eefa6ad15a3 bp 0x7fff46dfd010 sp 0x7fff46dfd008
WRITE of size 8 at 0x6c78e4600038 thread T0
...
Address 0x6c78e4600038 is located in stack of thread T0 at offset 56 in frame
   #0 0x5eefa6aaf037 in main /tmp/tmp.BHxNAL5bpn/main.cpp:14

 This frame has 6 object(s):
   [32, 56) 'object' (line 16) <== Memory access at offset 56 overflows this variable
   [96, 112) 'ec' (line 17)
   [128, 152) 'data' (line 19)
   [192, 208) 'agg.tmp'
   [224, 240) 'ref.tmp' (line 20)
   [256, 280) 'ref.tmp37' (line 23)
HINT: this may be a false positive if your program uses some custom stack unwind mechanism, swapcontext or vfork
     (longjmp and C++ exceptions *are* supported)
SUMMARY: AddressSanitizer: stack-buffer-overflow /home/conan/.conan2/p/b/boost6d3a53bf84abe/p/include/boost/json/detail/parse_into.hpp:567:21 in boost::json::detail::converting_handler<boost::json::detail::sequence_conversion_tag, std::__1::array<long, 3ul>, boost::json::detail::converting_handler<boost::json::detail::described_class_conversion_tag, Test, boost::json::detail::into_handler<Test>>>::signal_value()
```

As you can see, ASan successfully detected the buffer overflow and provided a detailed report. All of this was achieved seamlessly within the Conan workflow, demonstrating how to effectively build and use sanitized packages. Still, the produced Boost/1.86.0 package will be listed and identified separately thanks to the `compiler.sanitizer` setting:

```bash
conan list "boost/1.86.0#latest:*" -f compact
Local Cache
 boost/1.86.0
   boost/1.86.0#514cca6b72ee8e0da1318a177e5d6c06%1763450148.1475632 (2025-11-18 07:15:48 UTC)
     boost/1.86.0#514cca6b72ee8e0da1318a177e5d6c06:6db083a153294679253acd9ba3d4af3727bbb6ea
       settings: Linux, x86_64, Debug, clang, gnu17, libc++, Address, 20
       options(diff):
       requires: bzip2/1.0.Z, libbacktrace/cci, zlib/1.3.Z
```

Fortunately, the Boost/1.87.0 package has that bug fixed, so you can use a newer version to avoid the issue altogether.
To install the latest version of Boost available in Conan Center, just run:

```bash
conan install -r conancenter --requires="boost/[*]"
```

---

## Troubleshooting Common Issues

Even with proper configuration, you may encounter some challenges when using sanitizers. Here are solutions to common problems:

### Third-Party Libraries That Can't Be Rebuilt

**Problem:** You depend on a prebuilt binary library that wasn't compiled with sanitizers.

**Solution:**
- For ASan/UBSan: This often works fine, though you won't get error detection in that library
- For MSan: You **should** rebuild the library or you'll get false positives.
- For TSan: Mixed instrumentation can lead to false positives; try to rebuild if possible

### Dealing with False Positives

**Problem:** Sanitizers report errors in code you know is correct.

**Solution:**
- Use suppression files (see below) to ignore specific known issues
- For MSan: Ensure **all** code is instrumented, including system libraries
- Verify the error isn't actually a real bug that happens to be "working" by accident
- In last case, check if there are reports about the issue in the sanitizer's issue tracker

### Sanitizer Conflicts

**Problem:** You need to test with multiple incompatible sanitizers (e.g., ASan and TSan).

**Solution:**
- Create separate Conan profiles for each sanitizer configuration
- Run different sanitizer builds in separate CI jobs
- Use ASan for general testing, TSan specifically for threading tests

### Slow Build Times

**Problem:** Building all dependencies with sanitizers takes too long.

**Solution:**
- Cache sanitizer-enabled packages in your Conan remote Artifactory repository
- Use `conan install --build=missing` to only rebuild what's necessary
- For a local development, consider using ASan only on your code and not all dependencies (except for MSan)

---

## Hints When Using Sanitizers

When using sanitizers in your Conan projects, here are some additional tips to ensure a smooth experience:

- **Suppressions:** Some libraries may trigger false positives with sanitizers. You can create suppression files to ignore specific known issues. For example, for ASan, you can create a file named `MyASan.supp` with content like:

 ```
 # Suppress known false positive in some_library for NameOfCFunctionToSuppress method
 interceptor_via_fun:NameOfCFunctionToSuppress
 ```

 Then, set the `ASAN_OPTIONS` environment variable to include the suppression file:

 ```ini
 [runenv]
 ASAN_OPTIONS="suppressions=MyASan.supp"
 ```

- **Build All Dependencies with Sanitizers when needed:** To avoid compatibility issues, ensure that all dependencies are built with the same sanitizer settings. This is most common when using MemorySanitizer, which requires all code to be instrumented. Use Conan's `-b=missing` option to build any missing packages from source with the correct configuration.

- **Use Debug Builds:** Sanitizers work best with debug builds, as they provide more information for error reporting. Ensure your Conan settings use `build_type=Debug`.

- **Monitor Performance:** Sanitizers can introduce performance overhead. Use them primarily during development and testing, and switch to non-instrumented builds for production releases.

---

## Conclusion: Sanitizers Without the Chaos

Compiler sanitizers are incredibly powerful, but in a large C/C++ codebase with many dependencies, they can feel intimidating.
Conan helps bring order to that chaos:

- By modeling sanitizers as part of the compiler settings (`compiler.sanitizer`), Conan can keep sanitized and non‑sanitized binaries cleanly separated.
- By using profiles, you get all in a single configuration file: settings, flags, and runtime environment.
- With proper flags, environment configuration, and occasional suppressions, sanitizer runs become a reliable debug tool rather than a wall of noise.

You can obtain more information about sanitizers integration with Conan in the official documentation: [C, C++ Compiler Sanitizers](https://docs.conan.io/2/security/sanitizers.html).

---

## Try It Yourself

Ready to add sanitizers to your project? Here's what to do next:

1. **Create a sanitizer profile** for your compiler (use the `gcc_asan` example above as a template)
2. **Add `settings_user.yml`** to your Conan configuration with the sanitizer settings
3. **Start a new Conan project** with `conan new cmake_lib`
4. **Build your project and run its tests** with `conan create . -pr=<your_sanitizer_profile>`

You can find a complete working example in our [GitHub Examples repository](https://github.com/conan-io/examples2/tree/main/examples/security/sanitizers).

### Related Resources

- [Conan Documentation: Sanitizers](https://docs.conan.io/2/security/sanitizers.html)
- [Google Sanitizers Wiki](https://github.com/google/sanitizers/wiki)
- [Clang Sanitizer Documentation](https://clang.llvm.org/docs/index.html)
- [GCC Instrumentation Options](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
- [Microsoft C/C++ Sanitizers](https://learn.microsoft.com/en-us/cpp/sanitizers/)

Happy debugging - and stay safe out there in UndefinedBehavior land.
