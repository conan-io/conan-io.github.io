---
layout: post
comments: true
# other options
---

This post explains how to setup a development environment for C and C++ projects
using Clang as compiler, CMake as build system, CLion as IDE and Conan
as package manager. The name 4 Cs is cool, but not my idea, it has been
coined by well known C++ blogger [Arne Metz](https://twitter.com/arne_mertz), author
of the great [Simplify C++ blog](http://arne-mertz.de/)

Though Clang has some support in Windows, its usage there is still low compared with MSVC,
and Apple-Clang is the default on OSX, so it has not special difficulties. This post
will use Ubuntu 14.04. As example, we will develop a simple application using the
well known [POCO](http://pocoproject.org/) and [Boost](http://www.boost.org/) libraries.


<h2 class="section-heading">Setting up Clang C/C++ compiler</h2>

The default compiler in Ubuntu is GNU/gcc, so we have to install first Clang:

{% highlight bash %}

$ sudo apt-get install clang-3.6

{% endhighlight %}

Installed this way, clang will not add itself to the path. It is true that
setting environment variables CC and CXX is enough for most use cases. But
for others, as building boost, it is much simpler if clang is in the path,
otherwise editing .bjam files might be necessary. Currently, the conan package for boost,
does not do that, so it requires clang to be in the path. Lets add a couple of links
(most likely we can also use other ways as update-alternatives):

{% highlight bash %}

$ sudo ln -s /usr/bin/clang-3.6 /usr/local/bin/clang
$ sudo ln -s /usr/bin/clang++-3.6 /usr/local/bin/clang++
$ clang --version
$ clang++ --version

{% endhighlight %}


<h2 class="section-heading">Setting up latest CMake (meta) build system</h2>

The default CMake version bundled with Ubuntu 14 is still 2.8.12, which is really old.
CMake current version is 3.5 at the time of this writing, so lets install it. Go to
[CMake downloads](https://cmake.org/download/) and get it. In this case, the tar.gz
was retrieved and installed, prepending the ``bin`` subfolder to the path, so it gets
higher priority. I did this way because I have to keep CMake 2.8.12 as default, but
it is easy to add it permanently to the path.


{% highlight bash %}

$ export PATH=/home/user/cmake-3.5/bin:$PATH
$ cmake --version

{% endhighlight %}

We will be using CMake "Unix Makefiles" generators. Though it is possible to pass
the compilers to CMake in the command line, I find it error prone, so I usually
prefer to set the CC and CXX environment variables:

{% highlight bash %}

$ export CC=clang
$ export CXX=clang++

{% endhighlight %}

This is also convenient for later CLion usage using this compiler.

<h2 class="section-heading">Setting up Conan C/C++ package manager</h2>

To install conan in your computer, the easiest way is with Python package:

{% highlight bash %}

$ sudo pip install conan

{% endhighlight %}

You might need to use **sudo** if you are installing it globally, not necessary
if using a virtualenv.


<h2 class="section-heading">Set up the project</h2>

{% highlight bash %}

$ git clone https://github.com/memsharded/four-c-example.git
$ cd four-c-example

{% endhighlight %}

Inside the folder there is a simple ``conanfile.txt`` defining our dependencies:

{% highlight text %}

[requires]
Poco/1.7.2@lasote/stable
Boost/1.60.0@lasote/stable

[generators]
cmake

{% endhighlight %}

Let's install the dependencies. We will use a temporary folder called ``.conan``
(you can use any name), as the CLion editor uses an external build folder. Using
a known and close folder for conan temporary files allows easy management of dependencies:

{% highlight bash %}

$ mkdir .conan && cd .conan
$ conan install .. -s compiler=clang -s compiler.version=3.6 -s compiler.libcxx=libstdc++ --build=missing

{% endhighlight %}

Note the final ``--build=missing``. Most packages in conan provide binaries for the mainstream compilers,
MSVC in Win, GNU/gcc in Linux and Apple-Clang in OSX. So, it is expected that pre-compiled binaries
for CLang in Linux will not be available, so we have to tell conan to build them from sources.
Go and grab a coffee, it will build Poco, Boost and some other libs!

This install step will generate 2 files: ``conanbuildinfo.cmake`` with some CMake variables
defined inside, as include paths and library names and ``conaninfo.txt`` which stores your current
configuration. You can use in parallel many configurations if you want, just place each one in a
separate folder.

You can check the installed dependencies with:

{% highlight bash %}

$ conan info
PROJECT
    Requires:
        Boost/1.60.0@lasote/stable
        Poco/1.7.2@lasote/stable
Boost/1.60.0@lasote/stable
    Remote: conan.io=https://server.conan.io
    URL: https://github.com/lasote/conan-boost
    License: Boost Software License - Version 1.0. http://www.boost.org/LICENSE_1_0.txt
    Updates: You have the latest version (conan.io)
    Required by:
        PROJECT
    Requires:
        zlib/1.2.8@lasote/stable
        bzip2/1.0.6@lasote/stable

{% endhighlight %}


<h2 class="section-heading">Developing with CLion</h2>

Now open CLion. As we already have defined CC and CXX environment variables, launching CLion in
our terminal will automatically use CLang as default compiler.

{% highlight bash %}

$ cd ..
$ /path/to/clion/bin/clion.sh

{% endhighlight %}

If you go to File->Settings, you could see the compiler is Clang:

![CLion Settings]({{ site.url }}/assets/clion_settings.png)

It might be possible to use the CMake variables ``-D CMAKE_C_COMPILER=clang-3.6 -D CMAKE_CXX_COMPILER=clang++-3.6``
defined in the CLion IDE, to define the compiler. Note that typically a CMake cache clean&restart might be necessary.

From CLion CMakeLists.txt project file, we can load the generated ``conanbuildinfo.cmake``.

{% highlight cmake %}

cmake_minimum_required(VERSION 2.8)
project(four_c)

include(.conan/conanbuildinfo.cmake)

conan_basic_setup()

add_compile_options(-std=c++11)
add_executable(timer timer.cpp)
target_link_libraries(timer ${CONAN_LIBS})

{% endhighlight %}

CLion will be able to autocomplete from both Poco and Boost headers:

![Poco autocomplete]({{ site.url }}/assets/poco_autocomplete.png)

That is all! You can now select in CLion the "timer" target, build it, and run it!

![CLion run]({{ site.url }}/assets/clion_run.png)


<h2 class="section-heading">Conclusions</h2>

Setting up a development environment for C++ with these 4 tools is not complicated.
Basically make sure that CLang is in the path, and that CMake is using it (through
the environment variables CC and CXX) instead of the sytem GNU/gcc compiler.

Also I found more intuitive to launch CLion with those variable defined, so it detects
the CLang compiler and shows it in the Settings dialog. It is possible to use cmake command line
parameters ``-DCMAKE_C_COMPILER=clang-3.6 -DCMAKE_CXX_COMPILER=clang++-3.6`` in the same CLion
Settings dialog, but a File->InvalidateCache/Restart is typically necessary, as CMake cache only
stores the compiler the first invocation (which is automatically done by CLion, before able to set
the command line parameters).

Conan packages (Poco, Boost and their dependencies: Zlib, electric-fence...) have built fine
with Clang, but it is also possible that some other conan packages have not been thoroughly
tested yet with CLang, and they might eventually fail to build. Please contribute in that
case, submitting an issue to the package repository.
