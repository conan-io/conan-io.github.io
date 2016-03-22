---
layout: post
comments: true
# other options
---

This is the short story of the 0.7.X conan releases, in which we had to launch several minor versions to fix unexpected problems related to CMake and the libstdc++ ABI incompatibility, though the lessons learnt might be useful for any C and C++ developer, so let's try to summarize them in this post.

From the beginning, conan has tried to be as compatible as possible with not bleeding-edge systems, because we know that in many corporate environments there are some restrictions and tend to attach to old distributions and tools. So conan started for its cmake generator (it support others as Visual or XCode) with the typical CMake 2.8 syntax for conditionals:

{% highlight cmake %}

macro(CONAN_CHECK_COMPILER)
    if( ("${CONAN_COMPILER}" STREQUAL "Visual Studio" AND NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC") OR

{% endhighlight %}

In old cmake, undefined variables were evaluated to empty strings, so the above code worked fine. But as soon as our users started to use more modern versions of CMake, the [CMake#CMP0054](https://cmake.org/cmake/help/v3.1/policy/CMP0054.html#policy:CMP0054) policy for CMake>3.1 states that the variables inside strings will not be dereferenced, which affect most of the above string, even the MSVC one that is a cmake variable.

The problem is that if using the new approach, cmake commands fail when such variable is not defined, due to an incorrect number of parameters, so existence of the variables must be checked in advance:

{% highlight cmake %}

macro(CONAN_CHECK_COMPILER)
    if(NOT DEFINED CONAN_COMPILER)
        message(STATUS "WARN: CONAN_COMPILER variable not set, please make sure yourself that "
                       "your compiler and version matches your declared settings")
        return()
    endif()

    if( (CONAN_COMPILER STREQUAL "Visual Studio" AND NOT CMAKE_CXX_COMPILER_ID MATCHES MSVC) OR
    
{% endhighlight %}

Here, we did another mistake, can you spot it in the above code? Yes, the ``return()`` from CMake macros, behaves different from the ``return()`` inside a function, it returns from the caller, considering that macros are not called but rather an inline expansion. The solution was obviously to use functions instead of macros.

Also, the C projects (which can be defined in the CMake project declaration as ``project(MyProject C)`` ), were another corner case that we didn’t consider at first, which made the above code to break, as CMAKE_CXX_COMPILER_ID was not defined either, and instead ``CMAKE_C_COMPILER_ID`` should be checked. Also, some checks had to be introduced for ``CMAKE_CXX_FLAGS_RELEASE`` and other similar variables.

<h2 class="section-heading">But why all these compiler checks?</h2>

Some reader might wondered why we need all these compiler checks, as this is something the user typically manages, as when specifying a generator in cmake:

{% highlight bash %}

cmake -G “Visual Studio 14 Win64”

{% endhighlight %}

Or by defining CC, CXX environment variables, or just by installing a certain version of a the gcc compiler in their system.

The problem is the ABI incompatibility between different compiler versions, which mean that a library compiled with Visual Studio 14, might not be linkable from Visual Studio 12, or one compiled with gcc 4.8, might not be linkable from gcc 5.2. So, in conan, the user specifies their setup (OS, compiler, compiler version, architecture, build type...), in order to retrieve if possible compatible pre-built binaries for their dependencies. Also package creators specify their setup and build and upload their packages in a similar way.

But what happens if a user specify usage of a certain compiler version, but actually the installed and used one is different? For package consumers that would typically produce linking errors, but for package creators that would mean that they could affect many people with incompatible builds.

So introducing a check in the build system that compares the settings used to install dependencies against the actual build settings seems a sane thing.

<h2 class="section-heading">And the checks proved useful</h2>


These kind of checks are typically useless, like assertions in code, until they raise. We realized that in some contexts, specifically when users were building with their own tools (as opposed to using the conan build command), the compiler being used by conan was not defined and nothing was being checked.

This soon became notorious in CI environments like travis-ci, that uses quite old Ubuntu 12.04 machines, with default compiler gcc 4.6. It is typical that travis users install more modern compilers as part of the setup procedure, but depending on it, it was possible that conan only auto-detected the system gcc 4.6, instead of the recently installed one.

So we found projects <b>building executables with gcc 5.2 linking against Boost libraries compiled with gcc 4.6. And it worked and run properly!</b>
But we knew this was probably not the user’s intention, and that actually Boost packages built with gcc 5.2 were most likely preferred. So the compiler checks easily allowed to spot this compiler version incompatibility and to fix the setup to properly point to the correct version.

But then… surprise! This was a typical output, when linking against Boost built with gcc 5.2.:

{% highlight bash %}

/home/travis/.conan/data/Boost/1.60.0/lasote/stable/package/ebdc9c0c0164b54c29125127c75297f6607946c5/lib/libboost_log.so: undefined reference to `std::invalid_argument::invalid_argument(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)@GLIBCXX_3.4.21'
/home/travis/.conan/data/Boost/1.60.0/lasote/stable/package/ebdc9c0c0164b54c29125127c75297f6607946c5/lib/libboost_log.so: undefined reference to `std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::find(char const*, unsigned long, unsigned long) const@GLIBCXX_3.4.21'
/home/travis/.conan/data/Boost/1.60.0/lasote/stable/package/ebdc9c0c0164b54c29125127c75297f6607946c5/lib/libboost_log.so: undefined reference to `std::runtime_error::runtime_error(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)@GLIBCXX_3.4.21'
/home/travis/.conan/data/Boost/1.60.0/lasote/stable/package/ebdc9c0c0164b54c29125127c75297f6607946c5/lib/libboost_filesystem.so: undefined reference to `std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::rfind(char, unsigned long) const@GLIBCXX_3.4.21'

WHAT!!?? We were able to link and run using gcc 5.2 against Boost with gcc 4.6, but we get linking errors against Boost built with gcc 5.2?

<h2 class="section-heading">Libstdc++ ABI incompatibility</h2>


Yes, we already knew it, that from gcc 5.1 there were two different libstdc++ implementations, supposedly being the default one the most modern one, i.e. the C++11 one (let's call it ``libstdc++11``). Is this true? <b>The answer: not always, it depends on your machine and OS.</b> 

It turns out that to build Boost in travis-ci we are using [conan-package-tools](https://github.com/conan-io/conan-package-tools), which use docker to manage different compiler versions easily. Such docker images are based on modern Ubuntu distros like Xenial Xerus (15.04), with a default gcc 5.2 compiler and libstdc++11 by default. So those packages were using the modern libstdc++ ABI.

But most travis-ci users will not use docker to build their projects. They will just upgrade their compiler to gcc 5.2. But travis-ci machines are old Ubuntu 12.04 distributions, so upgrading them to gcc 5.2, do not upgrade by default the libstdc++. In fact, such upgrade is very difficult, as many programs depend on libstdc++, so the system one cannot be upgraded without a major system upgrade. It could in theory be possible to download a separate copy of a modern libstdc++ and link against it, but seems a bit complex and not something that travis-ci users were doing.

<b>Libstc++11 and its new ABI will be the default for gcc>5.1 in modern distributions, but not for old distros, even if upgrading the gcc compiler.</b>

<h2 class="section-heading">Our solution</h2>

So what could be done? First of all, we have added a new setting to gcc and clang compiler families, that can take several values:

{% highlight yaml %}

os: [Windows, Linux, Macos, Android, iOS]
arch: [x86, x86_64, armv6, armv7, armv7hf, armv8]
compiler:
    gcc:
        version: ["4.4", "4.5", "4.6", "4.7", "4.8", "4.9", "5.1", "5.2", "5.3"]
        libcxx: [libstdc++, libstdc++11]
    Visual Studio:
        runtime: [MD, MT, MTd, MDd]
        version: ["8", "9", "10", "11", "12", "14"]
    clang:
        version: ["3.3", "3.4", "3.5", "3.6", "3.7"]
        libcxx: [libstdc++, libstdc++11, libc++]
    apple-clang:
        version: ["5.0", "5.1", "6.0", "6.1", "7.0"]
        libcxx: [libstdc++, libc++]

build_type: [None, Debug, Release]

{% endhighlight %}

That setting is then managed as the other settings, so the user can write:

{% highlight bash %}

conan install -s compiler=gcc -s compiler.version=5.3 -s compiler.libcxx=libstdc++11

{% endhighlight %}

And it will aim for a binary package linked against the new ABI libstdc++.

In the case of cmake, it is translated (just an excerpt) to a variable that is checked to define the compiler flag ``_GLIBCXX_USE_CXX11_ABI``

{% highlight cmake %}

if(CONAN_LIBCXX STREQUAL "libstdc++11")
    add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)
elseif(CONAN_LIBCXX STREQUAL "libstdc++")
    add_definitions(-D_GLIBCXX_USE_CXX11_ABI=0)
endif()

{% endhighlight %}

It can be seen that Visual Studio does not have this setting, but instead the runtime, which in essence solves the same problem. It could be argued that C projects do not link against libcxx, and that is true, so we decided that the most conceptually correct approach for C projects would be to remove that settings, so they do not depend on it, which can be done:

{% highlight python %}

def config(self):
    del self.settings.compiler.libcxx

{% endhighlight %}

Migrations are hard. Augmenting cmake support from cmake 2.8 to more modern 3.4, and also dealing with modern gcc>5.1 incompatibilities has meant a lot of work done in latest 0.8 conan release, but we are confident that conan will keep improving for one main reason: all of the above has been detected and reported by active users, building their projects using conan, and we have received tons of help, feedback and contributions in order to solve these issues. 

Special thanks go to [@mcraveiro](https://github.com/mcraveiro), [@tyroxx](https://github.com/tyroxx), [@Manu343726](https://github.com/Manu343726), [@nathanaeljones](https://github.com/nathanaeljones), and of course to all contributors of conan! (tip, clone the repo and “git shortlog -sne” ;) )

