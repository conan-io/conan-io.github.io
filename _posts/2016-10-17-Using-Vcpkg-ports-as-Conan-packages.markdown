---
layout: post
comments: true
title: "Using Vcpkg ports as Conan packages"
---

A few days ago, during the CppCon C++ conference, Microsoft presented [**Vcpkg**](https://github.com/Microsoft/vcpkg). It helps you get and build from sources C and C++  open source libraries on Windows for Microsoft Visual Studio. It is a good initiative, it has been well received by the community, and several users have already collaborated making pull requests with new “ports” (the way vcpkg calls the recipes, or formulas).

Vcpkg is based on CMake scripts to perform all the retrieve and build tasks, delegating to an executable called “vcpkg.exe” the invocation to cmake and some other features.

Conan had already implemented the system_requirements() to handle installation of system packages, like apt-get or brew, within conan recipes that needed those system dependencies. So we started to analyze if there was any equivalent synergy between vcpkg and conan, and conan could avoid creating or re-writing packages for those libraries already existing in vcpkg.


Using vcpkg libraries from conan
------------------------------------

The "port conan recipe" names looks like "portname/libversion@lasote/vcpkg", e.g. **boost/1.61.0@lasote/vcpkg**

You can search [vcpkg packages in conan.io](https://www.conan.io/search?q=vcpkg)

Use them like regular conan recipes, in a **conanfile.txt** or **conanfile.py**. [Take a look to the getting started guide](http://docs.conan.io/en/latest/getting_started.html).

This is an example using the **boost** library, create the following source code files in a folder:

**Conanfile.txt**
{% highlight txt %}
[requires]
boost/1.61.0@lasote/vcpkg

[generators]
cmake

[imports]
bin, *.dll -> ./bin
lib, *.dylib* -> ./bin

{% endhighlight %}


**regex.cpp**
{% highlight cpp %}

#include <boost/regex.hpp>
#include <iostream>
#include <string>

int main(){
    std::string line = "Subject: Regex working!";
    boost::regex pat( "^Subject: (Re: |Aw: )*(.*)" );

    boost::smatch matches;
    if (boost::regex_match(line, matches, pat))
        std::cout << matches[2] << std::endl;
}

{% endhighlight %}


**CMakeLists.txt**
{% highlight cmake %}

project(MyHello)
cmake_minimum_required(VERSION 3.0)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)

conan_basic_setup()
add_executable(regex regex.cpp)
target_link_libraries(regex ${CONAN_LIBS})

{% endhighlight %}

Create a new build folder in your project and run conan install. It will retrieve the boost recipe from **conan.io** and the pre-built binary package. In case that there is no binary package for your settings it will invoke the vcpkg cmake scripts embedded in the conan recipe and will generate a new conan package binary:


{% highlight bash %}

$ mkdir build && cd build
$ conan install .. --build missing

{% endhighlight %}

This assumes that your default setting is Visual Studio 14, if you have other version, you can specify it in the install arguments:

{% highlight bash %}

$ conan install .. --build missing -s compiler="Visual Studio" -s compiler.version=12

{% endhighlight %}


And invoke cmake with the correct generator for your Visual Studio version:

{% highlight bash %}
$ cmake ..  -G "Visual Studio 14 Win64"
$ cmake --build . --config Release
{% endhighlight %}

Go to the “bin” folder and run the executable:

{% highlight bash %}
$ cd bin
$ regex.exe
{% endhighlight %}


How we did it? Automatic creation of conan packages for vcpkg libraries
-----------------------------------------------------------------------

In the [“lasote” Vckpg fork](https://github.com/lasote/vcpkg) there is a “conanizer” folder.
It contains a **run.py** python script that reads all the available ports. For each one, it generate from a basic template a new **conanfile.py** conan package recipe that will invoke the CMake scripts and build package binaries for different configurations (VS10, 12, 14, both Debug and Release versions).

Vcpkg CMake scripts only need two parameters:

- **Port** : The port name to be compiled
- **Target triplet**: Basically it defines the architecture, in conan is a setting, so we can generate a triplet name from the conan arch setting.

Vcpkg packages the libraries following the same layout (standard) as conan, so in the “package” method we can just copy the folders:

- **bin** => dll’s
- **lib** => libraries to link with
- **include** => library headers
- **tools** => executables

Finally we have created an appveyor.yml to help to auto-generate and upload to conan.io all package recipes and pre-built binaries every time we push our fork or with any tagged release.


Conan benefits
--------------

Using conan for vcpkg packages has some advantages to using only vpckg:

- **Library versioning**: [Vcpkg only keeps one version for each port/vcpkg instance](https://github.com/Microsoft/vcpkg/blob/master/docs/FAQ.md#how-do-i-use-different-versions-of-a-library-on-one-machine), if a new version of a library is released it will overwrite your previous dependency. This is a big issue for C/C++ projects where the dependencies often should keep stabilized. Users seldom want their Boost or OpenSSL version replaced automatically with the latest one. We read the CONTROL file where library version is declared and we use the version to generate a different conan recipe for different library versions, e.g. ``boost/1.61.0@lasote/vcpkg``

**TODO**: *conanizer* doesn't manage the ports recursive dependencies correctly yet. We could improve it by defining conan requires to another "port" package. This way we could handle situations like library A depends on B (A -> B) and B version is updated in vcpkg repository to B'. Then there will be two binary packages available in conan.io, (A -> B) and (A -> B'). Users can use normally the (A -> B) version by requiring A, or even override the B' to B in their projects, using the old binary package.

- **Different Visual Studio versions**: Vcpkg currently only support Visual Studio 14 compilations. We perform some adjustments to compile any port with any other Visual Studio version (as long as the library source code compiles with previous Visual Studio versions, it is possible that they don’t if they use the very latest C++ features only provided by VS 2015). 
- **Different debug/release packages**: We separate build type debug and release in two different binary packages, so you can use the setting “build_type” to install only the binaries that you want.
- **Combine ports with regular conan packages**: Use these port packages as normal conan packages, link against others etc.
- **Automatic linking**: Conan detects and declares the built libraries, so you can use for example CMake generator and link with ${CONAN_LIBS} automatically.
- **Binary caching**: Conan can catch locally or in any conan server the built packages. We know how costly is to compile big C/C++projects, so you don’t need to rebuild your dependencies every time you change your environment. The distributed server architecture, like git remotes, offers multiple possibilities, like private in-house servers with optional read access to public repositories, etc.
- **Use your own in-house conan server**, with MIT license and very simple to run and maintain, to host package recipes and binaries and share them with your development teams.
- **Build from source**: As in Vcpkg, you can keep building packages from source if you don’t want to use pre-built binaries from conan.io. Invoke conan install with --build option. It will invoke the library CMake port scripts to rebuild the library.
- **Use any conan generator**: Use ANY conan generator to reuse the vcpkg port, CMake, CLion, Xcode, Autotools, YCM, Premake...
- **Many other conan benefits**: Conan offers many other advanced package manager features, as conflict resolution, dependency overriding etc.



