---
layout: post
comments: false
title: "Introducing the new Conan CLion Plugin compatible with 2.X"
meta_title: "Unveiling the new Conan CLion Plugin for seamless C++ package management - Conan Blog"
description: "Discover how the new Conan CLion plugin 2.X enhances C++ development, with a practical example using OpenCV and a library for loading images from the internet."
---

In this post, we're thrilled to announce the launch of the new version of Conan CLion
Plugin, which is now compatible with the 2.X versions of Conan. The new plugin is designed
to bring more ease and control to developers using CLion and Conan for C++ projects. We're
going to walk you through the process of using this plugin with a practical example that
uses [libcurl](https://curl.se/libcurl/) and [stb](https://github.com/nothings/stb) to
download an image from the Internet, load it, and print it as ASCII art in the console.

## Installing the plugin

To install the new Conan CLion plugin, navigate to the JetBrains marketplace. To do so,
open CLion and go to *Settings > Plugins*, the select the *Marketplace* tab and search for
the Conan plugin, the click on the Install button. After restarting CLion a new “Conan”
tool tab will appear at the bottom of the IDE.

**Missing screen capture here!**

## How the plugin works

Before using how to configure and use the plugin we will briefly explain how it integrates
Conan with CMake to make using it a seamless experience. This plugin makes use of
[cmake-conan](https://github.com/conan-io/cmake-conan/tree/develop2) which is a [CMake
dependency
provider](https://cmake.org/cmake/help/latest/guide/using-dependencies/index.html#dependency-providers)
for the Conan C and C++ package manager. It works by injecting ``conan_provider.cmake``
using the ``CMAKE_PROJECT_TOP_LEVEL_INCLUDES`` definition. This dependency provider will
translate the CMake configuration to Conan so that, for example, if you select a Debug
profile in CLion, Conan will install and use the packages for Debug.

Be aware that, as dependency providers is a relatively new feature in CMake, you will need
at a CMake version >= 3.24 and Conan >= 2.0.5.

**Missing schematic of translating CLion profiles to CMake settings and then to Conan?**

## Configuring the plugin

## Using the plugin

## Conclusions

The new Conan CLion plugin, compatible with 2.X versions, is designed to bring more
seamless integration between the Conan package manager and CLion IDE. The plugin provides
a more intuitive interface, making it easier to handle your dependencies directly within
CLion. We hope this tool improves your development experience, and we look forward to
seeing what you will build with it!


