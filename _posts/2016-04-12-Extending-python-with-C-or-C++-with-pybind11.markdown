---
layout: post
comments: true
# other options
---

C, C++ and Python are my favourites languages. You get from C and C++ the performance (with great difference of course between them), and from Python the simplicity and speed of development. Mixing them can get the best of both worlds into our development environment.

The relation between them can be in both directions:

- Extending python is the process of creating python extensions programmed in C or C++ in the form of shared libraries (.pyd in win, .so in nix) that can be imported and executed from the python environment. The binary native extensions would typically contain the performance critical code as well as functionality that was previously implemented in C/C++ libraries that is wanted to be exposed to the python environment.

- Embedding python is the process of creating a native application, developed in C or C++ that can execute python code, using the python interpreter.

Both tasks can be achieved at "low level" using for example the CPython : [Python/C API](https://docs.python.org/2/extending/), but there exist many [third party](https://wiki.python.org/moin/IntegratingPythonWithOtherLanguages) tools that try to improve over this process.

Boost is probably the most acknowledged C++ library in the world, and it has been pushing the frontiers of C++ for many years. It features a Boost.Python library that is intended to provide high level C++ abstractions for both extending and embedding python. However, from my point of view it suffers some drawbacks, an important one being difficult to build (it is not header only, as many other boost libs). It uses the b2 boost build system, which I am not very used to, and it is not simple to use another one. Moreover, it seems its activity and maintenance could be also larger.


<h2>Entering pybind11</h2>

I usually would attach to Boost, but among the other tools, it is noticeable the [pybind11](https://github.com/pybind/pybind11) one. It almost gathers 1 thousand stars in github, really active project and updated to the latest C++ compilers and features. Also, it is TMP based library, header only, which greatly increases usability. You can read some [benchmarks in the docs](http://pybind11.readthedocs.org/en/latest/benchmark.html)

<h2>Getting started</h2> 

Getting started with pybind11 is really simple. I have created a conan package, but as it is header only, it should be quite easy to use it just cloning the sources and pointing to the include directory.

To build the first application, get the example:

{% highlight bash %}

$ git clone https://github.com/memsharded/pybind11-example.git
$ cd pybind11-example

{% endhighlight %}

There is a simple ``conanfile.txt`` that tells conan to retrieve the conan pybind11 package and generate a cmake file for our convenience:

{% highlight conf %}

[requires]
pybind11/1.4@memsharded/stable

[generators]
cmake

{% endhighlight %}


<h2>Hello world Python/C++ App</h2> 

We are just using the code provided in pybind11 help, a simple integer addition plugin, in a file called **example.cpp**:

{% highlight cpp %}

#include <pybind11/pybind11.h>

int add(int i, int j) {
    return i + j;
}

namespace py = pybind11;

PYBIND11_PLUGIN(example) {
    py::module m("example", "pybind11 example plugin");
    m.def("add", &add, "A function which adds two numbers");
    return m.ptr();
}

{% endhighlight %}


We will be using cmake for building the extension, with the provided **CMakeLists.txt**:

{% highlight cmake %}

cmake_minimum_required(VERSION 2.8)

project(example)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
include_directories(SYSTEM ${CONAN_INCLUDE_DIRS})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

... 

{% endhighlight %}

The only change made to the original **CMakeLists.txt** is to define the include directories for the pybind11 headers and define the output directory as the current one, so our extension is in the current folder.

We will use Visual Studio 14 to build the extension. Note that even the official VS for python is an (old) VS2008, it is possible to create such extensions with more modern compilers. The parameters must match your compiler and python installation. Note that the extension architecture must match your python one, so if you have python 32 bits, use "Visual Studio XX" and if you have python 64 bits, you may need "Visual Studio XX Win64".

{% highlight bash %}

$ mkdir build && cd build
# Retrieve the pybind package
$ conan install ..
$ cmake .. -G "Visual Studio 14" -DPYTHON_INCLUDE_DIR="C:/Python27/include" -DPYTHON_LIBRARY="C:/Python27/libs/python27.lib"
$ cmake --build . --config Release

{% endhighlight %}

In linux, you could use the following commands to build it, and it may automatically find python, but please check the cmake output to ensure that it is finding your desired python distribution.

{% highlight bash %}

$ cmake .. -DCMAKE_BUILD_TYPE=Release
$ cmake --build .

{% endhighlight %}


And that's it, we already have the extension ready to be used from python:

{% highlight bash %}

$ python
>>> import example
>>> example.add(2, 3)
5L
{% endhighlight %}

<h2>Conclusion</h2> 

I have found pybind11 to be elegant, very simple to use, efficient, and also very important, I also like its syntax to define the extensions. To summarize, a very good job. Its only drawback could be that it seems not to be the tool for embedding python (I might be wrong). I also feel confident about the project being very active and supported by the community, so in my opinion this is probably the best choice for the task of extending python.

I will by talking about these topics in [Accu conference](http://accu.org/index.php/conferences/accu_conference_2016) in Bristol within a few days, maybe [see you there?](http://accu.org/index.php/conferences/accu_conference_2016/accu2016_sessions#Extending_and_Wrapping_C_and_C++_with_Python) :) You can also [follow me on twitter](https://twitter.com/diegorlosada) for tweets about C/C++/Python and programming in general
