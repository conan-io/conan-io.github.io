---
layout: post
comments: false
title: "Serialiazing your data with Protobuf"
---

You probably already had to develop a project where you needed to exchange information between
processes or even between different architectures. One well-known technique in this scenario is
[serialization](https://en.wikipedia.org/wiki/Serialization), which is summarized in the
translation of data structures or object state into a format that can be stored and retrieved by
the both sides.

In this blog post, we will discuss the [Protobuf](https://developers.google.com/protocol-buffers)
(Protocol Buffers), a project that can extend more than a simple library for serialization. The
entire example presented here is available on [Github](https://github.com/uilianries/conan-protobuf-example).

## What is Protobuf?

Protocol Buffers is an open source project under the BSD 3-Clause
[license](https://github.com/protocolbuffers/protobuf/blob/master/LICENSE), a popular one developed
by Google, to provide a language-neutral, platform-neutral and extensible mechanism for serializing
structured data. It supports many popular languages such as C++, C#, Dart, Go, Java and Python.
Although there are still other not official [add-ons](https://github.com/protocolbuffers/protobuf/
blob/master/docs/third_party.md), that support other languages, such as C. You can find the source
code on [Github](https://github.com/protocolbuffers/protobuf), where its popularity reaches almost
32K stars!

The neutral language used by Protobuf allows you to model messages in a structured format
through **.proto** files:

{% highlight proto %}
message Person {
  required string name = 1;
  required int32 age = 2;
  optional string email = 3;
}
{% endhighlight %}

In the example above we use a structure that represents a person's information, where it has
mandatory attributes, such as _name_ and _age_, as well as having the optional _email_ data.
Mandatory fields, as the name already says, must be filled when a new message is constructed,
otherwise, a **runtime error** will occur.

## But Why not XML?

But, why another language and serialization mechanism if we can use something already available
like XML? The answer is [performance](https://github.com/protocolbuffers/protobuf/blob/master/
docs/performance.md).

Protobuf has many advantages for serialization that go beyond the capacity of XML. It allows you
to create a simpler description than using XML. Even for small messages, when requiring multiple
nested messages, reading XML starts to get difficult for human eyes.

Another advantage is the size, as the Protobuf format is simplified, the files can reach 10 times
smaller compared to XML. But the great benefit is its speed, which can reach 100 times faster than
the standard XML serialization, all due to its optimized mechanism. In addition to size and speed,
Protobuf has a compiler capable of processing a .proto file to generate multiple supported
languages, unlike the traditional method where it is necessary to arrange the same structure in
multiple source files.

## That sounds good, but how do I use it in real life?

So that we can illustrate the use of Protocol Buffers, we will exchange messages through different
architectures and opposite languages. We will compile a code in C++ for _armv7hf_ architecture,
serialize an object to file, and retrieve through a Python script. An advantageous model for those
who need to exchange messages between opposing architectures through IPC techniques, even for
embedded systems.

For our example, we will use a message that has the reading of several sensors. The file
**sensor.proto**, which will represent the message, is described below:

{% highlight proto %}
syntax = "proto2";
message Sensor {
  required string name = 1;
  required double temperature = 2;
  required int32 humidity = 3;

  enum SwitchLevel {
    CLOSED = 0;
    OPEN = 1;
  }
  required SwitchLevel door = 5;
}
{% endhighlight %}

The variable _syntax_ refers to the version of the Protobuf used, which can be _proto2_ or _proto3_.
Versions 2 and 3 have important differences, but we will only address version 2 in this post. For
more information about version 3, see the
[official documentation](https://developers.google.com/protocol-buffers/docs/proto3).
In addition to the declared attributes, and previously highlighted there is the enumerator
_SwitchLevel_, which represents the state of a port. We could still include new messages, or even
lists for multiple ports, for example. For a complete description of the syntax used in proto
version 2, see the [language guide](https://developers.google.com/protocol-buffers/docs/proto).

The Protobuf serialization mechanism is given through the ``protoc`` application, this compiler
will parse the ``.proto`` file and will generate as output, source files according to the
configured language by its arguments, in this case, C++. You can also obtain more information
about, reading the section [compiler invocation](https://developers.google.com/protocol-buffers/
docs/reference/cpp-generated#invocation).

{% highlight bash %}
$ protoc --cpp_out=. sensor.proto
{% endhighlight %}

The ``protoc`` compiler will generate the ``sensor.pb.h`` and ``sensor.pb.cc`` files, respectively,
of which have the getters and setters needed to access the attributes, as well as methods for
serializing and parsing. The files work only as a stub, and it is necessary to include the headers
distributed by Protobuf. Without this compiler, we would have to describe all the steps of object
serialization in our code, and for any new change, it would be needed to update the C++ and Python
files.

Now that we have the stubs, we can implement an example to serialize the data collected by a sensor.
The file ``main.cpp`` will be described below:

{% highlight cpp %}
#include “sensor.pb.h”

int main() {
    Sensor sensor;
    sensor.set_name("Laboratory");
    sensor.set_temperature(23.4);
    sensor.set_humidity(68);
    sensor.set_door(Sensor_SwitchLevel_OPEN);
}
{% endhighlight %}

The Sensor object can be serialized through methods inherited from the [Message](https://
developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.message) class.
For example, we can serialize to a string by the [SerializeAsString](https://developers.google.com/
protocol-buffers/docs/reference/cpp/google.protobuf.message_lite#MessageLite.SerializeAsString) method.

Note that this reconstruction can be performed by other languages also supported by Protobuf, in
addition to other architectures. In order for the transmission to occur through different processes,
it will be necessary to use [IPC](https://en.wikipedia.org/wiki/Inter-process_communication)
techniques, for this, Google provides the [gRPC](https://grpc.io/) project, a universal[RPC](https://
en.wikipedia.org/wiki/Remote_procedure_call) framework, that supports Protobuf directly. However,
our intention in this post is just to talk about Protobuf, so we will use the only text file as a
means to exchange messages between processes:

{% highlight cpp %}
#include <fstream>
#include “sensor.pb.h”

int main() {
    Sensor sensor;
    sensor.set_name("Laboratory");
    sensor.set_temperature(23.4);
    sensor.set_humidity(68);
    sensor.set_door(Sensor_SwitchLevel_OPEN);
    std::ofstream ofs("sensor.data", std::ios_base::out | std::ios_base::binary);
    sensor.SerializeToOstream(&ofs);
}
{% endhighlight %}

To perform serialization through a file, we use the [SerializeToOstream](https://developers.google.com/
protocol-buffers/docs/reference/cpp/google.protobuf.message#Message.SerializeToOstream.details) method.

## Building the project

For the next step, we will describe the actions for constructing the project by [CMake](https://cmake.org/):

{% highlight cmake %}
cmake_minimum_required(VERSION 3.1.2)
project(sensor CXX)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup(TARGETS)

find_package(Protobuf REQUIRED)

protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS sensor.proto)
add_executable(${PROJECT_NAME} main.cc ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(${PROJECT_NAME} PUBLIC CONAN_PKG::protobuf)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_BINARY_DIR})
{% endhighlight %}

This recipe searches for the modules, libraries, and macros provided by the Protobuf project when
calling [find_package](https://cmake.org/cmake/help/v3.1/command/find_package.html). Once found and
loaded correctly, ``protobuf_generate`` macros will be available for use. The
[protobuf_generate_cpp](https://cmake.org/cmake/help/v3.1/module/
FindProtobuf.html#command:protobuf_generate_cpp) function is responsible for executing the
``protoc`` and populating the ``PROTO_SRCS`` and ``PROTO_HDRS`` variables with their generated
files. Without this functionality, you would need to manually add the ``protoc`` command and the
required arguments. The subsequent lines follow the most usual of CMake projects. Because the
generated files will be in the build directory, you need to include it by
[target_include_directories](https://cmake.org/cmake/help/v3.1/command/
target_include_directories.html) so that ``main.cc`` can resolve ``proto.pb.h``.

It is also possible to observe that we are using [Conan](https://conan.io) to solve Protobuf as a
dependency. The [conan_basic_setup](https://docs.conan.io/en/latest/reference/generators/cmake.html#conan-basic-setup)
function will be in charge of configuring all the necessary variables, besides generating the
target ``CONAN_PKG::protobuf``.

In addition, you must also declare the
[conanfile.txt](https://docs.conan.io/en/latest/reference/conanfile_txt.html) file with the
following dependencies:

{% highlight text %}
[requires]
protoc_installer/3.6.1@bincrafters/stable
protobuf/3.6.1@bincrafters/stable

[generators]
cmake
{% endhighlight %}

Since Protobuf can be divided into two parts, the protoc installer, and the libraries, there are two
separate packages. Thus, it will be possible to install ``protoc`` for the same host architecture,
and libraries for a target architecture. As we are using CMake for this project, we need to declare
the CMake [generator](https://docs.conan.io/en/latest/integrations/cmake/cmake_generator.html).

Now just run the commands to build the project:

{% highlight bash %}
mkdir build
cd build
conan install ..
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
bin/sensor
{% endhighlight %}

So far so good, but how is it done in case of cross compilation? In this case, it will be necessary
to inform the compiler and the target platform:

{% highlight bash %}
conan install .. -s arch=armv7hf
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++``
cmake --build .
{% endhighlight %}

In the above commands, we have installed only the prebuilt Protobuf libraries for _armv7hf_. The
``protoc`` will only hold for _amd64_ because it ignores arch, making use of only the host
architecture by [arch_build](https://docs.conan.io/en/latest/systems_cross_building/
cross_building.html#conan-settings). CMake needs to be informed which compiler will be used, so we
define it through ``CMAKE_CXX_COMPILER``. Once ready, we can copy our application directly to the
target platform.

## Parsing with Python

Now we get to the second step, read the file and retrieve the object using Python. For this, we will
only update the CMake script, so that it generates the C++ files and also the python stub:

{% highlight cmake %}
protobuf_generate_python(PROTO_PYS sensor.proto)
add_custom_target(proto_python ALL DEPENDS ${PROTO_PYS})
{% endhighlight %}

The ``protobuf_generate_python`` function has the same goal as ``protobuf_generate_cpp`` but will
generate the file ``sensor_pb2.py``. The ``proto_python`` virtual target was added to force CMake
to call the generator for Python.

The next step is to develop the script that will read the file with the serialized data and parse
it through the script generated in the previous step:

{% highlight python %}
from sensor_pb2 import Sensor

if __name__ == "__main__":
    with open("sensor.data", 'rb') as file:
        content = file.read()
        print("Retrieve Sensor object from sensor.data")
        sensor = Sensor()
        sensor.ParseFromString(content)
        print(f"Sensor name: {sensor.name}")
        print(f"Sensor temperature: {sensor.temperature}")
        print(f"Sensor humidity: {sensor.humidity}")
    print("Sensor door: {}".format("Open" if sensor.temperature else "Closed"))
{% endhighlight %}

The script is fairly straightforward, just like the code in C++ and can be copied together with the
``sensor_pb2.py`` file directly to the target platform.

## Conclusion

Transfer data between processes, serializing objects or even storing data are techniques that are
widely used in all scenarios, but they require a lot of effort when implemented and are often not
the goal of the project under development. Serialization techniques can be solved through several
projects available, such as Protobuf, without having to delve into the low level required to
process all the data.

The success in using Protobuf is not only in serializing the data, but in the mechanism as a whole,
from the natural language used, flexible and easy to understand, to the compiler with support for
multiple languages, and even integration with other products, such as the gRPC, which provides
direct communication between processes without much effort.

This post blog was a tutorial to demonstrate how tasks that could take up to weeks to complete, with
library development, can be solved in a few hours, only using what is ready and without the need to
build from the sources.

Interested in knowing more or commenting on the subject? Please do not hesitate to open a new
[issue](https://github.com/conan-io/conan/issues).
