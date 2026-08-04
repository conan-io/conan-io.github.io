---
layout: post
comments: false
title: "CUDA meets Windows on ARM64: getting your applications ready for NVIDIA RTX Spark with Conan"
description: "The CUDA Toolkit 13.4 developer preview brings native and cross-compiled Windows ARM64 support, and Conan makes it a drop-in dependency"
meta_title: "CUDA on Windows ARM64 with Conan - Conan Blog"
categories: [cuda, gpu, armv8, arm64, windows, conan, nvidia, jetson, jetpack]
---

Windows on ARM just got a lot more interesting for developers building local AI agents and creators pushing GPU-accelerated workflows. With **NVIDIA RTX Spark** bringing CUDA-capable
silicon to ARM64 laptops and devices, and NVIDIA shipping the **CUDA Toolkit 13.4 developer preview** — the first
CUDA release with a compiler and device libraries that target **Windows 11 on ARM64** — the door is now open for
CUDA-accelerated applications to run natively on this platform.

The remaining question for most teams is: how do you actually plug this into your build? Today we're excited to
show you that with [`cuda-conan`](https://github.com/conan-io/cuda-conan), the answer is the same as it's always
been with Conan — add a requirement, and go.

> CUDA 13.4 is currently a **developer preview**, made available by NVIDIA so that developers can start porting
> their applications ahead of general availability. See NVIDIA's
> [release notes](https://docs.nvidia.com/cuda/developer-preview/13.4/cuda-toolkit-release-notes/index.html) for details.

> `cuda-conan` is a **recipes only** repository, no binaries are provided. Building packages from these
> recipes downloads the CUDA Toolkit and other NVIDIA components as made available by NVIDIA, subject to NVIDIA's
> own terms, including any applicable EULAs.

## Why this matters

NVIDIA RTX Spark and the broader wave of ARM-powered Windows devices represent a real shift in where GPU-accelerated
applications need to run. In order to take advantage of ARM64 native performance as well as the integrated GPU acceleration, your CUDA applications will
need to be rebuilt for the new platform. And until now, there hasn't been a great way to use CUDA as a dependency
without cobbling together manual toolkit installs and fragile environment setups — something that gets even messier
the moment you want to cross-build from an x86_64 CI runner instead of testing on physical ARM64 hardware.

The recipes and features of `cuda-conan` close that gap. The recipes in the repository automate the
download of the CUDA Toolkit, along with related libraries like cuDNN and TensorRT, so that you can
use them as any other dependencies. Conan will configure your build, ensure compatible binaries, and
expose the right environment when running your programs. Windows and Linux are supported, including 
cross-building for Jetson devices — and now, for the first time, the developer
preview makes it possible to target Windows ARM64 as well, including cross-building from x86_64 Windows.

## CUDA as just another dependency

First, configure the `cuda-conan` remote:

```
git clone https://github.com/conan-io/cuda-conan
conan remote add cuda-conan ./cuda-conan
```

If you already use Conan, that's the only setup required. From there on, adding CUDA is just another entry in your
`conanfile.py`:

```python
def requirements(self):
    self.requires("cuda-toolkit/[>=13 <14]")
    self.tool_requires("cuda-toolkit/<host_version>")
```

That's it — the same two lines work for every platform CUDA supports, whether you're building natively or
cross-compiling. Your `CMakeLists.txt` needs no Conan-specific changes either, and can follow standard CMake
practice:

```cmake
enable_language(CUDA)
find_package(CUDAToolkit)
```

Conan resolves and provides the toolkit, and `find_package(CUDAToolkit)` finds it. No system-wide CUDA install, no
environment variables pointing at a specific CUDA installation, nothing extra to configure in CI beyond having
Conan available.

In your profile, set the GPU architecture(s) you're targeting, for example:

```
tools.cmake.cmaketoolchain:extra_variables*={'CMAKE_CUDA_ARCHITECTURES':'87-real'}
```

And for the rest of your dependencies? Conan Center already builds and supports over **800 libraries for Windows
ARM64**, so chances are your stack is already covered — see
[Windows ARM64 builds now enabled in Conan Center](https://blog.conan.io/armv8/arm64/windows/conan/2025/10/01/Windows-arm64-builds-now-enabled-in-Conan-Center.html)
for the full story.

## No ARM64 hardware? No problem

One of the best parts of this setup is that you don't need an ARM64 machine to get started in order to start porting your applications. Cross-compiling for
Windows ARM64 works directly from your existing x86_64 workstations or CI runners. If your Conan profile is already
set up for `msvc`, cross-building is as simple as adding `--settings arch=armv8` to your Conan command (e.g. `create` or `install`):

```
conan create . --settings arch=armv8
```

Under the hood, Conan makes sure `nvcc` runs on your x86_64 build machine while linking ARM64 CUDA libraries into
your application — so the executable you get out the other end is ready to run on RTX Spark and other ARM64
devices, no emulation required.

Before you build, there are a couple of one-time setup steps:

- A recent Conan 2 (>=2.31.1 recommended)
- Visual Studio 2022 or 2026 with the **ARM64 MSVC toolset** installed (via the Visual Studio Installer → Individual
  components → search "ARM64" → select the C++ ARM64 build tools for your version). This is required for both
  native and cross builds — see
  [ARM64 Visual Studio is officially here!](https://devblogs.microsoft.com/visualstudio/arm64-visual-studio-is-officially-here/)

## Seeing it in action: `cuda-samples`

Talk is cheap — let's build something. [`cuda-samples`](https://github.com/NVIDIA/cuda-samples) is NVIDIA's own
collection of example CUDA applications, from minimal ones like `vectorAdd` and `deviceQuery` up through CUDA
library usage (cuBLAS, cuFFT, and more). `cuda-conan` ships a recipe that builds it from source with CUDA from
Conan, ARM64 included.

```
git clone https://github.com/conan-io/cuda-conan
conan remote add cuda-conan ./cuda-conan
```

```
cd cuda-conan/samples/cuda-samples
conan build . --settings arch=armv8 -c tools.cmake.cmaketoolchain:generator=Ninja --build=missing -cc core.version_ranges:resolve_prereleases=True
```

Drop `--settings arch=armv8` and it builds natively for x86_64 instead — same command, same recipe, either target. Once
it's built, load the run environment and try it out:

```
cmd.exe /k "build\Release\generators\conanrun.bat"
build\Release\cpp\1_Utilities\deviceQuery\deviceQuery.exe
```

If you don't have an NVIDIA-powered ARM64 device on hand yet, that's fine — the binary will still run, and simply
report that `cudaGetDeviceCount` couldn't find a device.

## The big one: `llama.cpp` with CUDA support for RTX Spark

Here's where it gets fun. [`llama.cpp`](https://github.com/ggml-org/llama.cpp) is the dependency-light C/C++
inference engine behind a huge chunk of the local-LLM ecosystem — over 80k stars on GitHub, and the engine powering
downstream projects like Ollama and LM Studio. Getting it running with CUDA acceleration on Windows ARM64 is exactly
the kind of workload RTX Spark exists for: local, GPU-accelerated AI inference on an ARM64 PC.

`cuda-conan` includes a recipe for it too, CUDA and Windows ARM64 support included:

```
cd samples/llama-cpp
conan create all --version=b6565 -pr clang-cl-arm64 --build=missing -cc core.version_ranges:resolve_prereleases=True
```

This same command runs on both x86_64 and ARM64 Windows. Want a different GPU architecture target? Just edit the
profile at `samples/llama-cpp/clang-cl-common`.

> Windows ARM64 builds of `llama.cpp` currently require building with **Clang** (`clang-cl`) rather than MSVC's
> `cl.exe`. Install it via the Visual Studio Installer: Individual components → search "Clang" → select the C++
> Clang Compiler for Windows component.

## Developing for other platforms? We've got you covered too

Windows ARM64 is the new addition, but `cuda-conan` isn't a one-platform trick. The same recipes support Linux on
both x86_64 and armv8, and have been tested on Jetson devices running JetPack 7.2 with CUDA 13.2 — so if your CUDA
workloads are headed for embedded or edge deployments rather than a Windows laptop, the same requirements and
workflow shown above apply there too.

The samples go beyond `cuda-samples` and `llama.cpp` as well: `cuda-conan` also ships recipes for other heavily
requested CUDA-accelerated libraries, including `libtorch` and `onnxruntime`, so you can pull in the frameworks
powering most AI workloads today without building them yourself.

## Where things stand today

This is a fast-moving space, so a couple of things to keep in mind:

- CUDA support at runtime can only be verified on actual NVIDIA-powered ARM64 hardware — the ARM64 binaries
  themselves will run on any Windows on ARM device.
- Right now, `cuda-toolkit` 13.4 preview is the only package available. Other libraries, like cuDNN, will follow
  as NVIDIA makes them publicly available for this platform.

## Try it out

The CUDA Toolkit landing on Windows ARM64, right as NVIDIA RTX Spark brings capable silicon to ARM64 PCs, is a
genuinely exciting moment for GPU developers — and with Conan, adopting it doesn't require reworking your build.
Two lines in your `conanfile.py`, and you're building for a whole new class of device.

Clone [`cuda-conan`](https://github.com/conan-io/cuda-conan), try the samples, and let us know how it goes:

- [Repository Readme](https://github.com/conan-io/cuda-conan/) 
- [Building CUDA-enabled applications for Windows 11 on ARM (NVIDIA RTX Spark)](https://github.com/conan-io/cuda-conan/blob/main/docs/building-for-windows-on-arm.md)
- [Report issues or share feedback](https://github.com/conan-io/cuda-conan)
- [Roadmap discussion — see what's coming next](https://github.com/conan-io/cuda-conan/discussions/2)

Happy coding!

*This post was written with AI assistance and reviewed by humans.*


