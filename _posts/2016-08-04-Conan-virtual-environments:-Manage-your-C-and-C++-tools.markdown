---
layout: post
comments: true
title: "Conan virtual environments: Manage your C and C++ tools"
---

The benefit of using a package manager like conan is, in addition to many other advantages, manage your project dependencies. You can build your project even in different computers and with different operating systems just running ``conan install`` command again.

But that's not completely true, you usually need some tools like a compiler and maybe a separate build system to build your project. 
So, if you change your computer you will need to setup your build tools with the system package manager (apt, yum...) or downloading the installers, etc.

In the latest 0.11 release, we've introduced some minor changes to conan to try to help our users to reproduce their environments easily. We don't pretend to replace the current applications managers; yum, apt, brew...etc, are GREAT tools, but maybe conan users can benefit of custom and easy installers for the applications that they use to build software.

Conan has a new generator called ``virtualenv``, inspired in python virtual environments that we really love. This generator can be activated like any other in the [generators] section of your conanfile, and will generate two files: ``activate.[sh|bat]`` and ``deactivate.[sh|bat]``. 
If we run the activate script, conan will set our current shell environment variables with the values that the installed packages declare. The most common usage would be setting the PATH environment variable, so tools can be easily executed.

Let's see an example. Lets suppose we are working on a Windows machine, and we want to build and test a project with different versions of MinGW and CMake. So we can do:

Create a separate folder from your project. This folder will handle our development environment. 

{% highlight bash %}

$ mkdir my_cpp_environ
$ cd my_cpp_environ

{% endhighlight %}

Now, create a ``conanfile.txt`` file:

{% highlight conf %}

[requires]
mingw_installer/0.1@lasote/testing
cmake_installer/0.1@lasote/testing

[generators]
virtualenv

{% endhighlight %}

In this file we are requiring two packages, one is the MinGW installer and the other is a CMake installer. The "0.1" version is the version of the installer recipe, not the MinGW nor CMake tools. If you want to create your own recipes matching the tool version, you can, but in this way we are able to handle many MinGW and CMake versions just with the same recipes. Later we will se how can we install those different versions.

Install the packages:

{% highlight bash %}

$ conan install

{% endhighlight %}

Once the tools have been installed, you can activate the virtual environment in your shell:

{% highlight bash %}

$ activate
(my_cpp_environ) $

{% endhighlight %}

Check that everything is working and the tools are in the path:

{% highlight bash %}
(my_cpp_environ) $ gcc --version

> gcc (x86_64-posix-sjlj-rev1, Built by MinGW-W64 project) 4.9.2
 Copyright (C) 2014 Free Software Foundation, Inc.
 This is free software; see the source for copying conditions.  There is NO
 warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

{% endhighlight %}

{% highlight bash %}

(my_cpp_environ) $ cmake --version
cmake version 3.6.0

CMake suite maintained and supported by Kitware (kitware.com/cmake).

{% endhighlight %}

You can now deactivate the virtual environment with the ``deactivate`` script

{% highlight bash %}

(my_cpp_environ) $ deactivate

{% endhighlight %}

The same can be done (with CMake, because MinGW is just for Windows), in Linux/OSx.
If you are a Conan user you will know that every package depends on the settings and options. So, we can change the available options to get a different MinGW version easily.

Let's take a look to the MinGW installer recipe. Go to (https://www.conan.io/source/mingw_installer/0.1/lasote/testing) and click in "conanfile.py" tab.

We have available these options:

{% highlight conf %}

options = {"threads": ["posix", "win32"],
          "exception": ["dwarf2", "sjlj", "seh"], 
          "arch": ["x86", "x86_64"],
          "version": ["4.8", "4.9"]}
default_options = "exception=sjlj", "threads=posix", "arch=x86_64", "version=4.9"
       
{% endhighlight %}

By default we are installing MinGW 4.9 with posix thread support and sjlj exceptions. But we can install MinGW with other options:

Edit your conanfile.txt:

{% highlight conf %}

[requires]
mingw_installer/0.1@lasote/testing
cmake_installer/0.1@lasote/testing

[generators]
virtualenv

[options]
mingw_installer:threads=win32
mingw_installer:version=4.8

{% endhighlight %}

Remember to deactivate the previous virtual environment:

{% highlight bash %}

(my_cpp_environ) $ deactivate

{% endhighlight %}

And install again:

{% highlight bash %}

$ conan install

{% endhighlight %}

You can also pass the options in the command line instead of specifying them in the conanfile.txt file


Activate the virtual environment and check that the tools have changed:

{% highlight bash %}

$ activate
(my_cpp_environ) $ gcc --version

> gcc (rev0, Built by MinGW-W64 project) 4.8.2
Copyright (C) 2013 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

{% endhighlight %}

You can share this ``conanfile.txt`` with your team and share this way the development environment!

How can I create my own tool packages?
-------------------------------------------------------------------------------

If you want to create conan packages for any tool it is easy, specially if you are already familiar creating conan packages.

Let's see how the conan <a href="https://www.conan.io/source/cmake_installer/0.1/lasote/testing">CMake recipe is done</a>:

{% highlight python %}

from conans import ConanFile
import os

