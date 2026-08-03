---
layout: post
comments: false
title: "ROS in your Conan workflow: building robotics apps with conan install"
description: "ROS (Kilted) is now consumable as a Conan package via the ros-conan recipes. Pull the full ROS runtime with one conan install and use it from any plain CMake C++ project."
meta_title: "ROS in your Conan workflow - Conan Blog"
keywords: "conan, C++, ROS, ROS 2, robotics, ros-kilted, rclcpp, colcon, CMake"
categories: [cpp, conan, ros, ros2, robotics]
---

[ROS](https://docs.ros.org/) is the de-facto framework for building robotics
applications, with most performance-critical nodes written in C++ on top of
[`rclcpp`](https://docs.ros.org/en/kilted/p/rclcpp/). Installing it, though,
has always meant stepping outside the C++ package manager ecosystem and
reaching for `apt`, `rosdep`, `brew` or `choco`. We are happy to announce
that ROS [Kilted](https://docs.ros.org/en/kilted/Releases/Release-Kilted-Kaiju.html)
can now be consumed as a regular Conan package via the
[conan-io/ros-conan](https://github.com/conan-io/ros-conan) recipes: one
`conan install` pulls the full ROS runtime into your Conan cache, ready to be
consumed like any other C++ library.

## Why integrate ROS into Conan

Wrapping ROS as a Conan package brings the robotics half of your dependency
graph into the same workflow as the rest of your C++ stack:

- **Native C++ dev flow**: a plain `find_package(rclcpp REQUIRED)` in your
  `CMakeLists.txt` is enough. No global system install, no sourcing scripts
  before invoking CMake, no `ament_cmake` requirement on consumers.
- **Same interface as every other Conan dependency**: ROS becomes one more
  `requires` line in your `conanfile.txt/py`. Profiles, settings, options,
  generators and lockfiles work exactly as they do for any other package.
- **Reproducible across machines**: same recipe, same revisions, same binaries
  on Windows, macOS and Linux. No `rosdep`, no distro mismatch, no surprises
  between a developer laptop and a CI runner.
- **Self-contained**: ROS lives inside the Conan cache. No `sudo`, no polluting
  `/opt/ros/...`, no conflicts between distributions on the same machine.
- **Composable with ConanCenter**: ROS nodes naturally pull in `opencv`,
  `eigen`, `tensorflow-lite`, `grpc`, `fmt`, and the rest of the C++ ecosystem
  through the very same dependency graph.

## The integration approach: the `ros-kilted` recipe

The integration lives in [conan-io/ros-conan](https://github.com/conan-io/ros-conan),
a repository of Conan recipes that build ROS from source.

The `ros-kilted` recipe exposes a `variant` option to pick how much of the distribution
you want to pull in:

- **core** (default): `rcl`, `rclcpp`, `rclpy`, `rmw`, common interfaces.
- **base**: Adds `tf2`, `kdl_parser`, `robot_state_publisher`.
- **desktop**: Adds `rviz2`, demo nodes, visualization tools.
- **desktop_full** (WIP): Adds simulation and perception stacks.

### Setting it up

ROS Kilted targets Python 3.12, so make sure you are using
that interpreter. Then install Conan 2 in a virtual environment and add the
`ros-conan` repository as a local recipes index:

```bash
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate.bat
pip install conan
# only if it is the first time you use conan
conan profile detect 

git clone https://github.com/conan-io/ros-conan.git
conan remote add ros-conan ./ros-conan
```

`ros-kilted` and its bundled dependencies will resolve from this index;
everything else (compilers' tool-requires, `cmake`, transitive C++ libs) comes
from [ConanCenter](conan.io/center) as usual.

With the remote in place, kick off the ROS build from source. We pick the
`desktop` variant so we get `turtlesim`, `rviz2` and the rest of the demo
nodes out of the box:

```bash
conan install --requires=ros-kilted/2026.06.17 \
    --profile=ros-conan/profiles/ros \
    -o ros-kilted/*:variant=desktop \
    --build=missing
```

This compiles ROS Kilted and its dependencies from source, so expect it to
take a while. However, it is a one-time cost: the binaries land in your Conan
cache and are reused by every project that follows.

### Let's run `turtlesim` from the ros-kilted package

To run the classic [`turtlesim`](https://docs.ros.org/en/kilted/Tutorials/Beginner-CLI-Tools/Introducing-Turtlesim/Introducing-Turtlesim.html) demo, let's create a folder and drop a tiny `conanfile.txt` in it:

```
mkdir ros-demo && cd ros-demo
# Create conanfile.txt file as follows
```

**`conanfile.txt`**

```ini
[requires]
ros-kilted/2026.06.17

[options]
ros-kilted/*:variant=desktop

[layout]
cmake_layout
```

Install it. The heavy build already happened during setup, so this just
materializes the activation scripts and is essentially instant:

```bash
conan install --profile=../ros-conan/profiles/ros --build=missing
```

Activate the Conan run environment and launch turtlesim, exactly as the
official tutorials do:

- On Linux / macOS:

  ```bash
  source ./build/Release/generators/conanrun.sh  # Activates the environment
  ros2 run turtlesim turtlesim_node
  ```

- On Windows:

  ```bat
  .\build\generators\conanrun.bat  # Activates the environment
  ros2 run turtlesim turtlesim_node
  ```

In a second shell, drive the turtle around with the keyboard. Instead of
re-sourcing the `conanrun.sh/bat` script, you can use
[`conan run`](https://docs.conan.io/2/reference/commands/run.html) directly:

```bash
cd ros-demo
conan run "ros2 run turtlesim turtle_teleop_key" --profile=../ros-conan/profiles/ros
```

<figure class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2026-06-23/ros-kilted-turtlesim.jpg"
         style="display: block; margin-left: auto; margin-right: auto;"
         alt="turtlesim window after moving it with conan run ros2 run turtlesim turtle_teleop_key"/>
    <figcaption style="text-align: center; font-size: 0.9em;">
        turtlesim window after moving it with <code>conan run "ros2 run turtlesim turtle_teleop_key"</code>
    </figcaption>
</figure>

## Tutorial: a brand-new C++ ROS node with a native C++ workflow

Let's build a minimal ROS node from scratch, in pure CMake, consuming
`ros-kilted` from Conan.

### 1. Project layout

Let's use the `ros-demo` already created directory:

```text
ros-demo/
├── conanfile.txt
├── CMakeLists.txt
└── src/
    └── main.cpp
```

### 2. Conan recipe

The `conanfile.txt` declares a single requirement on `ros-kilted` and uses the
standard CMake generators with as CMake layout:

**`conanfile.txt`**

```ini
[requires]
ros-kilted/2026.06.17

[options]
ros-kilted/*:variant=desktop

[generators]
CMakeToolchain
CMakeDeps
VCVars

[layout]
cmake_layout
```

### 3. CMake

The CMake side does not know anything about ROS being delivered through Conan:
it is just a plain `find_package(rclcpp)`. The `rclcpp::rclcpp` target is
provided by the `CMakeDeps` generator.

**`CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.22)
project(my_ros2_node CXX)

find_package(rclcpp REQUIRED)

add_executable(my_ros2_node src/main.cpp)
target_link_libraries(my_ros2_node PRIVATE rclcpp::rclcpp)
```

### 4. Source code

A minimal node that initializes `rclcpp`, logs one line, and shuts down:

**`src/main.cpp`**

```cpp
#include <memory>

#include <rclcpp/rclcpp.hpp>

int main(int argc, char ** argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<rclcpp::Node>("my_ros2_node");
    RCLCPP_INFO(node->get_logger(), "Hello from a Conan-powered ROS node!");
    rclcpp::shutdown();
    return 0;
}
```

### 5. Build and run

From the `ros-demo` directory, install the dependencies:

```bash
conan install --profile=../ros-conan/profiles/ros --build=missing
```

And build the project with CMake as usual:

```bash
#macOS, Linux
cmake --preset conan-release
cmake --build --preset conan-release

#Windows
cmake --preset conan-default
cmake --build --preset conan-release

The `cmake_layout` generator drops the binary under `build/Release` (or the
equivalent multi-config path on Windows). Run it directly:

- On Linux / MacOS:

  ```bash
  source ./build/Release/generators/conanrun.sh
  ./build/Release/my_ros2_node
  ```

- On Windows:

  ```bat
  .\build\generators\conanrun.bat
  build\Release\my_ros2_node.exe
  ```

You should see the familiar ROS log line:

```text
[INFO] [...] [my_ros2_node]: Hello from a Conan-powered ROS node!
```

There you go! A full native C++ development workflow to create a ROS node. No `colcon`,
no workspace, no `ament_cmake`... just a `find_package(rclcpp)` in `CMakeLists.txt`,
a `conan install` pure CMake build commands.

## Beyond hello-world: composing with the rest of ConanCenter

The interesting payoff of having ROS as just-another-Conan-package is that the
rest of ConanCenter is one `self.requires(...)` away. The
[`pose_estimation`](https://github.com/conan-io/ros-conan/tree/main/examples/pose_estimation)
example in the `ros-conan` repository combines `ros-kilted`,
[`opencv`](https://conan.io/center/recipes/opencv) and
[`tensorflow-lite`](https://conan.io/center/recipes/tensorflow-lite) in a
single dependency graph to publish a skeleton overlay from a webcam feed.

**`conanfile.txt`**

```ini
[requires]
ros-kilted/2026.06.17
tensorflow-lite/2.12.0
opencv/4.9.0

...
```

There is no special integration glue between the robotics stack and the computer vision stack,
it is all just Conan requirements.

<figure class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2026-06-23/pose-estimation-ros-kilted-rviz2.jpg"
         style="display: block; margin-left: auto; margin-right: auto;"
         alt="Video frame with a 2D skeleton overlay computed via OpenCV and TensorFlow Lite and its visualization in Rviz2"/>
    <figcaption style="text-align: center; font-size: 0.9em;">
        Video frame with a 2D skeleton overlay computed via OpenCV and TensorFlow Lite and its visualization in Rviz2
    </figcaption>
</figure>

### Prefer `colcon`? It still works

The pure-CMake flow above is the simplest way to embed `rclcpp` into an
existing C++ codebase, but it is not the only option.

The [`consumer_colcon`](https://github.com/conan-io/ros-conan/tree/main/examples/consumer_colcon)
example walks through a `colcon` workspace with `ament_cmake` packages that uses the `ros-kilted`
Conan package as well.

## Try it and keep using the official ROS docs

The whole point of this integration is that developing with ROS is no longer
a path full of custom tools and steps, it is integrated into a common
C++ development workflow.

Once `ros-kilted` is installed with Conan, the usual CMake commands are the only
thing needed to get your robot node running. Furthemore, nothing else changes:
`rclcpp`, `ros2` commands, `rvi2`, message generation, lifecycle nodes, parameters,
launch files: they all behave as the [official ROS tutorials](https://docs.ros.org/en/kilted/Tutorials.html)
describe.

We encourage you to clone [conan-io/ros-conan](https://github.com/conan-io/ros-conan),
follow the steps described in this post and build your first ROS node using Conan!

We would love to hear your feedback on the recipe and the workflow. If you hit
something that does not work, or a feature that is missing, please open an issue at
[conan-io/ros-conan/issues](https://github.com/conan-io/ros-conan/issues).

Happy hacking, and happy robotics!
