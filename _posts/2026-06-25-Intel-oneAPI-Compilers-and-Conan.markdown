---
layout: post
comments: false
title: "Intel oneAPI Compilers and Conan: High-Performance C++ Made Easy"
description: "Learn how to use Intel oneAPI DPC++/C++ compilers with Conan for high-performance C++ development, including SYCL support for heterogeneous computing."
meta_title: "Intel oneAPI Compilers and Conan: High-Performance C++ - Conan Blog"
keywords: "conan, C++, intel, oneapi, icx, icpx, sycl, dpcpp, compiler, performance, heterogeneous computing"
categories: [cpp, conan, intel]
---

The Intel oneAPI DPC++/C++ Compiler is one of the most powerful tools available
for C++ developers targeting high-performance computing. Whether you're
optimizing numerical code, working with vectorized operations, or exploring
heterogeneous computing with SYCL, Intel's compilers offer capabilities that go
beyond what standard compilers provide.

## What is Intel oneAPI?

Intel oneAPI is a unified programming model for development across CPUs, GPUs,
and FPGAs. The **Intel DPC++/C++ Compilers** (`icx`/`icpx`) are modern
LLVM-based compilers that replace the classic `icc`/`icpc`.

**Why use Intel compilers?**

- **Performance optimizations**: Auto-vectorization, interprocedural optimization
  (IPO), and profile-guided optimization (PGO) for Intel architectures.
- **SYCL for heterogeneous computing**: Write once, run on CPUs, GPUs, and FPGAs.
- **Math libraries**: Tight integration with Intel MKL for high-performance
  numerical computing.
- **Modern C++**: Full support for C++17, C++20, and C++23 standards.

## Getting started

### Installation

**Linux (Debian/Ubuntu):**

```bash
# Add Intel repository
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | sudo tee /usr/share/keyrings/intel-oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/intel-oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | sudo tee /etc/apt/sources.list.d/oneAPI.list

# Install DPC++/C++ compiler
sudo apt-get update
sudo apt-get install -y intel-oneapi-compiler-dpcpp-cpp-2026.0
```

**Windows:**

