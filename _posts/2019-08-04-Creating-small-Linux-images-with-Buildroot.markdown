---
layout: post
comments: false
title: "Creating small Linux images with Buildroot"
---

There are many embedded Linux distributions ready for use with good functionality, but at the cost of image size, some images can reach 4GB. Sometimes we want embedded systems that support Linux with only the minimum packages needed for our system, such as running a small FTP server with no graphical interface.

To fulfill the object of getting a custom image, we can automate and facilitate building a distro through some build tools for embedded Linux-based systems. Some existing ones today include [Yocto](https://www.yoctoproject.org/) and [Buildroot](https://buildroot.org/), which are open source projects.

In this blog post we will comment on using Buildroot and how we can use it to create a customized image for [RaspberryPi3](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/).

## Buildroot

<img src="{{ site.url }}/assets/buildroot-logo.png" style="width:200px;display: block;margin: 0 auto;"/>

Buildroot is a tool for automating the creation of Embedded Linux distributions. It builds the code for the architecture of the board so it was set up, all through an overview of Makefiles. In addition to being open-source, it is licensed under [GPL-2.0-or-later](https://spdx.org/licenses/GPL-2.0-or-later.html).

If you want to know more about cross-compilation process, we have a blog post about it [here](https://blog.conan.io/2017/03/30/Cross-building-and-debugging-C-C++-libraries-for-the-Raspberry-PI.html).

## How to Install

Before starting Buildroot installation, let's assume you have a Linux environment ready for building C projects, as well as tools for git, svn, and rsync.

You can get more information about the requirements through the official Buildroot [documentation](https://buildroot.org/downloads/manual/manual.html).

In order to install Buildroot, we will clone the repository through Github:

{% highlight bash %}

$ git clone https://github.com/buildroot/buildroot.git buildroot

{% endhighlight %}

## Analyzing the Buildroot

Once inside the Buildroot directory, we will have the following tree:

{% highlight text%}

buildroot/
|
├── arch
├── board
├── boot
├── configs
├── docs
├── linux
├── package
├── support
├── system
├── toolchain
└── utils

{% endhighlight %}

Each directory holds a set of files needed to set up a part of the build. Here we can highlight:

* board: Contains files for target board mapping and configuration, such as flash memory address and device tree files;
* configs: Contains a series of pre-set configurations to automate which packages and properties should be added to the embedded image;
* packages: Contains all official packages available so far for Buildroot. We are not limited to these packages only, Buildroot allows we to create new custom packages.

We will give more focus to package folder, as our main interest will be to customize the packages installed in our image.

As an example, let's look at the [fmt](https://github.com/fmtlib/fmt) package, which consists of 3 files:

{% highlight text%}

package/fmt/
|
├── Config.in
├── fmt.hash
└── fmt.mk

{% endhighlight %}

*Config.in* is the package description to be used for Buildroot configuration, it is responsible for maintaining the information for the user interface when choosing which packages to build. It also contains the package dependencies.

{% highlight text%}

config BR2_PACKAGE_FMT
    bool "fmt"
    depends on BR2_INSTALL_LIBSTDCPP
    depends on BR2_USE_WCHAR
    help
      fmt is an open-source formatting library for C++. It can be
      used as a safe alternative to printf or as a fast alternative
      to IOStreams.

      https://fmt.dev/latest/index.html

{% endhighlight %}

The *fmt.mk* file is the Makefile recipe for setting up, building, and installing the library.

{% highlight makefile%}

FMT_VERSION = 5.3.0
FMT_SITE = $(call github,fmtlib,fmt,$(FMT_VERSION))
FMT_LICENSE = BSD-2-Clause
FMT_LICENSE_FILES = LICENSE.rst
FMT_INSTALL_STAGING = YES

FMT_CONF_OPTS = \
    -DHAVE_OPEN=ON \
    -DFMT_INSTALL=ON \
    -DFMT_TEST=OFF

$(eval $(cmake-package))

{% endhighlight %}

This file stores default properties for all other packages, such as its version, site from which to download the source code, software license name, and where to find that license file.

Here you can see that at the end a module called **cmake-package** is invoked. This module is responsible for handling projects using [CMake](https://cmake.org/), where it will execute all necessary commands, from configuration to installation of artifacts. This modularization allows for a higher level of automation, otherwise it would be necessary to describe all CMake commands for each package.

The last and not the least file, *fmt.hash* holds the checksum of the downloaded file directly from the site.

{% highlight text%}

sha256 defa24a9af4c622a7134076602070b45721a43c51598c8456ec6f2c4dbb51c89  fmt-5.3.0.tar.gz
sha256 560d39617dfb4b4e4088597291a070ed6c3a8d67668114ed475c673430c3e49a  LICENSE.rst

{% endhighlight %}

Although we are using SHA-256, Buildroot is able to support other formats like SHA-1 and MD5. The checksum is automatically verified by Buildroot during package download. If the value found is not the same as described, an error will be raised.

## Configuring the Custom Image

As our target platform is RaspberryPi3, Buildroot offers a pre-configured file for this board, which is located within the configs directory.

To ask Buildroot that we want to build our configuration from RaspberryPi3, we should use the following command:

{% highlight bash %}

$ make raspberrypi3_defconfig

{% endhighlight %}

Once executed, this command will generate the file *.config*, which contains all the packages, kernel, toolchain and properties needed for our image. To add new packages or edit existing ones, we need to manipulate this file, but this is not very automated and can result in a number of errors during the construction. That's why Buildroot has more user-friendly interfaces, where you can customize your final configuration, and automatically resolve dependencies. There are different formats for this interface you can try some of them:

{% highlight bash %}

$ make config
$ make menuconfig
$ make gconfig
$ make xconfig

{% endhighlight %}

During this example we will use *menuconfig*, as it has a minimal graphical interface and does not require other system dependencies like Qt.

After executing the configuration command, we will have the following output:

<img src="{{ site.url }}/assets/buildroot-menuconfig.png" style="display: block;margin: 0 auto;"/>

As we had already detailed the *fmt* library before, we will include it in our image, so we have to navigate thought the menu in the following way:

`Target Packages -> Libraries -> Text and terminal handling -> fmt`

To get more information about the package, you can enter **?**. It will show the same content as we had seen in the *Config.in* file.
Once selected, we can save the current setting through the panel and exit by pressing *ESC*.

## Building and Installing the Image

Once setup is ready, we can proceed to the longest step in this tutorial, building the image. Although the build is just a command, Buildroot will have to download all the sources that are present in the configuration file, build from sources and finally generate a custom image. To start the build process just run:

{% highlight bash %}

$ make

{% endhighlight %}

From now, Buildroot will take care of the entire build process, which may take a few hours the first time. For future builds, the cache may be reused which will decrease the build time in a few minutes.

After two hours and a few coffees and if no errors have occurred during the process we will have the following output:

{% highlight bash %}

$ ls output/images/
  bcm2710-rpi-3-b.dtb bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-cm3.dtb boot.vfat rootfs.ext2 rootfs.ext4 rpi-firmware sdcard.img zImage

$ ls -lh output/images/sdcard.img
    -rw-r--r-- 1 conan conan 153M ago  6 11:43 output/images/sdcard.img

{% endhighlight %}

These artifacts are the final compilation of everything that was generated during the build process, here we will be interested in the *sdcard.img* file. This is the final image that we will use on our RaspberryPi3 and it is only 153MB. Compared to other embedded distributions like Raspbian, it is much smaller.

Now let's copy the image to the destination SD card:

{% highlight bash %}

$ sudo dd if=output/images/sdcard.img of=/dev/mmcblk0 bs=4M conv=sync status=progress

{% endhighlight %}

Remember that the mounting point of your SD card may vary depending on your distribution.

Once done, plug the SD Card into the RaspberryPi3 and power the card, already connected to a video output. You will see the bootloader running normally and finally you will be presented to login screen where the default user is **root**, no password needed.

## Conclusions

In this post we talked about how to use Buildroot to create a Linux distribution without much effort and resulting in a very lean image.

Buildroot helps automate the process of creating a custom embedded Linux distribution with only the developer packages of interest.

Interested in knowing more or commenting on the subject? Please do not hesitate to open a new [issue](https://github.com/conan-io/conan/issues).
