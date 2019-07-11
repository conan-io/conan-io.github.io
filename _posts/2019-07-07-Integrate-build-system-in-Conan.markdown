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

All the code for this post is available in the conan examples repo. Feel free to clone it and do your own
experiments with all the code. **TODO: PUT LINK**

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
	conf.env.INCLUDES_mylib = ['dir_to_mylib_includes']
	conf.env.LIBPATH_mylib = ['dir_to_mylib_libs']
	conf.env.LIB_mylib = 'mylib'

def build(bld):
	bld.program(source='main.cpp', target='app', use='mylib')
{% endhighlight %}

As you can see there are several commands defined here, being ``configure`` and ``build`` the ones that matter
most to us in this moment.

* ``configure`` command has the responsibility to configure the project and find the location of the
  prerequisites. As you can see  we have to modify the *configuration context* variable in order to tell Waf
  where will it be able to find the includes and library files. Conan has all this information so we will need
  a tool that transforms that information in a way we can load in the *wscript* and that's exactly what a
  *Conan generator* is designed to do.

* ``build`` command will transform the source files into build files. Note that in the call to ``bld.program``
  we can tell Waf which libraries we are linking through the ``use`` argument. *Conan generator* will have to
  provide this argument to Waf as well.

Waf provides us with the capability of loading *python modules* using the ``load`` command so we could create
some Python code with the generator that modifies the Waf *configuration context* to include the information
of the libraries location and one variable with all the list of dependencies as input to the ``use`` argument.

#### Custom Conan generators

A [custom generator](https://docs.conan.io/en/latest/reference/generators/custom.html#custom-generator) in
Conan is a class that extends ``Generator`` and implements two properties:

* ``filename`` that should return the name of the file that will be generated. In our case we will generate a
  file called ``waf_conan_libs_info.py`` 

* ``content`` that should return the contents of the file with the desired format. Here we will retreive all
  that information from the ``deps_build_info`` property of the ``Generator`` class. That property is a
  dictionary that has all the information needed to link the library.

If we want to use the generator in our consumers we will have to make a package that we can load as a
``build_requires``. The implementation of the generator then will go in ``conanfile.py`` and can be as simple
as this:

{% highlight python %}
from conans.model import Generator
from conans import ConanFile


class Waf(Generator):
    def _remove_lib_extension(self, libs):
        return [lib[0:-4] if lib.endswith(".lib") else lib for lib in libs]

    @property
    def filename(self):
        return "waf_conan_libs_info.py"

    @property
    def content(self):
        sections = []
        sections.append("def configure(ctx):")
        self.deps_build_info.libs = self._remove_lib_extension(
            self.deps_build_info.libs)
        conan_libs = []
        for dep_name, info in self.deps_build_info.dependencies:
            if dep_name not in self.conanfile.build_requires:
                info.libs = self._remove_lib_extension(info.libs)
                dep_name = dep_name.replace("-", "_")
                sections.append("   ctx.env.INCLUDES_{} = {}".format(
                    dep_name, info.include_paths))
                sections.append("   ctx.env.LIBPATH_{} = {}".format(
                    dep_name, info.lib_paths))
                sections.append("   ctx.env.LIB_{} = {}".format(
                    dep_name, info.libs))
                conan_libs.append(dep_name)
        sections.append("   ctx.env.CONAN_LIBS = {}".format(conan_libs))
        sections.append("")
        return "\n".join(sections)


class WafGeneratorPackage(ConanFile):
    name = "WafGen"
    version = "0.1"
    url = "https://github.com/czoido/conan-waf-generator" **TODO: CHANGE LINK**
    license = "MIT"

{% endhighlight %}

Once implemented the generator we can create the package via conan the conan ``create`` command:

{% highlight bash %}
conan create . user/channel
{% endhighlight %}

Now we have the tools to invoke the Waf generator in our ``conanfile.py`` and creating a
``waf_conan_libs_info.py`` file with all the dependencies information that we can load in Waf with the
``load`` command in the *wscript*:

{% highlight python %}
def configure(conf):
	conf.load('compiler_cxx')
	conf.load('waf_conan_libs_info', tooldir='.')
{% endhighlight %}

But that would only work if we have the Waf build tool in our path and we don't know if our consumers are
going to have the tool so it would be great if we could install this tool using Conan.

### Creating a package to install the build-system

As we said earlier Waf is a build-system written in Python and in order to use it we will need to download the
python script from their servers. For this we can create a Conan package that downloads the tool and makes it
available to perform our build. All Conan packages for building tools follow a similar structure. This would
be the structure of the ``conanfile.py`` for our installer:

{% highlight python %}

from conans import ConanFile, tools
import os


class WAFInstallerConan(ConanFile):
    name = "waf"
    version = "2.0.17"
    url = "https://github.com/czoido/conan-wasf-installer"
    description = "Waf is a Python-based build system"
    settings = "os_build"
    homepage = "https://gitlab.com/ita1024/waf"
    license = "BSD"
    exports_sources = ["LICENSE"]

    def build(self):
        source_url = "https://waf.io/waf-%s" % (self.version)
        self.output.warn("Downloading Waf build system: %s" % (source_url))
        tools.download(source_url, "waf")
        if self.settings.os_build == "Windows":
            tools.download(
                "https://gitlab.com/ita1024/waf/raw/waf-{}/utils/waf.bat".format(
                    self.version), "waf.bat")
        elif self.settings.os_build == "Linux" or self.settings.os_build == "Macos":
            self.run("chmod 755 waf")

    def package(self):
        self.copy(pattern="LICENSE", src='.', dst="licenses")
        self.copy('waf', src='.', dst="bin", keep_path=False)
        if self.settings.os_build == "Windows":
            self.copy('waf.bat', src='.', dst="bin", keep_path=False)

    def package_info(self):
        self.output.info("Using Waf %s version" % self.version)
        self.env_info.path.append(os.path.join(self.package_folder, "bin"))

{% endhighlight %}

Note that **only** the ``os_build`` setting has been left from the settings of the ``conanfile.py`` that is
because it does not make sense to create different installer packages depending for example on the
``compiler`` or ``arch_build`` as the tool will be the same for all those configurations. It will only create
different packages for differentiating ``os_build`` as the tool is going to be called through a *.bat* file in
*Windows* and in *Linux* the permissions have to be set. Now if one consumer declares this package as
``build_requires`` it will have this tool available on the path to build the project with it.

So at this point we are able to *tell Waf about the libraries locations* and we *can invoke Waf while using
our consumers* so we could call it directly from a *conanfile* using ``self.run`` and passing manually
settings like the ``build_type`` in the *conanfile*. But there is a better way of doing this that will be the
missing piece of our puzzle: *creating our own Conan build-helper*.

### Conan build-helper for Waf

Build helpers are Python wrappers of a build tool that help with the conversion of the Conan settings to the
build system’s ones. They assist users with the compilation of libraries and applications in the ``build()``
method of a recipe. 



### Putting It All Together
