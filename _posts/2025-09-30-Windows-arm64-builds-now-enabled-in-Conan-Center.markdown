---
layout: post
comments: false
title: "Windows ARM64 builds now enabled in Conan Center"
description: "ARM-powered devices continue to gain significant traction across a number of platforms"
meta_title: "What is in your dependencies updates?"
categories: [armv8, arm64, windows, conan]
---

ARM-powered devices continue to gain significant traction across a number of platforms. Last year marked a pivotal 
moment with Microsoft's release of new Surface products as well as laptops from multiple vendors featuring Snapdragon X 
CPUs. This commitment is further reinforced by Qualcomm's recent announcement of the Snapdragon X2 Elite, further 
enabling developer workflows on native devices. 

Conan has been platform-agnostic since its inception, already enabling teams to target various operating systems and CPU
architectures using the same recipes and commands (e.g., macOS Apple Silicon, Android, iOS, FreeBSD, …). Windows ARM64 
is no exception.

That's why we're thrilled to announce improved support for Windows ARM64 in Conan Center recipes! We've been working 
hard to streamline the development experience for this platform, and the latest improvements are now rolling out.

## What's New and Improved?

**Native Installer and Self-Contained Executable:** While Conan is typically installed by developers locally using pip, 
we also provide standalone installers that don’t require a Python distribution. Starting with the 
**Conan 2.21.0 release**, we are now providing a [native ARM64 Windows installer](https://github.com/conan-io/conan/releases/download/2.21.0/conan-2.21.0-windows-arm64-installer.exe) as well as [a self-contained executable](https://github.com/conan-io/conan/releases/download/2.21.0/conan-2.21.0-windows-arm64.zip) 
for Conan.

**Validated recipes for native development:** We understand that a package manager is only as good as the packages it 
provides. We've dedicated significant effort to validating a subset of the most popular Conan Center recipes to ensure 
they build and run natively on Windows ARM64. This includes over 350+ recipes in Conan Center (and counting!), including 
the most popular ones such as Boost, OpenCV, Qt, ffmpeg, Protocol buffers, gRPC, and many more! 

**Improved fallbacks for build tools that don’t yet support arm64:** Some recipes require build tools that currently only 
run with x86_64 emulation, like Autotools on msys2 and strawberry perl. We have improved the recipes so that compatible
binaries are transparently fetched from Conan Center without manual tweaks.

**Availability of Windows ARM64 binaries in Conan Center:** To further simplify your development workflow, Conan Center 
CI will now actively build and publish Windows ARM64 binaries for already validated recipes. This means that for a 
growing list of libraries, you won't need to build from source on your ARM64 machine if your profile matches the 
available binaries, saving you time and resources. This is an ongoing process and we aim to publish Windows arm64 
binaries for every recipe that supports it. You can check if binaries are available in the Conan Center package 
explorer, example: https://conan.io/center/recipes/fmt?version=

### Your Feedback Fuels Our Progress!

This is an ongoing effort, and your feedback is invaluable. As you begin to develop on Windows ARM64 with Conan, we 
strongly encourage you to share your experiences, report any issues, and suggest additional recipes you'd like to see 
natively supported. Your contributions help us prioritize and expand our ARM64 coverage, ensuring Conan Center remains 
a powerful resource for all developers.

## Getting started with Conan for native Arm64 Windows Development

To get started with native Windows ARM64 development, you'll need the right tools. Here's a quick guide to the essential
Visual Studio components:

### Conan

Download the latest 
[installer](https://github.com/conan-io/conan/releases/download/2.21.0/conan-2.21.0-windows-arm64-installer.exe) 
(does *NOT* require a separate Python installation) and follow the instructions in the installation wizard.

### CMake

Now you will need CMake, which you can download from the official website(https://cmake.org/download/). Don’t forget to 
add it to the system PATH.

The current release at time of writing is 4.1.1 
(download [installer](https://github.com/Kitware/CMake/releases/download/v4.1.1/cmake-4.1.1-windows-arm64.msi)).

### Visual Studio

* Install Visual Studio 2022 (Version 17.4 or later): This is the first version of Visual Studio that offers native ARM64 
support. You can download it from the official [Visual Studio website](https://visualstudio.microsoft.com/downloads/). 
Please ensure you are using the correct license.
* Select the "Desktop development with C++" Workload: During the Visual Studio installation process, ensure you select this workload.

<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-09-30/visual-studio-desktop-development.jpg"
       alt="conan report diff web interface"/>
</div>
<br>

That’s it! Now let’s get this to work.
In a terminal window, first run the following command:

{% highlight bash %}
$ conan profile detect
{% endhighlight %}

The result should be:

{% highlight bash %}
Detected profile:
[settings]
arch=armv8
build_type=Release
compiler=msvc
compiler.cppstd=17
compiler.runtime=dynamic
compiler.version=194
os=Windows

{% endhighlight %}

Ensure ``arch=armv8``. If you get ``x86_64``, you may be running a non-native installation of Python or Conan. This still 
works, but please ensure you modify the profile to reflect the ``arm=armv8`` architecture.

## Build a sample project

We can now use Conan as we are already used to natively on any platform. For example one of the toy projects in the 
examples repo:

{% highlight bash %}
git clone https://github.com/conan-io/examples2.git
cd examples2/examples/libraries/raylib/introduction
conan install . -s compiler.cppstd=17
cmake --preset conan-default
cmake --build --preset conan-release
.\build\Release\runner_game.exe
{% endhighlight %}

<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-09-30/raylib-image-example.png"
       alt="conan report diff web interface"/>
</div>
<br>

Dependencies will be downloaded from Conan Center and the app will build and run natively on Windows ARM64. 

Happy coding!