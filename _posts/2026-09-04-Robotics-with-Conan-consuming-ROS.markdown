---
layout: post
comments: false
title: "Robotics with Conan: consuming ROS as a regular package"
description: "We have been experimenting with recipes that build ROS, the framework most robotics applications are built on, from source and expose it as a regular Conan package. Here is how consuming it looks, and the questions we would like to ask you about it."
meta_title: "Robotics with Conan: consuming ROS as a regular package - Conan Blog"
keywords: "conan, C++, ROS, ROS 2, ROS Kilted, robotics, ros-kilted, rclcpp, CMake, dependency management"
categories: [cpp, conan, ros, ros2, robotics]
---

We know that many of you use Conan for your C++ developments in robotics, and that some of
you have probably considered adding [ROS](https://docs.ros.org/) support to those projects at some point.
**That is usually where the two worlds stop fitting together.** Your control, perception or planning
code is written in C++ and managed with Conan, while ROS is a layer
on top of it that has to be dealt with separately, installed system-wide with `apt`, `rosdep`,
`brew` or `choco` on every developer machine and every CI agent.

In case you have not worked with it, ROS (Robot Operating System) is a large set of C++ and
Python libraries and tools that provide the API and the conventions around that code. Your
components run as processes that exchange data through a publish/subscribe layer built on top
of DDS, using standard message types for sensor data, geometry and coordinate transforms. **That
universality is where its power comes from**: once your code speaks those interfaces, it can be
combined with the drivers, algorithms, robot models and tools that the rest of the ecosystem
already publishes, or with those of the partners you work with.

For some months now we have been working on [conan-io/ros-conan](https://github.com/conan-io/ros-conan),
a set of recipes that build the current ROS distribution,
[Kilted](https://docs.ros.org/en/kilted/Releases/Release-Kilted-Kaiju.html), from source and expose
it as a regular Conan package for Linux, macOS and Windows. What we are after is that **adding ROS
support to a C++ project already using Conan is one more `requires`**, and not a separate
installation with its own workflow. A `conan install` puts the ROS installation in your cache, and from
there you require and consume it like any other package.

<figure class="centered">
    <video controls playsinline preload="metadata" width="100%"
           poster="{{ site.baseurl }}/assets/post_images/2026-09-04/pose-estimation-ros-kilted-rviz2.jpg">
        <source src="{{ site.baseurl }}/assets/post_images/2026-09-04/ros-conan-screencast.mp4" type="video/mp4">
        <a href="{{ site.baseurl }}/assets/post_images/2026-09-04/ros-conan-screencast.mp4">Download the video</a>
    </video>
    <figcaption style="text-align: center; font-size: 0.9em;">
        The <a href="https://github.com/conan-io/ros-conan/tree/main/examples/pose_estimation">pose_estimation</a>
        example: a ROS node that tracks human pose from an image input, with
        <code>ros-kilted</code>, <code>opencv</code> and <code>tensorflow-lite</code>
        resolved in a single dependency graph
    </figcaption>
</figure>

## What consuming it looks like

ROS shows up as one more `requires`. This is the whole dependency declaration of the example in the video above:

**`conanfile.txt`**

```ini
[requires]
ros-kilted/2026.06.17
tensorflow-lite/2.15.0
opencv/4.12.0

[generators]
CMakeToolchain
CMakeDeps

[layout]
cmake_layout
```

On the CMake side, ROS packages are located with their usual
`find_package()` calls. The recipe puts the ROS installation on
`CMAKE_PREFIX_PATH`, so the config files that ROS itself installs are the
ones being used:

**`CMakeLists.txt`**

```cmake
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(tensorflowlite REQUIRED)
find_package(OpenCV REQUIRED)

add_executable(pose-estimation src/pose-estimation.cpp)
target_link_libraries(pose-estimation PRIVATE rclcpp::rclcpp
                                              ${geometry_msgs_TARGETS}
                                              ${visualization_msgs_TARGETS}
                                              tensorflow::tensorflowlite
                                              opencv::opencv)
```

**`ros-kilted` is more than the C++ client library.** The recipe packages the distribution, so besides
`rclcpp` you get the standard message packages such as `geometry_msgs` or `sensor_msgs` and,
depending on the variant you pick, coordinate transforms with `tf2` or the visualization tools.
The `variant` option ranges from `core` to `desktop` and decides how much of ROS gets built.

Then the usual install and build sequence of any Conan project:

```bash
conan install . --build=missing --profile=ros-conan/profiles/ros
cmake --preset conan-release
cmake --build --preset conan-release
```

> **Note**: on Windows, building ROS produces deep directory trees that exceed the default
> 260-character path limit. Enable
> [long paths](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry#enable-long-paths-in-windows-10-version-1607-and-later)
> before running `conan install`.

The recipes are not in Conan Center yet, so `ros-kilted` is resolved by cloning the repository next
to your project and adding it as a
[local-recipes-index](https://docs.conan.io/2/devops/devops_local_recipes_index.html) remote. That
clone is also where the `profiles/ros` profile comes from. The two commands for that are in the README.

One good thing about this approach is that there is no need to bring all the usual ROS
tooling and workspace conventions into your C++ project. **The application stays a plain
CMake project that happens to require ROS.** For a codebase where ROS is one layer of a
larger C++ product, we think that is a reasonable place to be, but we would like to hear
whether it holds up in a real project.

## What we think this brings

- **One dependency graph.** ROS is resolved together with the rest of your requirements, so
  Conan can detect version conflicts between the robotics libraries and everything else.
- **No system-wide install.** ROS lives in the Conan cache, so different versions can coexist on
  the same machine and each project activates the one it needs.
- **The same tooling as the rest of your dependencies.** Profiles, options, lockfiles, remotes
  and CI pipelines apply to ROS as they do to any other package, with the same commands on the
  three platforms.
- **Composable with Conan Center.** Robotics applications often need
  [opencv](https://conan.io/center/recipes/opencv), [eigen](https://conan.io/center/recipes/eigen)
  or [tensorflow-lite](https://conan.io/center/recipes/tensorflow-lite), and those come from the
  same graph, with no glue in between.

## The ROS tools still work as usual

If you are already familiar with ROS, the `ros-kilted` recipe brings a couple of conveniences:
the whole installation arrives with a single `conan install`, and the `ros2` commands can be run
without sourcing anything by hand. Everything else behaves as the
[official tutorials](https://docs.ros.org/en/kilted/Tutorials.html) describe. Here is `turtlesim`,
the small simulator used to introduce ROS, launched straight from the installation Conan provides.
It is part of the `desktop` variant, so that is the one to select:

```ini
[options]
ros-kilted/*:variant=desktop
```

```bash
conan run "ros2 run turtlesim turtlesim_node" --profile=ros-conan/profiles/ros
```

<figure class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2026-09-04/ros-kilted-turtlesim.jpg"
         style="display: block; margin-left: auto; margin-right: auto;"
         alt="turtlesim window launched from a Conan-provided ROS installation"/>
    <figcaption style="text-align: center; font-size: 0.9em;">
        turtlesim launched from a Conan-provided ROS installation
    </figcaption>
</figure>

## We would like to know what you think

**This is an early experiment rather than a finished feature.** Kilted is the only
distribution covered so far, and CI builds the `core`, `base` and `desktop` variants
from source for Linux (gcc 13, x86_64 and ARM64), macOS (clang 17, x86_64 and ARM64)
and Windows (MSVC 19.40). There are no prebuilt binaries yet, so the first
`conan install --build=missing` compiles ROS from source. That takes a while, but the
result stays in the cache for the projects that come after.

A few questions we have in mind:

- Does this approach make sense to you? Is consuming ROS as a Conan package something you would use?
- Would it help to put a ROS layer on top of an existing C++ codebase, or to try ROS
  out without installing it system-wide?
- Is a single `ros-kilted` package the right granularity, or would you rather have
  smaller packages so that a project only pulls in what it uses?
- Which other libraries would you like to combine with ROS in the same graph?

Clone [conan-io/ros-conan](https://github.com/conan-io/ros-conan), try the examples, and tell us how
it went by opening an issue on [GitHub](https://github.com/conan-io/ros-conan/issues). Bugs and
contributions are welcome too.

We will also be at ROSCon Global 2026 in Toronto. If you are attending, we would
be happy to talk about this in person.

Looking forward to your feedback.
