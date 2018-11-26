---
layout: post
comments: false
title: Using Facebook Folly with Conan
description: How to install Folly library and its dependencies without pain using Conan
---

This blog post goals to present the Facebook Folly project and its complex dependency chain as well as its usage. It will also present Conan as a solution for its installation and for its dependencies.
The source code for this example can be found on [Github](https://github.com/uilianries/conan-folly-example).


## What is Folly


[Folly](https://github.com/facebook/folly) is the "acronym" for *Facebook Open Source Library*, a C ++ project that has been developed with the community and has become quite popular on Github, with more than 11,000 stars and 2,000 forks. The project was introduced in 2012 through [Facebook](https://www.facebook.com/notes/facebook-engineering/folly-the-facebook-open-source-library/10150864656793920/), aiming at a complete library, focused on ease of use, speed on development and as complement to real-world solutions, including:

* Asynchronous computation
* String formatting
* Benchmark
* Dynamic types

Folly was also introduced to the world through at CppCon editions, as in the ["Experiences with Facebook's C ++ Library"](https://www.youtube.com/watch?v=GDxb21kEthM) at CppCon 2017, and has an extensive documentation on [Github](https://github.com/facebook/folly/blob/master/folly/docs/Overview.md).


## Why should I use folly in my project?


We already have ``std`` and ``Boost``, so why we need another core library? In fact Folly does not aim to replace any library, but complement them. Folly was thought for cases where they require higher performance or have not yet been implemented. Currently it is used by Facebook itself, in its [millions of servers]( https://code.fb.com/open-source/linux/), which support more than [2 billion users](https://newsroom.fb.com/company-info/), and also is used in [Facebook mobile apps](code.fb.com/android/building-zero-protocol-for-fast-secure-mobile-connections) which are on over a billion devices according to [Google Play](play.google.com/store/apps/details?id=com.facebook.katana). This proves the maturity and reliability of Folly project.

In the CppCon 2016 edition, the presentation ["The strange details of std::string at Facebook"](https://youtu.be/kPR8h4-qZdk) demonstrated the work done by [Andrei Alexandrescu](http://erdani.com/) in implementing [FBString](https://github.com/facebook/folly/blob/master/folly/docs/FBString.md), a class developed with the objective of being more efficient, compatible with ``std::string``, resulting in **30x faster** than ``string::find()``.

In addition to being designed to achieve great efficiency, Folly was also designed to be easy to use, to acelerate the integration and learning of new users. For example, string conversion can be simplified through [Conv](https://github.com/facebook/folly/blob/master/folly/docs/Conv.md), or mutex synchronization through [Synchronized](https://github.com/facebook/folly/blob/master/folly/docs/Synchronized.md), or even [ProducerConsumerQueue](https://github.com/facebook/folly/blob/master/folly/docs/ProducerConsumerQueue.md) to synchronize queues for multhreading programming.


## Talk is cheap, Show me the code


To illustrate the use of Folly, let's use an example project with the purpose of validating a [URI](https://www.ietf.org/rfc/rfc3986.txt) using [Futures](https://code.fb.com/developer-tools/futures-for-c-11-at-facebook/), [FBString](https://github.com/facebook/folly/blob/master/folly/docs/FBString.md), [Executors](https://github.com/facebook/folly/blob/master/folly/docs/Executors.md), and [Format](https://github.com/facebook/folly/blob/master/folly/docs/Format.md):

{% highlight cpp %}

#include <utility>
#include <iostream>
#include <folly/Format.h>
#include <folly/futures/Future.h>
#include <folly/executors/ThreadedExecutor.h>
#include <folly/Uri.h>
#include <folly/FBString.h>

static void print_uri(const folly::fbstring& address) {
    const folly::Uri uri(address);
    const auto authority = folly::format("The authority from {} is {}", uri.fbstr(), uri.authority());
    std::cout << authority << std::endl;
}

int main() {
    folly::ThreadedExecutor executor;
    folly::Promise<folly::fbstring> promise;
    folly::Future<folly::fbstring> future = promise.getSemiFuture().via(&executor);
    folly::Future<folly::Unit> unit = std::move(future).thenValue(print_uri);
    promise.setValue("https://conan.io/");
    std::move(unit).get();
    return 0;
}

{% endhighlight %}

The code above should only print_uri the message *"The authority from https://conan.io is conan.io"* shortly after the future callback is executed. Let's look in detail:

{% highlight cpp %}

static void print_uri(const folly::fbstring& address) {
    const folly::Uri uri(address);
    const auto authority = folly::format("The authority from {} is {}", uri.fbstr(), uri.authority());
    std::cout << authority << std::endl;
}

{% endhighlight %}

This small function is responsible for parsing the address, validating whether it is a valid URI, formatting a string with the authority present on the URI, and showing through the standard output. The ``FBString`` class has 3 strategies for storing:

- Small strings (<= 23 chars) are stored in-situ without memory allocation.
- Medium strings (24 - 255 chars) are stored in malloc-allocated memory and copied eagerly.
- Large strings (> 255 chars) are stored in malloc-allocated memory and copied lazily.

The received address has only 17 characters, so it will be stored without memory allocation. The ``Uri`` will parse the address in its constructor, for this will be used [Boost Regex](https://theboostcpplibraries.com/boost.regex). And finally will format using the fast and powerful ``folly::format``.

{% highlight cpp %}

folly::Future<folly::fbstring> future = promise.getSemiFuture().via(&executor);
folly::Future<folly::Unit> unit = std::move(future).thenValue(print_uri);
promise.setValue("https://conan.io/");
std::move(unit).get();

{% endhighlight %}

[Future](https://isocpp.org/wiki/faq/cpp11-library-concurrency#cpp11-future) is nothing more than a representation of the result of an asynchronous computation that may not yet be available.
Once completed, it will contain the result of the operation performed. Folly Future is able to execute a callback after its completion through ``thenValue`` and ``thenTry``.
The executor specifies where work will run, thus given an executor we can convert a ``SemiFuture`` to a ``Future`` with an executor. Finally, we set the value to be consumed by the callback function and wait for the result through ``get()``.

Now that we have the sample code and the build description, we need the environment to build the project, including the Folly library and its dependencies.


## Folly's dependencies


Although Folly is an excellent project for C ++ environments, it has a complex dependency structure:

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2018-11-19/graph.png"  align="center"
    width="600"  alt="Folly's dependency graph"/>
</p>

This graph can be generated with the [conan info](https://docs.conan.io/en/latest/reference/commands/consumer/info.html) command:

{% highlight bash %}

$ conan info folly/2018.11.12.00@bincrafters/stable --graph index.html

{% endhighlight %}

As noted, Conan listed 11 other projects directly related to Folly, including the [Boost library](https://boost.org). Now you can realize just how difficult and time-consuming the task of preparing the environment to use Folly is.

The project itself lists how to resolve its dependencies on Linux, Windows, and OSX platforms. However, in Linux it will be mandatory to use the version offered by the distribution and will not always be what is wanted. On Windows there is still the option to use [Vcpkg](https://docs.microsoft.com/en-us/cpp/vcpkg), however, you will need to wait for the construction of all dependencies before you can compile any sample code.


## Conan to the rescue


Conan the C++ package manager is able to compute the dependency graph and resolve dependencies. In order for such dependencies to be resolved, the small file ``conanfile.txt`` must be created to tells conan to retrieve the conan Folly package and generate a cmake file for our convenience:

{% highlight conf %}

[requires]
folly/2018.11.12.00@bincrafters/stable

[generators]
cmake

{% endhighlight %}

The file shows the requirements for our project, in this case only the Folly project, distributed in version 2018.11.12.00, by [Bincrafters](https://bincrafters.github.io/) and is available on [Bintray](https://bintray.com/bincrafters/public-conan/folly%3Abincrafters) and [Conan center](https://bintray.com/conan/conan-center), which comes pre-configured in the conan-cli.
Since we are using CMake to build our project, we need to tell Conan to run its [cmake generator](https://docs.conan.io/en/latest/integrations/cmake/cmake_generator.html#cmake-generator) to provide a file with all the necessary settings to be able to import Folly.
Although we use cmake for this project, Conan has several other [generators](https://docs.conan.io/en/latest/integrations.html), including [QMake](https://docs.conan.io/en/latest/integrations/qmake.html), [Visual Studio](https://docs.conan.io/en/latest/integrations/visual_studio.html), [XCode](https://docs.conan.io/en/latest/integrations/xcode.html) and many others.

All those 11 dependencies listed by Folly will be solved automatically by Conan!

Unfortunately, CMake alone is not able to solve all the extra dependencies required through Folly, so we will need to use Conan and [CMake](https://cmake.org/) together to declare the extra packages. Let's write ``CMakeLists.txt``:

{% highlight cmake %}

cmake_minimum_required(VERSION 3.1.3)
project(folly_example CXX)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup(TARGETS)

add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} CONAN_PKG::folly)
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 14)

{% endhighlight %}

The function `conan_basic_setup` will be responsible of configuring all necessary settings, including the paths to the headers and libraries files. The ``conanbuildinfo.cmake`` is generated by Conan, once the generator configured is of type **cmake**. The `CONAN_PKG::folly` target, generated by Conan, owns the Folly project, in addition to all the libraries listed as dependencies.


## Time to build


Now that the CMake file was updated and the Conan recipe has the appropriate dependency listed, we can build our example:

{% highlight bash %}

$ mkdir build && cd build
$ conan install ..
$ cmake .. -G "Visual Studio 15 Win64"
$ cmake --build . --config Release

{% endhighlight %}

The [conan install](https://docs.conan.io/en/latest/reference/commands/consumer/install.html) command is responsible for reading the ``conanfile.txt`` file, downloading and installing Folly according to the default profile (based on the host configuration), and generating the ``conanbuildinfo.cmake`` with all the information we need for the next step.
The commands using CMake will take care of generating the file for construction, in addition to building the example.

Once built, we can run our example project:

{% highlight bash %}

$ bin/folly_example
 Callback Future: Hello World!
{% endhighlight %}


## Conclusion


The C ++ universe has such incredible projects as Folly to help with real-world problems, however, preparing an environment with all the necessary dependencies can lead to a long and painful task often.
Although Folly is an excellent tool for your project, the complexity of 11 projects related as transitive dependencies, including Boost regex, can be taken as a bad factor to avoid using it.
The case of the Folly project demonstrates the importance of a dependency manager and packages like Conan for a modern C++ development environment.

Are you interested in making comments, questions or suggestions? Please open an [issue](https://github.com/conan-io/conan/issues)!
