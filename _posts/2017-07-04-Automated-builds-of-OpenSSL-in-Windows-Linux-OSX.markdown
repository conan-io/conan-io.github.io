---
layout: post
comments: true
title: Automated builds of OpenSSL in Windows, Linux and OSX
# other options
---


Packaging C/C++ is not very difficult, as long as you have a well known, documented, relatively portable build setup for your library. OpenSSL builds very differently in different operating systems, using different tools and commands. Thus, creating binary packages from sources, in a portable manner, for someone who’s not savvy with their build system, is challenging, just because building it is challenging.
 
This post describes how to achieve a fully automated build for [OpenSSL](https://www.openssl.org/) packages in multiple platforms.


OpenSSL requirements
============================

One of the biggest challenges to achieve easy builds for a library is defining a simple way to install its required dependencies. 
 
OpenSSL has an optional dependency on [ZLib](https://zlib.net/), which can be configured at build time as an **optional requirement**. It is possible to build different binaries of OpenSSL with or without using ZLib compression.  
 
In Windows, OpenSSL uses Perl and Nasm (Native Assembler) for its builds. In Nix systems, OpenSSL uses configure and make. While we can assume that the compiler (e.g. Visual Studio) is a prerequisite and it is already installed on the developer’s machine, having both Perl and Nasm as default prerequisites for a C or C++ developer is too much. 

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2017-07-04/requirements.png" align="center"/>
</p>

While ZLib must be installed at development time, when the developer is linking their code to OpenSSL, Perl and Nasm are only necessary when building OpenSSL from sources. If we already have a pre-built binary package for OpenSSL, then Perl and Nasm are no longer necessary and the developer doesn’t even need to install them. So, we’ll call Perl and Nasm build-requirements. You can find the Conan packages for both [Nasm](https://bintray.com/conan-community/conan/nasm%3Aconan) and [StrawberryPerl](https://bintray.com/conan-community/conan/strawberryperl%3Aconan) in Bintray’s [Conan-Center](http://docs.conan.io/en/latest/packaging/using_bintray.html).
 
Conan has built-in mechanisms to define both scenarios. Here’s the relevant section for the OpenSSL Conan package recipe:

```python
def build_requirements(self):
    # useful for example for conditional build_requires
    if self.settings.os == "Windows":
        self.build_requires("strawberryperl/5.26.0@conan/stable")
        self.build_requires("nasm/2.13.01@conan/stable")

def requirements(self):
    if not self.options.no_zlib:
        self.requires("zlib/1.2.11@conan/stable")
```


Cross-platform OpenSSL package building
========================================

As introduced above, OpenSSL has different build commands and arguments in different platforms. Instead of defining build instructions in a README file, and having developers manually follow them, the Conan package recipe basically converts these steps in a readable Python script:

```python
       if self.settings.os == "Linux":
           self.linux_build(config_options_string)
       elif self.settings.os == "Macos":
           self.osx_build(config_options_string)
       elif ...
 
   def linux_build(self, config_options_string):
       m32_suff = " -m32" if self.settings.arch == "x86" else ""
       if self.settings.build_type == "Debug":
           config_options_string = "-d no-asm -g3 -O0 -fno-omit-frame-pointer " \
                                   "-fno-inline-functions" + config_options_string
 
       m32_pref = "setarch i386" if self.settings.arch == "x86" else ""
       config_line = "%s ./config -fPIC %s %s" % (m32_pref, config_options_string, m32_suff)
       self.output.warn(config_line)
       self.run_in_src(config_line)
       self.run_in_src("make depend")
       self.run_in_src("make")
 
   def osx_build(self, config_options_string):
       m32_suff = " -m32" if self.settings.arch == "x86" else ""
       if self.settings.arch == "x86_64":
           command = "./Configure darwin64-x86_64-cc %s" % config_options_string
       else:
           command = "./config %s %s" % (config_options_string, m32_suff)
```

With over 240 lines of code, the OpenSSL Conan recipe is one of the most complex and longest recipes, due to this variability. Together with the automation of the ZLib conditional requirement as well as the build-requirements to StrawberryPerl and Nasm, it allows the creation of more than 80 different binaries for multiple compilers and versions in Windows, Linux and OSX. Here’s the current matrix for the [OpenSSL package](https://bintray.com/conan/conan-center?filterByPkgName=OpenSSL%3Aconan) in Conan-Center:

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2017-07-04/matrix.png" align="center"/>
</p>

The above matrix is a sneak preview for a new feature that will be available in the next Conan release v0.25 :)
 
Creating the binaries, testing them and automatically uploading them to Bintray, is a fully automated process using the Travis and Appveyor public and free Continuous Integration services. Take a look at the [Conan OpenSSL package recipe](https://github.com/lasote/conan-openssl) repository to see how this is done.


Building other configurations
------------------------------
The above matrix shows the current binaries stored in Bintray, but that doesn’t mean that other configurations will not work. If you try to install Conan for an older version of Visual Studio (version 9) in Windows, you’ll get the following error:

```bash
$ conan install OpenSSL/1.0.2l@conan/stable -s compiler="Visual Studio" -s compiler.version=9 -s arch=x86
> ERROR: Missing prebuilt package for 'OpenSSL/1.0.2l@conan/stable'
```

This means that there is no pre-compiled binary for this configuration. But you can try building it from sources with the following command:

```bash
$ conan install OpenSSL/1.0.2l@conan/stable -s compiler="Visual Studio" -s compiler.version=9 -s arch=x86 --build=missing
```
 
ZLib will be built from sources too, as there is no pre-built binary for VS 9 for ZLib either.
 
This command will fire the installation in Windows of StrawberryPerl and Nasm too, of course. Once you have the OpenSSL package, you can safely remove them, install again and you will notice they are not retrieved again.


Conclusion
============

In this blog post we described how to achieve a reproducible build that includes the conditional (Windows only) automatic installation of required dev tools such as Nasm and Perl. These tools are installed locally, and apply only to the OpenSSL build, which keeps the development machine unpolluted. We also demonstrated automatic management of the ZLib dependency for the major OSs, Windows, Linux and OSX. 
 
The OpenSSL package recipe has been reported also to work for other configurations, including MinGW (it works in Appveyor, but keep in mind that it’s not fully tested). Please try it yourself and report in [github repository](https://github.com/lasote/conan-openssl) if necessary to improve support for other platforms.
