---
layout: post
comments: false
title: "Empower your Yocto builds with Conan Package Manager"
---

Good news for all embedded developers!

We have officially released the integration with the [Yocto Project](https://www.yoctoproject.org/) with a new section in our documentation.

The Yocto Project is an open-source collaboration project that helps developers create custom Linux-based systems regardless of the
hardware architecture. Yocto includes a set of tools and libraries organized in layers (directories) and recipes to create a final
Linux distribution without any additional requirements on the host machine.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-07-26/conan-yocto.png"
             width="50%"
             alt="Conan and Yocto logos."/>
    </figure>
</div>

This layers and recipes system provides an extensible mechanism to incorporate new software components to the final Linux image. Users can
create their layers to deploy their software into the image.

The Yocto Project is intended for **embedded development** as it offers capabilities of customization at bootloader, kernel and filesystem
level. Yocto is also able to generate SDKs with a specific toolchain for the targeting device to cross-compile for the hardware in use.

Additionally, creating images with support for different hardware is as easy as changing the **Board Support Package layer**. The purpose of
this kind of layers is to act as an abstraction over the hardware, meaning that with just the change of this layer we could ship the same
software into an image suitable for a different device. Some of these layers are contributed by the open-source community or even
officially provided by the hardware manufacturers.

All of this abstraction and customization is very convenient when working with different hardware, but it comes with the drawbacks like a
constrained set of tools, difficult configuration for development and long build times.

## Conan packages in your Yocto builds

Using Conan you can create packages for different platforms. This allows developers to work on different systems (Windows in the example
below) and with their usual set of tools for debugging and testing.

With the usage of the Yocto SDK toolchain, packages can be cross-compiled and created as any other regular package, providing the same
development experience. This step can be easily automated in CI servers to create the packages for any embedded device supported by Yocto
and later uploaded to an Artifactory repository.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-07-26/conan-yocto_flow.png"
             width="70%"
             alt="Creating Conan packages with Yocto for embedded development."/>
        <figcaption>Creating Conan packages with Yocto for embedded development.</figcaption>
    </figure>
</div>

Moreover, those cross-built packages (ARM v8 in the figure above) can be deployed into the final image without rebuilding them in the Yocto
build. Just install them from the Artifactory repository!

We have created a [meta-conan layer](https://github.com/conan-io/meta-conan) that includes the Conan client into Yocto and makes the
deployment of packages a matter of indicating the Conan reference and the Artifactory repository details.

You can check all the information about this integration in the
[Yocto section of our documentation](https://docs.conan.io/en/latest/integrations/cross_platform/yocto.html).

Hope you find it useful!
