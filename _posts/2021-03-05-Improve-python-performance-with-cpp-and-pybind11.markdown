---
layout: post
comments: false
title: "Improve the Python performance using C++ and pybind11"
---

Python is a general-purpose programming language that provides the user with tons of capabilities in very straightforward syntax.
Moreover, all the ecosystem of libraries around its standard library offers innumerable possibilities to develop any kind of piece
of software one can imagine. However, when it comes to processing big amounts of data the language is not so performant and relies
on third-party libraries that actually run C or C++ code underneath like ``tensorflow``, ``numpy`` or ``pandas`` to name a few.

The combination of both programming languages can provide the best of both worlds: A friendly syntax in the frontend and a performant behavior in the backend.

Probably you are already familiar with bindings in different languages and the different ways to achieve that. Today we will be talking about the ``pybind11`` C++ library with some simple but illustrative examples on this matter.

# Introduction to pybind11

Pybind11 is a C++ header-only and easy to use library that provides Python binding of C++ code. While there were already libraries like ``boost.python`` that also cover this purpose, ``pybind11`` gets rid of a lot of the boilerplate binding code and leverages the features of C++11 onwards standards.

As usual in this kind of libraries, it exposes C++ types in Python and the other way around. So if you are mainly developing in Python, you can benefit from the speed and low-level control of C++, and if you have an application or library in C++ you can expose it with a nice-looking Python API.

**********add more intro********

# The Fibonacci example

To showcase the performance of both programming languages, let's use a function to calculate the numbers of the Fibonacci sequence. I know this isn't a real issue as recursive operations can be optimized with the usage of caches, but just imagine any other computationally heavy operation instead of this one. We will calculate the number of the position 36 (with the result of 24157817) in pure Python, C++ and then Python with C++ module compiled with pybind11.

You can find all the materials here: https://github.com/danimtb/pybind11_fibonacci

## The Python way

Starting with Python, let’s create a simple Fibonacci library called `fibolib`:

```bash
$ mkdir fibolib && cd fibolib
$ vim fibonacci.py
```

*fibonacci.py*
```python
def fib(n):
    if n <= 1:
        return 1
    return fib(n -1) + fib(n - 2)
```

Now let's create a main program file to execute the function above to get the number 36 of the sequence:

```bash
$ cd ..
$ vim main.py
```

**main.py**
```python
from fibolib.fibonacci import fib


if __name__ == "__main__":
    print(fib(36))
```

Now if we execute the program measuring the time we got the following result:

```
$ ptime python main.py

=== python main.py  ===
24157817

Execution time: 5.881 s
```

That took some time to calculate it. Note that this time will vary significantly depending on the computer. I encourage you
to try it and check the differences.

**Note:** ``ptime`` is a tool to measure time in Windows similar to the ``time`` one in unix systems. You can install it using Chocolatey ``choco install ptime``.

## The C++ way

In the same sense, let’s mimic the same python ``fibolib`` library but this time using C++ code:

```bash
$ cd fibolib
$ create fibonacci.h
```

*fibonacci.h*
```cpp
#include <cstdint>

uint64_t fib(uint64_t n) {
    if (n <= 1) {
        return 1
    }
    return fib(n -1) + fib(n - 2)
}
```

Now we will call this function from the main program and output the result for the position 36:

```
$ cd ..
$ vim main.cpp
```

*main.cpp*
```cpp
#include <iostream>

#include "fibolib/fibonacci.h"


int main() {
    std::cout << fib(36) << std::endl;
}
```

And a very simple *CMakeLists.txt*:

```
cmake_minimum_required(VERSION 3.4)

project(main CXX)

add_executable(main main.cpp)
```

Now if we compile and execute the program measuring the time we got the following result:

```
$ mkdir _build && cd _build
$ cmake .. -G “Visual Studio 15 2019”
…
$ cmake --build . --config Release
...

$ ptime Release/main.exe

=== Release\main.exe  ===
24157817

Execution time: 0.184 s
```

What a boost in performance! As you can see, the time difference with the Python example is very notable. We can deduce that the
increase of speed could be quite relevant when using C++ compiled code.

# Using the pybind11 library

We can bring the power of C++ to the Python world, this time with ``pybind11``. In order to make the C++ a python module, we need to add some binding code. To avoid mixing the binding code with the library one, let’s create a new directory with the stuff inside:

```bash
$ mkdir binding && cd binding
$ vim fibolib.cpp
```

And we will only require a small piece of binding code for our function:

*fibolib.cpp*
```cpp
#include <pybind11/pybind11.h>

#include <fibolib/fibonacci.h>


PYBIND11_MODULE(fibolib, m) {
    m.doc() = "pybind11 fibonacci plugin"; // module docstring

    m.def("fib", &fib, "A function that computes the n number of the Fibonacci sequence");
}
```

You can see that the code it is pretty straightforward. The library provides very convenient macros to expose the C++ code and some
information for the generated Python module. Also, the library is able to analyze the signature of the function and provide the equivalent interface in Python.

## Retrieving the pybind11 library

Now it is time to get the pybind11.

```bash
$ mkdir _build && cd _build
$ vim conanfile.py
```

The *conanfile.py* looks as easy as:

```python
from conans import ConanFile

class FibolibConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    requires = "pybind11/2.5.0"
    generators = "cmake_find_package"
```

Now let's install the library:

```bash
$ conan install ..
...
******************************add more output
```

And include it in a CMake project to build the ``fibolib`` Python module:

*CMakeLists.txt*
```
cmake_minimum_required(VERSION 3.4)
project(binding CXX)

set(CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

find_package(pybind11 REQUIRED)

include_directories(${PROJECT_SOURCE_DIR}/..)

pybind11_add_module(fibolib MODULE fibolib.cpp)
```

As you can see, the library provides vey convenient ``pybind11_add_module()`` macro in CMake that takes care of finding the Python interpreter installation, the headers and the libraries to link with.

***** more info here?

Now let's build the ``fibolib`` module compiling the C++ binding code:

```bash
$ cmake .. -G “Visual Studio 15 2019”
...
$ cmake --build . --config Release
...
```

This will generate the module in the *lib/* folder. In my case, the files of the module are called *fibolib.cp37-win_amd64.pyd*,
*fibolib.exp* and *fibolib.lib*


Now let's use this new module in a new Pythom program called *main_cpp.py*:

```python
from binding._build.lib.fibolib import fib

if __name__ == "__main__":
    print(fib(36))
```

Running this new program gives this result:

```bash
$ ptime python main_cpp.py

=== python main_cpp.py  ===
24157817

Execution time: 0.212 s
```

Not bad!

# Wrap-up

- C++ is superior in performance to Python.
- We can use pydind11 to take advantage of C++ in our Python code.
- pybind11 produces Python compatible modules with a minimal binding code.

Moreover:
- Conan can be used to easily integrate the pydind11 dependency in our project

## Bonus

lru_cache
fibonacci benchmark
c++ constexpr
