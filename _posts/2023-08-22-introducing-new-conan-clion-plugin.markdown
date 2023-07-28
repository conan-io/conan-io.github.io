---
layout: post
comments: false
title: "Introducing the new Conan CLion Plugin compatible with 2.X"
meta_title: "Unveiling the new Conan CLion Plugin for seamless C++ package management - Conan Blog"
description: "Discover how the new Conan CLion plugin 2.X enhances C++ development, with a practical example using OpenCV and a library for loading images from the internet."
---

In this post, we are thrilled to announce the launch of the new version of the Conan CLion
Plugin, now compatible with the 2.X versions of Conan. The new plugin is designed to bring
more ease and control to developers using CLion and Conan for C++ projects. We will walk
you through the process of using this plugin with a practical example that uses
[libcurl](https://curl.se/libcurl/) and [stb](https://github.com/nothings/stb) to download
an image from the Internet, load it, and print it as ASCII art in the console.

## How the plugin works

Before explaining how to install, configure and use the plugin, let's briefly discuss how
it integrates Conan with CMake to create a seamless experience. This plugin utilizes
[cmake-conan](https://github.com/conan-io/cmake-conan/tree/develop2), a [CMake dependency
provider](https://cmake.org/cmake/help/latest/guide/using-dependencies/index.html#dependency-providers)
for the Conan C and C++ package manager. It injects ``conan_provider.cmake`` using the
``CMAKE_PROJECT_TOP_LEVEL_INCLUDES`` definition. This dependency provider will translate
the CMake configuration to Conan. For instance, if you select a *Debug* profile in CLion,
Conan will install and use the packages for *Debug*. 

Bear in mind that *cmake-conan* activates the Conan integration everytime CMake calls to
``find_package()``, that means that no library will be installed until the CMake configure
step runs, and at that point Conan will try to install the required libraries and build
them if it is nedeed.

Also, note that as dependency providers are a relatively new feature in CMake, you will need
CMake version >= 3.24 and Conan >= 2.0.5.

**Missing schematic of translating CLion profiles to CMake settings and then to Conan?**

## Installing the plugin

To install the new Conan CLion plugin, navigate to the JetBrains marketplace. Open CLion,
go to *Settings > Plugins*, then select the *Marketplace* tab. Search for the Conan plugin
and click on the Install button. After restarting CLion, a new “Conan” tool tab will
appear at the bottom of the IDE.

**Missing screen capture here!**

## Creating a new CMake project

First, create a new CMake project in CLion, as usual. 

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-08-22/clion-new-project.png" style="display: block; margin-left: auto; margin-right: auto;" alt="CLion new CMake project"/>
</p>

Then select the project location and the language standard you want to use and click on
"Create".

## Configuring the plugin

Go to the “Conan” tool tab in the bottom of the IDE. You will see that the only enabled
action in the toolbar of the plugin is the one with the 🔧 (wrench) symbol, click on it. 

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-08-22/clion-configuration-1.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Click wrench symbol"/>
</p>

The first thing you should do there is configuring the Conan client executable that's
going to be used. You can point to one specific installed in an arbitrary location on your
system or you can select *"Use Conan installed in the system"* to use the one installed at
system level.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-08-22/clion-configuration-2.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Click wrench symbol"/>
</p>

You will find there some options marked as default. Let's go through all of them.

- First, you will see checkboxes to mark in which configurations should Conan manage the
  dependencies. In our case, as we only have the Debug configuration, it's the only one
  checked. Also, below that "Automatically add Conan support for all configurations" is
  marked by default. That means that if you don't have to worry about adding Conan support
  to new build configurations because the plugin will automatically add Conan support by
  default.

- You can also see that there's a checkbox to let Conan change the default CLion settings
  and run CMake sequentially instead of running it on parallel. This is needed as the
  Conan cache is not still concurrent up to Conan 2.0.9 version.

Normally, if you are using the Conan plugin, you don't want to unmark them. So leave them
and let's create our project and add the libraries to it. So, click on the OK button and
the plugin should be ready to use.

After doing the initial configuration, you will notice that the list of libraries is now
enabled and that the 🔄 (update) and 👁️ (inspect) symbols are also enabled. We will
explain them later in detail.

## Using the plugin

Let's explore the plugin's usage with an example. 

## Conclusions

The new Conan CLion plugin, compatible with 2.X versions, is designed to bring more
seamless integration between the Conan package manager and CLion IDE. The plugin provides
a more intuitive interface, making it easier to handle your dependencies directly within
CLion. We hope this tool improves your development experience, and we look forward to
seeing what you will build with it!


