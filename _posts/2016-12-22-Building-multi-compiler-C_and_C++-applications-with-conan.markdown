---
layout: post
comments: false
title: "Building multi-compiler C/C++ applications with conan"
---

Conan 0.16 introduced a feature that allows to override any setting for a specific conan package in your dependencies graph. Also allows to specify environment variables to be set during the `conan install` command.

That feature was born from the conan github repository issue (a feature request). Users wanted to build some of their project dependencies using gcc in Windows (MinGW), but compiling their project using Visual Studio. When we read the issue the first thing we thought was, What?? Is it possible?? And the answer is yes, pure C libraries might be compatible even though they have been built with different compilers.


When we implemented and started to use this feature we realized that the combination of package specific settings and environment variables with profiles feature is very powerful.

Mixing compilers
----------------

Let’s see an example. We are going to build OpenSSL conan package with gcc 4.9 compiler (the native in my Linux machine) but building the zlib dependency with clang compiler (installed in /usr/bin/clang). 

We could use the command line arguments to specify it, but let’s start creating  for convenience a profile “openssl” (use whatever name you want) file in  ~/.conan/profiles/openssl.

```
[settings]
compiler=gcc
compiler.version=4.9
zlib:compiler=clang
zlib:compiler.version=3.5

[env]
zlib:CXX=/usr/bin/clang++
zlib:CC=/usr/bin/clang
```

The `CXX` and `CC` environment variables are used by build tools like CMake or autotools to locate the compiler to be used. 

We only need the above profile file to mix two different compilers, but let’s write an `OpenSSL` example code as a test project to see it in action.

In a new folder create a `main.c` file with a simple OpenSSL test program:

```cpp
#include <stdio.h>
#include <string.h>
#include "openssl/md5.h"
#include "openssl/crypto.h"
#include "zlib.h"
 
int main(){
    unsigned char digest[MD5_DIGEST_LENGTH];
    char string[] = "happy";
    
    MD5((unsigned char*)&string, strlen(string), (unsigned char*)&digest);    
 
    char mdString[33];
    
    int i;
    for(i = 0; i < 16; i++)
         sprintf(&mdString[i*2], "%02x", (unsigned int)digest[i]);
 
    printf("md5 digest: %s\n", mdString);
    printf("SSL library version: %s\n", SSLeay_version(SSLEAY_VERSION));
    printf("ZLIB version: %s\n", ZLIB_VERSION);
 
    return 0;
}
```

Write a simple `CMakeLists.txt` to build the example:

```cmake
project(MyHello)
cmake_minimum_required(VERSION 2.8)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

add_executable(md5 main.c)
target_link_libraries(md5 ${CONAN_LIBS})
```

Write a `conanfile.txt``with the required package:

```
[requires]
OpenSSL/1.0.2i@lasote/stable

[generators]
cmake
```

Then you can run conan install command specifying the profile to use with “--build” to force build the project dependencies:

```bash
$ mkdir build && cd build
$ conan install --build  --profile openssl ../
```


Invoke CMake to build the example project:

```bash
$ cmake ../ -DCMAKE_BUILD_TYPE=Release
$ cmake --build .
```

And finally, run the example:

```bash
$  ./bin/md5 

md5 digest: 56ab24c15b72a457069c5ea42fcfc640
SSL library version: OpenSSL 1.0.2i  22 Sep 2016
ZLIB version: 1.2.8

```

Indeed you could use this feature without using conan profile, you need to pass the all the arguments to `conan install` command:

```bash
$ conan install --build -s compiler=gcc -s compiler.version=4.9 -s zlib:compiler=clang -s zlib:compiler.version=3.5 -e zlib:CXX=/usr/bin/clang++ -e zlib:CC=/usr/bin/clang

```

Managing the build environment
------------------------------

With environment variables defined at package level we can adjust the whole build environment, for example, we can use different CMake versions for each package  setting the `PATH` environment variable pointing to different CMake installations for different packages:

```
[env]
package1:PATH=/my/path/to/cmake/3.5.0/bin
package2:PATH=/my/path/to/cmake/2.8.0/bin
package2:PATH=/my/path/to/other_tools
```


Conclusion
----------
These new features endow Conan a lot of flexibility to control the build environment, controlling not only each package settings and options but all the tools involved in our project and dependencies build.

Do you have any further suggestions about this feature? Please give feedback or contribute in github.