class CMakeInstallerConan(ConanFile):
    name = "cmake_installer"
    version = "0.1"
    license = "MIT"
    url = "http://github.com/lasote/conan-cmake-installer"
    settings = {"os": ["Windows", "Linux", "Macos"], "arch": ["x86", "x86_64"]}
    options = {"version": ["3.6.0", "3.5.2", "3.4.3", "3.3.2", 
                           "3.2.3", "3.1.3", "3.0.2", "2.8.12"]}
    default_options = "version=3.6.0"
    
    def config(self):
        if self.settings.os == "Macos" and self.settings.arch == "x86":
            raise Exception("Not supported x86 for OSx")
        if self.settings.os == "Linux" and self.options.version == "2.8.12" and self.settings.arch == "x86_64":
            raise Exception("Not supported 2.8.12 for x86_64 binaries")

    def get_filename(self):
        os = {"Macos": "Darwin", "Windows": "win32"}.get(str(self.settings.os), str(self.settings.os))
        arch = {"x86": "i386"}.get(str(self.settings.arch), 
                                   str(self.settings.arch)) if self.settings.os != "Windows" else "x86"
        return "cmake-%s-%s-%s" % (self.options.version, os, arch)
    
    def build(self):
        keychain = "%s_%s_%s" % (self.settings.os,
                                 self.settings.arch,
                                 str(self.options.version))
        minor = str(self.options.version)[0:3]
        ext = "tar.gz" if not self.settings.os == "Windows" else "zip"
        url = "https://cmake.org/files/v%s/%s.%s" % (minor, self.get_filename(), ext)

        dest_file = "file.tgz" if self.settings.os != "Windows" else "file.zip"
        self.output.warn("Downloading: %s" % url)
        tools.download(url, dest_file)
        tools.unzip(dest_file)
    
    def package(self):
        self.copy("*", dst="", src=self.get_filename())

    def package_info(self):
        self.env_info.path.append(os.path.join(self.package_folder, "bin"))
   
{% endhighlight %}

The config method is avoiding some setting/options combinations throwing an exception.
The build method is downloading the right CMake file and unzipping it.
The package method is copying all the files from the zip to the package folder.
The package info is using the “self.env_info” to append to the environment variable “path” the package’s bin folder.

This package have only 2 different things than a regular conan library package:

The source method is missing. That’s because when you compile a library, the source code is always the same for all the generated packages, but, in this case we are downloading the binaries, so we do it in the build method to download the different zip file for each settings/option combination. Instead of really building the tools, we are just downloading them. Of course if you want to build it from source, you can do it too, create your own package recipe
The package_info method use the new ``self.env_info`` object. 
With “self.env_info” the package can declare environment variables that will be setted with the ``virtualenv`` generator.

The ``self.env_info`` variable can also be useful if a package tool depends on another tool.
Take a look to the <a href="https://www.conan.io/source/mingw_installer/0.1/lasote/testing">MinGW conanfile.py recipe</a>:

{% highlight python %}

class MingwinstallerConan(ConanFile):
    name = "mingw_installer"
    version = "0.1"
    license = "MIT"
    url = "http://github.com/lasote/conan-mingw-installer"
    settings = {"os": ["Windows"]}
    options = {"threads": ["posix", "win32"],
               "exception": ["dwarf2", "sjlj", "seh"], 
               "arch": ["x86", "x86_64"],
               "version": ["4.8", "4.9"]}
    default_options = "exception=sjlj", "threads=posix", "arch=x86_64", "version=4.9"

    def config(self):
        self.requires.add("7z_installer/0.1@lasote/testing", private=True)
        …
   
    def build(self):
        ...
        
        tools.download(files[keychain], "file.7z")
        env = ConfigureEnvironment(self)
        self.run("%s && 7z x file.7z" % env.command_line)
    
    def package(self):
        self.copy("*", dst="", src="mingw32")
        self.copy("*", dst="", src="mingw64")

    def package_info(self):
        self.env_info.path.append(os.path.join(self.package_folder, "bin"))
        self.env_info.CXX = os.path.join(self.package_folder, "bin", "g++.exe")
        self.env_info.CC = os.path.join(self.package_folder, "bin", "gcc.exe")

{% endhighlight %}


In the config method we are adding a require to another package, the 7z_installer that will be used to unzip the mingw installers (with 7z compression).

In the build method we are downloading the right MinGW installer and using the helper 
``ConfigureEnvironment``. This helper will provide us a string with a command to set the environment variables. That means that the 7z executable will be in the path, because the 7z_installer dependency declares the ``bin`` folder in its ``package_info()`` method.

In the package_info method we are declaring CC and CXX variables, used by CMake, autotools etc, to locate the compiler for C/C++ respectively. 
Also we are appending to ``path`` variable the bin folder, so we can invoke gcc, g++, make and other tools in the command line using the virtualenv generator when we execute the ``activate`` script.

The possibilities of these features are even larger. They are very useful for example in CI environments. Also, if you want to avoid copying shared (.dlls, .dylib) libraries to the project binary directory (which can be done with the ``imports`` feature), you can make packages to add them to the environment PATH variable, so consumers can use it to easily find the correct shared libraries for multiple different versions and settings.

What do you think? Do you like this feature? What tools would you like to have as a conan package? Use our https://github.com/conan-io/wishlist whislist and tell us what is your development environment!
