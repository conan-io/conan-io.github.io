---
layout: post
comments: true
title: Using Facebook Folly with Conan
description: How to install Folly library and its dependencies without pain using Conan
---

This blog post goals to present the Facebook Folly project and its complex dependency chain as well as its usage. It will also present Conan as a solution for its installation and for its dependencies.
The source code for this example can be found on [Github](https://github.com/uilianries/conan-folly-example).


<h2>What is Folly</h2>


[Folly](https://github.com/facebook/folly) is the "acronym" for *Facebook Open Source Library*, a C ++ project that has been developed with the community and has become quite popular on Github, with more than 11,000 stars and 2,000 forks. The project was introduced in 2012 through [Facebook](https://www.facebook.com/notes/facebook-engineering/folly-the-facebook-open-source-library/10150864656793920/), aiming at a complete library, focused on ease of use, speed on development and as complement to real-world solutions, including:

* Asynchronous computation
* String formatting
* Benchmark
* Dynamic types

Folly was also introduced to the world through at CppCon editions, as in the ["Experiences with Facebook's C ++ Library"](https://www.youtube.com/watch?v=GDxb21kEthM) at CppCon 2017, and has an extensive documentation on [Github](https://github.com/facebook/folly/tree/master/folly/docs).


<h2>Talk is cheap, Show me the code</h2>


To illustrate the use of Folly, let's use an example project with the purpose of printing a string using Folly [Futures](https://code.fb.com/developer-tools/futures-for-c-11-at-facebook/):

{% highlight cpp %}

#include <cstdlib>
#include <utility>
#include <iostream>
#include <folly/Format.h>
#include <folly/futures/Future.h>
#include <folly/executors/ThreadedExecutor.h>
#include <folly/FBString.h>

static void print(const folly::fbstring& value) {
    const auto formatted = folly::format("Callback Future: {}", value);
    std::cout << formatted << std::endl;
}

int main() {
    folly::ThreadedExecutor executor;
    folly::Promise<folly::fbstring> promise;
    folly::Future<folly::fbstring> future = promise.getSemiFuture().via(&executor);
    folly::Future<folly::Unit> unit = std::move(future).thenValue(print);
    promise.setValue("Hello World!");
    std::move(unit).get();
    return EXIT_SUCCESS;
}

{% endhighlight %}

The code above should only print the message *"Callback Future: Hello World!"* shortly after the future callback is executed. [Future](https://isocpp.org/wiki/faq/cpp11-library-concurrency#cpp11-future) is nothing more than a representation of the result of an asynchronous computation that may not yet be available.
Once completed, it will contain the result of the operation performed. In this case, Folly Future is able to execute a callback after its completion, being the message itself.

In order for us to build this example project, we will use [CMake](https://cmake.org), with the provided ``CMakeLists.txt``:

{% highlight cmake %}

cmake_minimum_required(VERSION 3.1.3)
project(folly_example CXX)

find_package(Folly CONFIG REQUIRED)

add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} Folly::folly)
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 14)

{% endhighlight %}

Now that we have the sample code and the build description, we need the environment to build the project, including the Folly library and its dependencies.


<h2>Folly's dependencies</h2>


Although Folly is an excellent project for C ++ environments, it has a complex dependency structure:

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2018-11-19/graph.png"  align="center"
    width="600"  alt="Folly's dependency graph"/>
</p>

This dependency graph can be generated using the command [conan info](https://docs.conan.io/en/latest/reference/commands/consumer/info.html):

{% highlight bash %}

$ conan info folly/2018.11.12.00@bincrafters/stable --graph index.html

{% endhighlight %}

As noted, Conan listed 11 other projects directly related to Folly, including the [Boost library](https://boost.org). Now you can realize just how difficult and time-consuming the task of preparing the environment to use Folly is.

The project itself lists how to resolve its dependencies on Linux, Windows, and OSX platforms. However, in Linux it will be mandatory to use the version offered by the distribution and will not always be what is wanted. On Windows there is still the option to use [Vcpkg](https://docs.microsoft.com/en-us/cpp/vcpkg), however, you will need to wait for the construction of all dependencies before you can compile any sample code.


<h2>Conan to the rescue</h2>


Just like Conan, the Barbarian, Conan the C ++ package manager is also able to perform magics to solve any requirement. In order for such dependencies to be resolved, the small recipe ``conanfile.txt`` must be created to tells conan to retrieve the conan Folly package and generate a cmake file for our convenience:

{% highlight conf %}

[requires]
folly/2018.11.12.00@bincrafters/stable

[generators]
cmake

{% endhighlight %}

The recipe shows the requirements for our project, in this case only the Folly project, distributed in version 2018.11.12.00, by [Bincrafters](https://bincrafters.github.io/) and is available on [Bintray](https://bintray.com/bincrafters/public-conan/folly%3Abincrafters).
Since we are using CMake to build our project, we need to tell Conan to run its [cmake generator](https://docs.conan.io/en/latest/integrations/cmake/cmake_generator.html#cmake-generator) to provide a file with all the necessary settings to be able to import Folly.

And how about all those 11 dependencies listed by Folly? All transitive dependencies will be solved automatically by Conan, like magic!

Unfortunately, CMake alone is not able to solve all the extra dependencies required through Folly, so we will need to use Conan and CMake together to declare the extra packages. Let's update our ``CMakeLists.txt``:

{% highlight cmake %}

cmake_minimum_required(VERSION 3.1.3)
project(folly_example CXX)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup(TARGETS)

add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} CONAN_PKG::folly)
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 14)

{% endhighlight %}

As you can see, the [find_package](https://cmake.org/cmake/help/v3.1/command/find_package.html) has been replaced by the `conan_basic_setup` function. This function will be responsible of configuring all necessary settings, including the paths to the headers and libraries files. The ``conanbuildinfo.cmake`` is generated by Conan, once the generator configured is of type **cmake**. The `CONAN_PKG::folly` target, generated by Conan, owns the Folly project, in addition to all the libraries listed as dependencies.


<h2>Time to build</h2>


Now that the CMake file was updated and the Conan recipe has the appropriate dependency listed, we can build our example:

{% highlight bash %}

$ mkdir build && cd build
$ conan install ..
$ cmake ..
$ cmake --build .

{% endhighlight %}

The [conan install](https://docs.conan.io/en/latest/reference/commands/consumer/install.html) command is responsible for reading the ``conanfile.txt`` file, downloading and installing Folly according to the default profile (based on the host configuration), and generating the ``conanbuildinfo.cmake`` with all the information we need for the next step.
The commands using CMake will take care of generating the file for construction, in addition to building the example.

Once built, we can run our example project:

{% highlight bash %}

$ bin/folly_example
 Callback Future: Hello World!
{% endhighlight %}


<h2>Conclusion</h2>


The C ++ universe has such incredible projects as Folly to help with real-world problems, however, preparing an environment with all the necessary dependencies can lead to a long and painful task often.
Although Folly is an excellent tool for your project, the complexity of 11 projects related as transitive dependencies, including Boost regex, can be taken as a bad factor to avoid using it.
The case of the Folly project demonstrates the importance of a dependency manager and packages like Conan for a modern C++ development environment.
