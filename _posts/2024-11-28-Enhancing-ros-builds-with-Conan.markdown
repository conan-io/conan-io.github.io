---
layout: post
comments: false
title: "Enhancing ROS development with Conan packages"
meta_title: "Conan introduces new integration for ROS to enhance robotics development."
description: "Conan has introduced a new integration for ROS (Robot Operating System) to incorporate packages from Conan Center to any robotics development in C++."
keywords: "conan, ros, ros2, robots, robotics, c++, packages, libraries"
---

When we think about development in C or C++, we immediately associate it with programming for industrial systems and embedded devices.
Indeed, it is in this area where the language is extensively used, and this inevitably includes its application in robotics.

In this context, there is no doubt that [ROS (Robot Operating System)](https://ros.org/) is the most well-known framework and probably one of the most widely used. It enables the integration of different hardware components into a single system, allowing them to function seamlessly together. This makes development in robotics more efficient, as it allows for the reuse of each component's software across projects for various robotic applications.

This is why the Conan team is thrilled to present this integration of Conan with ROS. Many members of our team come from industrial engineering and we are passionate about this area, so being able to contribute to robotics through Conan makes us very happy.
In this post, we will discuss the different components that make up ROS development, how they work, and how Conan integrates into these projects to manage third-party libraries.


## A Quick Primer on ROS2 Packages and Workspaces

Let's start with a brief overview for those less familiar with the ROS2 ecosystem.

ROS organizes code into packages, each containing a package.xml with some metadata, executables, libraries, or other resources like launch files. These packages are typically managed within a **workspace**, allowing developers to build and run their robot applications. The key components of the workflow are:

- **CMake for builds**: ROS2 heavily relies on CMake as its build system for C/C++ packages, using CMakeLists.txt files to define the build logic.

- **Ament build tools**: The Ament build tools is a framework of CMake macros and functions that standardize and simplify package-level tasks
  such as linking dependencies, installation and export of artifacts or integration with ROS-specific tools like `rosidl`.

- **Colcon**: It's the main build tool that orchestrates the build of multiple
  packages inside a workspace. It is able to inspect the packages
  and its dependencies and launch the builds in the correct order. It can also overlay
  additional packages on top of their existing workspace
  without disrupting the core system.

## A small example of building a ROS package

For readers unfamiliar with ROS, we would like to show how a ROS package can be created and built to get to know the process. We will showcase the Conan integration later in the example.

We will need a **Linux environment with the ROS2 Humble version installed**. If you are running in another system or just for convenience, you can also build and run the commands using this dockerfile:

#### _`Dockerfile`_
```dockerfile
FROM osrf/ros:humble-desktop
RUN apt-get update && apt-get install -y \
curl \
python3-pip \
git \
ros-humble-nav2-msgs \
&& rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip && pip3 install conan
RUN conan profile detect
CMD ["bash"]
```

> You can build and run the docker image using ``docker build -t conanio/ros-humble .``, and run it with ``docker run -it conanio/ros-humble``

First, we create a workspace `navigation_ws` folder, set the environment of your ROS installation, and create a package:

```sh
$ mkdir /home/navigation_ws && cd /home/navigation_ws
$ source /opt/ros/humble/setup.bash
$ ros2 pkg create --build-type ament_cmake --node-name navigator navigation_package
```

These are the files that should be in your workspace. As indicated in this post, you can inspect them to understand the contents.

```txt
navigation_ws/
  navigation_package/
    CMakeLists.txt
    package.xml
    src/
      navigator.cpp
```

Now we can invoke ``colcon`` to perform the build

```sh
$ colcon build --packages-select navigation_package
Starting >>> navigation_package
Finished <<< navigation_package [1.21s]

Summary: 1 package finished [1.60s]
```

Finally, before executing the binary, we have to set the environment for the executable (so it is able to locate any shared library that it may
have) and then we execute it:

```sh
$ source install/setup.bash
$ ros2 run navigation_package navigator
hello world navigation_package package
```

## An example of using ROS with Conan

Let's say we want to include an external library using Conan. In this case, we would create a navigation node that sends locations goals from a
yaml file to our mobile robot.

The code for this example can be found at <https://github.com/conan-io/examples2/tree/main/examples/tools/ros/rosenv/navigation_ws>

_`navigation_ws/navigation_package/locations.yaml`_

```yaml
locations:
  - name: "Kitchen"
    x: 3.5
    y: 2.0
  - name: "Living Room"
    x: 1.0
    y: -1.0
  - name: "Bedroom"
    x: -2.0
    y: 1.5
```

And we will use the [``yaml-cpp`` library from Conan Center](https://conan.io/center/recipes/yaml-cpp). For that, we need to include a _conanfile.txt_ file next to the _CMakeLists.txt_ of our project:

_`navigation_ws/navigation_package/conanfile.txt`_

```txt
[requires]
yaml-cpp/0.8.0

[generators]
CMakeDeps
CMakeToolchain
ROSEnv
```

As you can see, we are listing our dependencies under the ``[requires]`` section and we are also adding the required generators, that _translate_ the information of the files in a package: libraries, headers, executables… into a file format that is suitable for the build system or the environment of the consumer):

- The **CMake ones** will generate the files so that the ``yaml-cpp`` package can be included in our project using ``find_package()``.

- The **ROSEnv generator** will create a shell script with the environment variables needed to perform the build.

In the _CMakeLists.txt_, we will need to include the **ROS client libraries**, the [ROS nav2_msgs](https://index.ros.org/p/nav2_msgs/) and also the [``yaml-cpp`` library from Conan](https://conan.io/center/recipes/yaml-cpp):

_`navigation_ws/navigation_package/CMakeLists.txt`_
```txt
cmake_minimum_required(VERSION 3.8)
project(navigation_package)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ROS dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(nav2_msgs REQUIRED)

# Conan dependencies
find_package(yaml-cpp REQUIRED)

add_executable(navigator src/navigator.cpp)

target_compile_features(navigator PUBLIC c_std_99 cxx_std_17)  # Require C99 and C++17
ament_target_dependencies(navigator rclcpp rclcpp_action nav2_msgs yaml-cpp)

install(TARGETS navigator
  DESTINATION lib/${PROJECT_NAME})

ament_package()
```

> **Note**:\
  In the case that we have to propagate the Conan packages as transitive dependencies for other ROS packages that depend on this one (in the case that ``navigation_package`` was a library):\
\
    ``Other ROS Package`` → ``navigation_package`` → ``yaml-cpp Conan Package``\
\
We can use the ament helper `ament_export_dependencies()` to export the Conan targets as we would do with a normal ROS package. You can read more about it in our documentation: <https://docs.conan.io/2/integrations/ros.html>

Now we install the ``yaml-cpp`` Conan package like so:

```sh
$ conan install navigation_package/conanfile.txt --build missing --output-folder install/conan
======== Input profiles ========
Profile host:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux

Profile build:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux


======== Computing dependency graph ========
yaml-cpp/0.8.0: Not found in local cache, looking in remotes...
yaml-cpp/0.8.0: Checking remote: conancenter
yaml-cpp/0.8.0: Downloaded recipe revision 720ad361689101a838b2c703a49e9c26
Graph root
    conanfile.txt: /navigation_ws/navigation_package/conanfile.txt
Requirements
    yaml-cpp/0.8.0#720ad361689101a838b2c703a49e9c26 - Downloaded (conancenter)

======== Computing necessary packages ========
yaml-cpp/0.8.0: Main binary package '8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe' missing
yaml-cpp/0.8.0: Checking 9 compatible configurations
yaml-cpp/0.8.0: Compatible configurations not found in cache, checking servers
yaml-cpp/0.8.0: '51ede47d8b958f4d476f9e327b0cf6c475a9d34b': compiler.cppstd=11
yaml-cpp/0.8.0: '9c2f25d016393b8d4be76305d23f60f457cc5612': compiler.cppstd=gnu11
yaml-cpp/0.8.0: 'c01616259c2d166eadec282346c9fb6dce0e3530': compiler.cppstd=14
yaml-cpp/0.8.0: '99c9bcacb68e3379fad0ffaab3c0268baafd0cd2': compiler.cppstd=gnu14
yaml-cpp/0.8.0: '13be611585c95453f1cbbd053cea04b3e64470ca': compiler.cppstd=17
yaml-cpp/0.8.0: Found compatible package '13be611585c95453f1cbbd053cea04b3e64470ca': compiler.cppstd=17
Requirements
    yaml-cpp/0.8.0#720ad361689101a838b2c703a49e9c26:13be611585c95453f1cbbd053cea04b3e64470ca#971e8e22b118a337b31131ab432a3d5b - Download (conancenter)

======== Installing packages ========

-------- Downloading 1 package --------
yaml-cpp/0.8.0: Retrieving package 13be611585c95453f1cbbd053cea04b3e64470ca from remote 'conancenter'
yaml-cpp/0.8.0: Package installed 13be611585c95453f1cbbd053cea04b3e64470ca
yaml-cpp/0.8.0: Downloaded package revision 971e8e22b118a337b31131ab432a3d5b
WARN: deprecated: Usage of deprecated Conan 1.X features that will be removed in Conan 2.X:
WARN: deprecated:     'cpp_info.build_modules' used in: yaml-cpp/0.8.0

======== Finalizing install (deploy, generators) ========
conanfile.txt: Writing generators to /navigation_ws/install/conan
conanfile.txt: Generator 'CMakeDeps' calling 'generate()'
conanfile.txt: CMakeDeps necessary find_package() and targets for your CMakeLists.txt
    find_package(yaml-cpp)
    target_link_libraries(... yaml-cpp::yaml-cpp)
conanfile.txt: Generator 'CMakeToolchain' calling 'generate()'
conanfile.txt: CMakeToolchain generated: conan_toolchain.cmake
conanfile.txt: CMakeToolchain: Preset 'conan-release' added to CMakePresets.json.
    (cmake>=3.23) cmake --preset conan-release
    (cmake<3.23) cmake <path> -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake  -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_BUILD_TYPE=Release
conanfile.txt: CMakeToolchain generated: /navigation_ws/install/conan/CMakePresets.json
conanfile.txt: CMakeToolchain generated: /navigation_ws/navigation_package/CMakeUserPresets.json
conanfile.txt: Generator 'ROSEnv' calling 'generate()'
conanfile.txt: Generated ROSEnv Conan file: conanrosenv.sh
Use 'source /navigation_ws/install/conan/conanrosenv.sh' to set the ROSEnv Conan before 'colcon build'
conanfile.txt: Generating aggregated env files
conanfile.txt: Generated aggregated env files: ['conanbuild.sh', 'conanrun.sh']
Install finished successfully
```

With this install command, Conan has performed some actions:
1. **Search** for packages in [Conan Center](https://conan.io/center), the central repository where OSS packages are contributed, that are suitable for your configuration.
2. **Download** the packages into the Conan cache locally in your machine.
3. **Generate** the environment and CMake files needed for your ROS project in the _install/conan_ folder.

Finally, let's add the code for our node to the _main.cpp_ file:

**`navigation_ws/my_package/src/main.cpp`**

```cpp
#include <string>
#include <vector>

#include <rclcpp/rclcpp.hpp>
#include <nav2_msgs/action/navigate_to_pose.hpp>
#include <rclcpp_action/rclcpp_action.hpp>

#include <yaml-cpp/yaml.h>

using NavigateToPose = nav2_msgs::action::NavigateToPose;


class YamlNavigationNode : public rclcpp::Node {
public:
    YamlNavigationNode(const std::string &yaml_file_path) : Node("yaml_navigation_node") {
        // Create action client
        action_client_ = rclcpp_action::create_client<NavigateToPose>(this, "navigate_to_pose");

        // Read locations from YAML file
        RCLCPP_INFO(this->get_logger(), "Reading locations from YAML...");
        if (!loadLocations(yaml_file_path)) {
            RCLCPP_ERROR(this->get_logger(), "Failed to load locations.");
            return;
        }

        if (locations_.empty()) {
            RCLCPP_ERROR(this->get_logger(), "No locations found in the YAML file.");
            return;
        }

        sendAllGoals();
    }

private:
    struct Location {
        std::string name;
        double x;
        double y;
    };

    std::vector<Location> locations_;
    rclcpp_action::Client<NavigateToPose>::SharedPtr action_client_;

    bool loadLocations(const std::string &file_path) {
        try {
            YAML::Node yaml_file = YAML::LoadFile(file_path);
            for (const auto &node : yaml_file["locations"]) {
                Location location;
                location.name = node["name"].as<std::string>();
                location.x = node["x"].as<double>();
                location.y = node["y"].as<double>();
                locations_.emplace_back(location);
            }
            return true;
        } catch (const std::exception &e) {
            RCLCPP_ERROR(this->get_logger(), "Error parsing YAML: %s", e.what());
            return false;
        }
    }

    void sendAllGoals() {
        for (const auto &location : locations_) {
            RCLCPP_INFO(this->get_logger(), "Sending goal to %s: (%.2f, %.2f)", location.name.c_str(), location.x, location.y);

            auto goal_msg = NavigateToPose::Goal();
            goal_msg.pose.header.frame_id = "map";
            goal_msg.pose.header.stamp = this->now();
            goal_msg.pose.pose.position.x = location.x;
            goal_msg.pose.pose.position.y = location.y;
            goal_msg.pose.pose.orientation.w = 1.0;

            action_client_->async_send_goal(goal_msg);
        }

        RCLCPP_INFO(this->get_logger(), "All goals have been sent.");
    }
};


int main(int argc, char **argv) {
    rclcpp::init(argc, argv);

    if (argc < 2) {
        RCLCPP_ERROR(rclcpp::get_logger("yaml_navigation_node"), "Usage: yaml_navigation_node <yaml_file_path>");
        return 1;
    }

    std::string yaml_file_path = argv[1];
    std::make_shared<YamlNavigationNode>(yaml_file_path);

    rclcpp::shutdown();
    return 0;
}
```

The node will read the locations from the YAML file and send them as navigation goals for our robot.

We can build our ROS package as usual, just source the conanrosenv.sh file before. This will set the environment so CMake can find the files generated by Conan.

```sh
$ source install/conan/conanrosenv.sh
$ colcon build --packages-select navigation_package
Starting >>> navigation_package
Finished <<< navigation_package [16.3s]

Summary: 1 package finished [16.7s]
```

Now it is finally time to run our executable:

```sh
$ source install/setup.bash
$ ros2 run navigation_package navigator navigation_package/locations.yaml
[INFO] [1732633293.207085200] [yaml_navigation_node]: Reading locations from YAML...
[INFO] [1732633293.208468700] [yaml_navigation_node]: Sending Kitchen goal (3.50, 2.00) to robot
[INFO] [1732633293.208949200] [yaml_navigation_node]: Sending Living Room goal (1.00, -1.00) to robot
[INFO] [1732633293.209244600] [yaml_navigation_node]: Sending Bedroom goal (-2.00, 1.50) to robot
[INFO] [1732633293.209548300] [yaml_navigation_node]: All goals have been sent.
```

## Conclusion

The new ROS integration for Conan offers a neat way of incorporating Conan packages to ROS packages. By simply including a conanfile, you can
install the required libraries from Conan Center.

Also, a package manager like Conan offers key advantages over system-package managers during the development of the ROS packages. With Conan,
you can **install different versions or flavors** of the packages **without interfering with the dependencies** across other projects. You can even **bring your own Conan packages as dependencies without disrupting the development workflow**.

With this integration, we hope to improve ROS package development even further. You can find more information about this integration in our documentation: <https://docs.conan.io/2/integrations/ros.html>.

If you have feedback, please submit an issue in the [Conan
repository](https://github.com/conan-io/conan) to help us improve the development experience. Thank you!