Download the [offline installer](https://www.intel.com/content/www/us/en/developer/tools/oneapi/oneapi-toolkit-download.html?packages=oneapi-toolkit&oneapi-toolkit-os=windows&oneapi-win=offline)
and run the setup wizard. The offline installer is recommended for a smoother
installation experience.

### Environment activation

Before using the Intel compilers, you need to activate the environment:

**Linux:**
```bash
source /opt/intel/oneapi/setvars.sh
```

**Windows (cmd):**
```batch
"C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
```

### First example

Let's compile a simple program that demonstrates Intel's auto-vectorization.
The compiler will automatically use SIMD instructions to speed up the loop:

```cpp
// hello.cpp
#include <iostream>
#include <vector>
#include <numeric>

int main() {
    std::vector<double> data(1000000);
    std::iota(data.begin(), data.end(), 1.0);
    
    double sum = 0.0;
    #pragma omp simd reduction(+:sum)
    for (size_t i = 0; i < data.size(); ++i)
        sum += data[i];
    
    std::cout << "Sum: " << sum << std::endl;
}
```

```bash
$ icpx -O3 -qopenmp-simd hello.cpp -o hello && ./hello
Sum: 5.00001e+11
```

## SYCL: Heterogeneous computing

SYCL is a cross-platform C++ abstraction layer that enables code for
heterogeneous processors to be written in standard C++. With SYCL, you can
write single-source code that runs on CPUs, GPUs, and FPGAs without
vendor-specific extensions.

> **Note**: The `dpcpp` compiler is deprecated. Use `icpx -fsycl` instead.

Here's a vector addition example using SYCL. The code creates a queue to submit
work to a device, uses buffers to manage memory, and launches a parallel kernel
that runs on all available compute units:

```cpp
// vector_add.cpp
#include <sycl/sycl.hpp>
#include <iostream>

int main() {
    sycl::queue q;  // Create queue, selects default device
    std::cout << "Device: " 
              << q.get_device().get_info<sycl::info::device::name>() << "\n";

    constexpr size_t N = 1024;
    std::vector<float> a(N, 1.0f), b(N, 2.0f), c(N);
    {
        // Buffers manage data movement between host and device
        sycl::buffer buf_a(a), buf_b(b), buf_c(c);
        q.submit([&](sycl::handler& h) {
            // Accessors define how the kernel accesses buffer data
            auto A = buf_a.get_access<sycl::access::mode::read>(h);
            auto B = buf_b.get_access<sycl::access::mode::read>(h);
            auto C = buf_c.get_access<sycl::access::mode::write>(h);
            // Launch N parallel work items
            h.parallel_for(N, [=](sycl::id<1> i) { C[i] = A[i] + B[i]; });
        });
    }  // Buffer destruction synchronizes and copies data back
    std::cout << "c[0]=" << c[0] << ", c[N-1]=" << c[N-1] << "\n";
}
```

```bash
$ icpx -fsycl vector_add.cpp -o vector_add && ./vector_add
Device: Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
c[0]=3, c[N-1]=3
```

## Compiling with dependencies using Conan

The examples above work great for standalone code. But real-world projects
typically depend on external libraries. What if you want to use zlib for
compression, fmt for formatting, or any of the thousands of libraries available
in ConanCenter—all compiled with Intel's optimizing compilers?

This is where **Conan** shines. Conan has native support for Intel oneAPI
compilers. When you specify `compiler=intel-cc` in your profile, Conan
automatically:

- Sources the Intel `setvars.sh` (or `.bat` on Windows) to set up the environment
- Configures the build system to use `icx`/`icpx` compilers
- Builds all your dependencies with Intel compilers
- Sets up the runtime environment for SYCL libraries

### Intel profiles

**Linux** (`~/.conan2/profiles/intel_sycl`):
```ini
[settings]
os=Linux
arch=x86_64
compiler=intel-cc
compiler.mode=icx
compiler.version=2026.0
compiler.cppstd=17
compiler.libcxx=libstdc++
build_type=Release

[conf]
tools.build:cxxflags=["-fsycl"]
tools.build:exelinkflags=["-fsycl"]
tools.build:sharedlinkflags=["-fsycl"]
tools.intel:installation_path=/opt/intel/oneapi
```

**Windows** (`%USERPROFILE%\.conan2\profiles\intel_sycl`):
```ini
[settings]
os=Windows
arch=x86_64
compiler=intel-cc
compiler.mode=icx
compiler.version=2026.0
compiler.cppstd=17
compiler.runtime=dynamic
build_type=Release

[conf]
tools.build:cxxflags=["-fsycl"]
tools.build:exelinkflags=["-fsycl"]
tools.build:sharedlinkflags=["-fsycl"]
tools.intel:installation_path=C:\Program Files (x86)\Intel\oneAPI
```

### Example: SYCL app with zlib and fmt

Let's put it all together with a complete example. We'll build an application
that combines SYCL parallel computation with two popular C++ libraries: zlib
for data compression and fmt for modern formatted output. All of this compiled
with Intel's optimizing compiler.

Clone the example from the [Conan examples repository](https://github.com/conan-io/examples2):

```bash
git clone https://github.com/conan-io/examples2.git
cd examples2/examples/tools/intel/sycl_app
```

The application computes squares in parallel using SYCL, then compresses the
results with zlib:

```cpp
#include <sycl/sycl.hpp>
#include <zlib.h>
#include <fmt/core.h>
#include <vector>

int main() {
    sycl::queue q;
    fmt::print("SYCL Device: {}\n", 
               q.get_device().get_info<sycl::info::device::name>());

    // Compute squares using SYCL parallel_for
    constexpr size_t N = 10000;
    std::vector<float> data(N);
    {
        sycl::buffer buf(data);
        q.submit([&](sycl::handler& h) {
            auto acc = buf.get_access<sycl::access::mode::write>(h);
            h.parallel_for(N, [=](sycl::id<1> i) {
                acc[i] = static_cast<float>(i[0] * i[0]);
            });
        });
    }
    fmt::print("Computed {} squares. First: {}, Last: {}\n",
               N, data[0], data.back());

    // Compress results with zlib
    std::vector<Bytef> compressed(compressBound(data.size() * sizeof(float)));
    uLongf comp_size = compressed.size();
    compress(compressed.data(), &comp_size,
             reinterpret_cast<const Bytef*>(data.data()),
             data.size() * sizeof(float));

    fmt::print("Compressed {} bytes -> {} bytes ({:.1f}%)\n",
               data.size() * sizeof(float), comp_size,
               100.0 * comp_size / (data.size() * sizeof(float)));
}
```

Build and run:

```bash
$ conan build . -pr intel_sycl --build missing
...

$ source build/Release/generators/conanrun.sh
:: initializing oneAPI environment ...
   bash: BASH_VERSION = 5.2.21(1)-release
   args: Using "$@" for setvars.sh arguments: intel64
:: compiler -- latest
:: debugger -- latest
:: dev-utilities -- latest
:: dpl -- latest
:: tbb -- latest
:: tcm -- latest
:: umf -- latest
:: oneAPI environment initialized ::

$ ./build/Release/sycl_app
SYCL Device: Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
Computed 10000 squares. First: 0, Last: 9.998e+07
Compressed 40000 bytes -> 23395 bytes (58.5%)
```

Conan builds the application and all dependencies (zlib, fmt) with Intel
compilers. The `conanrun.sh` script sets up the runtime environment so the
SYCL libraries are found.

## Conclusion

Intel oneAPI compilers bring powerful optimizations and SYCL support for
heterogeneous computing. Conan's native integration makes it easy to use them
with any C++ library from ConanCenter.

For more details, check the
[Conan documentation](https://docs.conan.io/2/reference/tools/intel.html).
