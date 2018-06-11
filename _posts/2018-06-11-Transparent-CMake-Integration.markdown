---
layout: post
comments: false
title: "Conan-CMake transparent integration"
---

In Conan 1.4 we have introduced two new Conan generators that allow linking with your dependencies without changing your CMakeList.txt file with any line related to Conan.

First of all, let's review what is a Conan generator and to show the pros and cons of both the classic and new generators.

All the code in the examples below are in this GitHub repository: [https://github.com/lasote/transparent_cmake_examples.git](https://github.com/lasote/transparent_cmake_examples.git)

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-06-11/conan_cmake_blog.png" align="center" width="300"/>
</p>


## Classic CMake integration: "cmake" generator

If you are consuming conan packages in your project, you typically declare a ``conanfile.txt`` file with some dependencies.
In this case, we are building an application that uses ``libcurl`` to check the Github starts from the Conan repository.

(Folder [classic_approach](https://github.com/lasote/transparent_cmake_examples/tree/master/classic_approach) in the repository)


**conanfile.txt**
```conf

[requires]
libcurl/7.52.1@bincrafters/stable

[generators]
cmake

[options]
libcurl:with_openssl=True


```

**CMakeLists.txt**
```cmake
project(myapp)
cmake_minimum_required(VERSION 3.1)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup(TARGETS)

add_executable(myapp main.cpp)
target_link_libraries(myapp CONAN_PKG::libcurl)

```

**main.cpp**
```cpp

#include <stdio.h>
#include <curl/curl.h>

int main(void)
{
  CURL *curl;
  CURLcode res;

  curl_global_init(CURL_GLOBAL_DEFAULT);

  curl = curl_easy_init();
  if(curl) {
    struct curl_slist *list = NULL;
    list = curl_slist_append(list, "user-agent: libcurl");
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, FALSE);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
    curl_easy_setopt(curl, CURLOPT_URL, "https://api.github.com/repos/conan-io/conan/stargazers");
    res = curl_easy_perform(curl);
    if(res != CURLE_OK)
        fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
    curl_easy_cleanup(curl);
  }

  curl_global_cleanup();
  return 0;
}

```

Create a "build" folder and call "conan install":

```bash

$ mkdir build && cd build
$ conan install ..

```


Conan has generated a `conanbuildinfo.cmake` file (corresponding with the “cmake” generator) with all the information about the libcurl
dependency and all the transitive ones, in this case, OpenSSL and ZLib, and some macros we can call to ease the
task of linking with our dependencies.

In our ``CMakeLists.txt`` (shown above) we are including that file and calling `conan_basic_setup()`.

This macro will do several things for us:

- Check if the specified compiler in the conan install matches the one detected by CMake.
- Adjusting the output directories, rpaths configurations, std library, runtime (only Visual Studio), fPIC flag, all according to the specified settings in the conan install command (default profile in this example).
- Prepare transitive targets (modern CMake) and needed variables (global approach) to link with the dependencies.

Any of these automatic adjustments can be [called individually](https://docs.conan.io/en/latest/reference/generators/cmake.html#methods-available-in-conanbuildinfo-cmake)
instead of calling `conan_basic_setup()` so we can control exactly what we want Conan to do for us.

Now we can build the application just calling CMake:


**Linux/Mac**
```bash
$ cmake .. -DCMAKE_BUILD_TYPE=Release
$ cmake --build .
$ ./bin/myapp
# a JSON will be outputted here
```

**Windows**
```bash
$ cmake .. -G “Visual Studio 15 2017 Win64”
$ cmake --build . --config Release
$ ./bin/myapp
# a JSON will be outputted here
```

This approach is pretty useful and the usage is very straightforward, but you need to change your `CMakelists.txt`
file to include the `conanbuildinfo.cmake` file.
Some users prefer to rely on the CMake `find_package()` feature to decouple the build system and the package manager.

## Transparent CMake integration: "cmake_paths" generator

(Folder [cmake_paths](https://github.com/lasote/transparent_cmake_examples/tree/master/cmake_paths) in the repository)

We can adjust our project to use a transparent integration with CMake:

**conanfile.txt** Change the generator to `cmake_paths`

```conf
[requires]
libcurl/7.52.1@bincrafters/stable

[generators]
cmake_paths

[options]
libcurl:with_openssl=True
```


**CMakeLists.txt** Here we are not including the `conanbuildinfo.cmake` file, only calling to find_package:

```cmake
project(myapp)
cmake_minimum_required(VERSION 3.1)

add_executable(myapp main.cpp)
find_package(CURL)
include_directories(${CURL_INCLUDE_DIRS})
target_link_libraries(myapp ${CURL_LIBRARIES})
```

Clean the "build" directory and install again, it will generate the `conan_paths.cmake` file:

```bash
$ rm -rf build && mkdir build && cd build
$ conan install ..
```

Now call CMake including the `conan_paths.cmake` as a toolchain:

**Linux/Mac**:
```bash
$ cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=./conan_paths.cmake
$ cmake --build .
$ ./bin/myapp
# a JSON will be outputted here
```

**Windows**:
```bash
$ cmake .. -G “Visual Studio 15 2017 Win64” -DCMAKE_TOOLCHAIN_FILE=./conan_paths.cmake
$ cmake --build . --config Release
$ ./release/myapp
# a JSON will be outputted here
```

Unfortunately, __it won't work__, many linker errors will occur:

```bash
  ...
  "_sk_value", referenced from:
      _ossl_connect_common in libcurl.a(libcurl_la-openssl.o)
  "_zlibVersion", referenced from:
      _Curl_version_init in libcurl.a(libcurl_la-version.o)
      _curl_version in libcurl.a(libcurl_la-version.o)
      _curl_version_info in libcurl.a(libcurl_la-version.o)
      _Curl_unencode_gzip_write in libcurl.a(libcurl_la-content_encoding.o)
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```


Why? Because even using `find_package(CURL)`, we need to manage the transitive dependencies, OpenSSL and Zlib:

(Folder [cmake_paths_attempt2](https://github.com/lasote/transparent_cmake_examples/tree/master/cmake_paths_attempt2) in the repository)

```cmake
PROJECT(myapp)
cmake_minimum_required(VERSION 3.1)

ADD_EXECUTABLE(myapp main.cpp)

find_package(ZLIB)
find_package(OpenSSL)
find_package(CURL)

include_directories(${ZLIB_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIRS} ${CURL_INCLUDE_DIRS})
target_link_libraries(myapp ${CURL_LIBRARIES} ${OPENSSL_LIBRARIES} ${ZLIB_LIBRARIES})
```

And not less important, we need to make the `target_link_libraries` in the correct order.
So definitely, in this case, the transparent integration is far from ideal, we are losing precious information
from the package manager, like the transitivity and the order of linkage.

If you are not using Windows, the previous example will probably work. If not, you will still see linker errors
because of the `findCURL.cmake` (provided by CMake).

- It is not linking with `Ws2_32`: Remember the CMake findXXX modules are not transitive, so you have to declare ALL
  the dependency tree in your ``CMakeLists.txt`` file.

- It is not propagating the definition `CURL_STATICLIB` needed to link correctly with the static library.

Check the code in the folder [cmake_paths_attempt3_windows](https://github.com/lasote/transparent_cmake_examples/tree/master/cmake_paths_attempt3_windows) of the repository.

We can see that using the CMake provided `findXXX` modules is very far from being ideal because many
information that the package manager already knows is completely lost: Both the transitive dependencies and definitions
are declared in the `package_info` method of the libcurl recipe, but will never be applied if you use the CMake provided findXXX modules.

How could this be improved?


## Transparent CMake integration (2): "cmake_find_package" generator


The ``cmake_find_package`` is a different approach. It will generate one ``find<package_name>.cmake`` for
each dependency from the information that Conan has about the dependency tree.
We can use it with modern CMake target approach. As every target is transitive, libcurl target will
contain the OpenSSL and zlib information too.

(Folder [cmake_find_package](https://github.com/lasote/transparent_cmake_examples/tree/master/cmake_find_package) in the repository)


**conanfile.txt** Change the generator to `cmake_find_package`:
```conf
[requires]
libcurl/7.52.1@bincrafters/stable

[generators]
cmake_find_package

[options]
libcurl:with_openssl=True
libcurl:darwin_ssl=False # Force use openssl in OSX too
```

**CMakeLists.txt** Conan will generate the ``libcurl::libcurl`` target, we only need to modify the ``CMAKE_MODULE_PATH`` to let CMake find our custom scripts:

```cmake
project(myapp)
cmake_minimum_required(VERSION 3.1)
set(CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
message(${CMAKE_BINARY_DIR})

add_executable(myapp main.cpp)
find_package(libcurl)
target_link_libraries(myapp libcurl::libcurl)
```


After cleaning the *build* directory and installing again, we will end up with the following files:

- FindOpenSSL.cmake
- Findzlib.cmake
- Findlibcurl.cmake


```bash
$ rm -rf build && mkdir build && cd build
$ conan install ..
```

Now let’s call CMake again:


**Linux/Mac**:
```bash
$ cmake .. -DCMAKE_BUILD_TYPE=Release
$ cmake --build .
$ ./bin/myapp
# a JSON will be outputted here
```

**Windows**:

```bash
$ cmake .. -G “Visual Studio 15 2017 Win64”
$ cmake --build . --config Release
$ ./release/myapp
# a JSON will be outputted here
```

If we would like to avoid the `CMAKE_MODULE_PATH` manipulation we could also use both `cmake_paths` and
`cmake_find_package` generators and use it as a toolchain like in the previous example, it will adjust also the
module path to locate our ``find<package_name>.cmake`` scripts in the current directory.

CMake will try to locate the find ``find<package_name>.cmake`` scripts in the following order: First the packages folder,
then the directory where we are building the project and finally the CMake installation/Modules directory.

## Wait... Is this really transparent?

Probably you noticed that the `find_package(CURL)` has been replaced with a `find_package(libcurl)`.
And maybe you are thinking: Well, but the name of the ``findXXX`` files do not correspond with my classic `find_package` invocations
in my `CMakelists.txt`. And I don't want to change my ``CMakeLists.txt`` file and this is the only reason why I'm reading this blog post!

And you are right, but this generator is not intended to replace the original CMake installation `find_package` modules,
because they behave in a very different way. As you can see, using the classic `find_package` modules, the information transmitted from
the Package Manager to the build system is mingy, while with this generator all the information from the targets is automatically
propagated:

- Targets are **transitive**, so you will specify only the dependencies you are directly depending on. You don't need to know if
  libcurl is depending on OpenSSL. Actually, the previous examples in Mac OSX use the internal Apple SSL implementation by default.
  And our ``CMakeLists.txt`` will work exactly the same in any system.

- Propagates **definitions**: Without the `CURL_STATICLIB` definition the build fails. This definition is declared in the `package_info` method
  of the libcurl package.

- Propagates **linker and compiler flags**: For example, to link with the SSL framework in Mac OSX, the recipe injects: ``-framework Security`` and ``-framework Cocoa``
  but only in OSX and only if you do not force it to use OpenSSL.

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-06-11/coupling_cmake.png" align="center" width="600"/>
</p>


- If you are consuming packages and you have high restrictions to change your ``CMakeLists.txt``, probably the ``cmake_paths`` is the best choice.

- If you are consuming packages and you are looking for a way to connect the package manager and the CMake build system in a non-intrusive way, choose ``cmake_find_package``.

- If you are creating Conan packages, we strongly recommend you to include the ``conanbuildinfo.cmake`` in your ``CMakeLists.txt`` file
(you can always patch your ``CMakeLists.txt`` from the recipe!).
The classic `cmake` generator introduces to our build script more information from the package manager:
The applied settings and options, the Visual Studio runtime, rpaths, compiler checks, standard library version and fPIC flag.


You can find the sources for the examples in this blog post at this repository:
[https://github.com/lasote/transparent_cmake_examples](https://github.com/lasote/transparent_cmake_examples)

You can find more information about the integration with CMake in the Conan docs:
[https://docs.conan.io/en/latest/integrations/cmake.html#cmake](https://docs.conan.io/en/latest/integrations/cmake.html#cmake)
