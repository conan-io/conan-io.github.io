---
layout: post
comments: false
title: "Integrate a build system in Conan"
---

As you will probably know Conan has official support for integration with several build systems such as
[CMake](https://cmake.org/), [Visual Studio](https://visualstudio.microsoft.com) or
[Meson](https://mesonbuild.com/) amongst others. But maybe you don't know that if you are using a build system
that is not currently supported, Conan provides the tools to integrate it and build and consume packages that
use your preferred build system. 

### Where do I start ?

So, you are using a build system and you want to create some packages that use it and let others consume your
packages and build them in case there are not binaries generated for their configuration. Conan has three
features that can help you with that:

* [Conan generators](https://docs.conan.io/en/latest/reference/generators.html). This is the tool you need to
  provide all the information of which are the dependencies and where are they to your build system in a
  format it will understand. 
* [Conan installer](https://docs.conan.io/en/latest/devtools/create_installer_packages.html). Conan lets you
  create a package for a tool that will assist you in the building process and installing it latter with a
  ``build_requires`` in order to be able to invoke that tool from conan. In our case we want to install the
  tools to run our build system. 
* [Conan build helper](https://docs.conan.io/en/latest/reference/build_helpers.html). This is the way that one
  can put a layer to assist in the building process. Although it is not required to create this because we
  could make several calls to ``self.run`` in the build step it will be very helpful to abstract things a
  little bit. To use the build helper code inside a *conanfile.py* we will use a [Python
  requires](https://docs.conan.io/en/latest/reference/conanfile/other.html)

### Conan generator for the Waf build system

As our *guinea pig* we have selected the [Waf](https://waf.io/) build system. Waf is a build automation tool
designed to asssist in the automatic compilation and installation of computer software. It is open source
software written in Python and is released under the terms of the [BSD
license](https://waf.io/book/#_customization_and_redistribution).

Waf is a generic utility for building projects and project-specific details are stored in Python modules under
the name *wscript*. A Waf project must contain a top-level *wscript* where the commands that will make the
build happen are defined. Also, a *configuration context* will store data which may be re-used during the build.
Let's see how a minimal implementation for that *wscript* would look for a C++ project where we want to build
an executable that depends on ``mylib`` library.

{% highlight python %}
#! /usr/bin/env python
# encoding: utf-8

top = '.'
out = 'build'

def options(opt):
	opt.load('compiler_cxx')

def configure(conf):
	conf.load('compiler_cxx')
	conf.env.INCLUDES.extend(['dir_to_includes'])
	conf.env.LIBPATH.extend(['dir_to_libs'])
	conf.env['LIB_mylib'] = 'mylib'

def build(bld):
	bld.program(source='main.cpp', target='app', use='mylib')
{% endhighlight %}

As you can see there are several commands defined here, being ``configure`` and ``build`` the ones that matter
most to us. 