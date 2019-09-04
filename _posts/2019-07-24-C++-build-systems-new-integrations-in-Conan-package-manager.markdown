---
layout: post
comments: false
title: "C++ build systems new integrations in Conan package manager"
---

As you will probably know, Conan has official support for integration with several build systems such as
[CMake](https://cmake.org/), [MSBuild](https://visualstudio.microsoft.com) or
[Meson](https://mesonbuild.com/) amongst others. But maybe you don't know that if you are using a build system
that is not currently supported, Conan provides the tools to integrate it and build and consume packages that
use it.

The code for this post is now available in the [Conan examples repository](https://github.com/conan-io/examples). 
Feel free to clone it and experiment with the code.

### Where do I start ?

Imagine that you want to create some packages using a specific build system and let others consume your packages and build them in case there are not binaries generated for their configuration. Conan has three features that can help you with that:

* [Conan generators](https://docs.conan.io/en/latest/reference/generators.html). They provide your build
  system with all the information about dependencies in a suitable format.
 
* [Conan installer](https://docs.conan.io/en/latest/devtools/create_installer_packages.html). Conan allows you
  to create packages for tools needed in the build process and installing them later with a ``build_requires`` to
  be able to invoke that tool from Conan. In our case, we want to install the tools to run our build system.

* [Conan build-helper](https://docs.conan.io/en/latest/reference/build_helpers.html). Build-helpers assist you
  in the process of translating settings such as ``build_type``, ``compiler.version`` or ``arch`` to the
  build system. It can also invoke the build system tools to build our sources. To use the build helper inside
  a ``conanfile.py`` we will use a [Python
  requires](https://docs.conan.io/en/latest/reference/conanfile/other.html)

### Conan generator for the Waf build system

To test these tools, we have selected the [Waf](https://waf.io/) build system. Waf is a build-automation tool
designed to help in the automatic compilation and installation of computer software. It is open-source
software written in Python and is released under the terms of the [BSD
license](https://waf.io/book).

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

As you can see, there are several commands defined here being ``configure()`` and ``build()`` the ones that matter
most to us at this moment.

* The ``configure`` command has the responsibility to set several settings and find the location of the
  prerequisites. We have to modify the *configuration context* (``conf.env``) variable to tell Waf where will
  it be able to find the *includes* and *library* files. Conan has all this information so we will need a tool
  that transforms that information in a way we can load in the *wscript* and that's what a *Conan
  generator* is designed to do.

* The ``build`` command will transform the source files into build files. Note that in the call to ``bld.program``
  we can tell Waf which libraries we are linking with the ``use`` argument. The *Conan generator* will have to
  provide this argument to Waf as well.

Waf provides us with the capability of loading *python modules* using the ``load`` command. We can load the
Python code created by the *Conan generator* to modify the Waf *configuration context*. That way we can
include the information about all the dependencies.

#### Custom Conan generators

A [custom generator](https://docs.conan.io/en/latest/reference/generators/custom.html#custom-generator) in
Conan is a class that extends ``Generator`` and implements two properties:

* ``filename`` should return the name of the file that will be generated. In our case, we will generate a
  file called ``waf_conan_libs_info.py`` 

* ``content`` should return the contents of the file with the desired format. Here we will retrieve all
  that information from the ``deps_build_info`` property of the ``Generator`` class. That property is a
  dictionary that has all the information required to link the library.

To use the *generator* in our consumers we will have to make a package that can be later loaded as a
``build_requires``. The implementation of the *generator will* go in ``conanfile.py`` and can be as simple as
this:

{% highlight python %}

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
        conan_libs = []
        for dep_name, info in self.deps_build_info.dependencies:
            if dep_name not in self.conanfile.build_requires:
                dep_name = dep_name.replace("-", "_")
                sections.append("   ctx.env.INCLUDES_{} = {}".format(
                    dep_name, info.include_paths))
                sections.append("   ctx.env.LIBPATH_{} = {}".format(
                    dep_name, info.lib_paths))
                sections.append("   ctx.env.LIB_{} = {}".format(
                    dep_name, self._remove_lib_extension(info.libs)))
                conan_libs.append(dep_name)
        sections.append("   ctx.env.CONAN_LIBS = {}".format(conan_libs))
        sections.append("")
        return "\n".join(sections)

{% endhighlight %}

This generator will create the ``waf_conan_libs_info.py`` file with all the dependencies information. We can
pass this information to Waf with the ``load`` command in the *wscript*:

{% highlight python %}
def configure(conf):
	conf.load('compiler_cxx')
	conf.load('waf_conan_libs_info', tooldir='.')
{% endhighlight %}

But that would only work if we have the Waf build tool in our path. However, we don't know if our consumers
are going to have it installed. We can solve this problem creating a Conan *installer package*.

### Creating a package to install the build system

As we said, Waf is a build system written in Python so to use it we will need to download the
Python script from the [Waf repository](https://gitlab.com/ita1024/waf/). We can create a Conan package that
downloads the tool and makes it available to perform our build. This would be the structure of the
``conanfile.py`` for our installer:

{% highlight python %}

class WAFInstallerConan(ConanFile):
    name = "waf"
    version = "2.0.18"
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
        self.copy('waf.bat', src='.', dst="bin", keep_path=False)

    def package_info(self):
        self.output.info("Using Waf %s version" % self.version)
        self.env_info.PATH.append(os.path.join(self.package_folder, "bin"))

{% endhighlight %}

Note that **only** the ``os_build`` setting has been left from the settings of the ``conanfile.py`` because it
does not make sense to create different installer packages depending for example on the ``compiler`` or
``arch`` as the tool will be the same for all those configurations. After installing this package all
consumers that declare it as ``build_requires`` will have this tool available on the path.

At this point, we are able to *tell Waf about the libraries locations* and we *can invoke Waf* from a
*conanfile* using ``self.run()`` and manually passing settings like the ``build_type``. But there is a better
way of doing this that will be the missing piece of our puzzle: *creating our own Conan build-helper*.

### Conan build-helper for Waf

Our build-helper will have two missions:

* Generate all the information with the Conan *build settings* to a format Waf can understand. We will generate
  another *Python module* that sets build information that Conan has such as ``arch``,
  ``build_type``, ``compiler`` or ``compiler.runtime`` in Waf. The name of this file will be
  ``waf_conan_toolchain.py``.

* Assist with the compilation of libraries and applications in the ``build()`` method of a recipe. We will
  create a method that invokes the build system abstracting the calls to ``self.run`` in the *conanfile*.

To create our own build-helper, we will use the ``python_requires()`` feature of Conan. That way we will be
able to reuse python code existing in other ``conanfile.py`` recipes. We will create a package with our
build-helper code and reuse it in the consumers importing them as a *Python requires*. There is a minimal
implementation of the *Python requires* in the *conanfile* but all the important code will reside in
``waf_environment.py`` file that contains the ``WafBuildEnvironment`` class. To learn a bit more about *Python
Requires*, please visit the [Conan
documentation](https://docs.conan.io/en/latest/extending/python_requires.html#python-requires).

{% highlight python %}

class PythonRequires(ConanFile):
    name = "waf-build-helper"
    version = "0.1"
    exports = "waf_environment.py"

{% endhighlight %}

As we said, all the important code is in the ``WafBuildEnvironment`` class in ``waf_environment.py``. Let’s
see an example of a simplified build-helper implementation that only takes into account the Conan
``build_type``. The configuration of the environment is made calling to the ``configure`` method of the
``WafBuildEnvironment`` class.

{% highlight python %}

class WafBuildEnvironment(object):
    def __init__(self, conanfile):
        self._conanfile = conanfile
        self._compiler = self._conanfile.settings.compiler
        self._build_type = self._conanfile.settings.build_type

    def _toolchain_content(self):
        sections = []
        sections.append("def configure(conf):")
        sections.append("    if not conf.env.CXXFLAGS:")
        sections.append("       conf.env.CXXFLAGS = []")
        sections.append("    if not conf.env.LINKFLAGS:")
        sections.append("       conf.env.LINKFLAGS = []")
        if "Visual Studio" in self._compiler:
            if self._build_type == "Debug":
                sections.append("    conf.env.CXXFLAGS.extend(['/Zi', '/FS'])")
                sections.append("    conf.env.LINKFLAGS.extend(['/DEBUG'])")
            elif self._build_type == "Release":
                sections.append("    conf.env.CXXFLAGS.extend(['/O2', '/DNDEBUG'])")
        else:
            if self._build_type == "Debug":
                sections.append("    conf.env.CXXFLAGS.extend(['-g'])")
            elif self._build_type == "Release":
                sections.append("    conf.env.CXXFLAGS.extend(['-O3'])")

        return "\n".join(sections)

    def _save_toolchain_file(self):
        filename = "waf_conan_toolchain.py"
        content = self._toolchain_content()
        output_path = self._conanfile.build_folder
        save(
            os.path.join(output_path, filename),
            content,
            only_if_modified=True)

    def configure(self, args=None):
        self._save_toolchain_file()
        args = args or []
        command = "waf configure " + " ".join(arg for arg in args)
        self._conanfile.run(command)

    def build(self, args=None):
        args = args or []
        command = "waf build " + " ".join(arg for arg in args)
        self._conanfile.run(command)

{% endhighlight %}

We modify the configuration environment through the ``conf.env`` variable setting all the relevant flags for
*Release* and *Debug* configurations depending on if we are building with Visual Studio or any other compiler.
We also define a ``build`` method that runs the Waf build tool.

### Putting it all together

#### Building the library

At this point, we are able to create a recipe that builds our library with the Waf build system. An example of
the structure of the project would be as follows:
 
{% highlight text%}

waf-mylib/
├── src/
│   └── mylib.cpp
├── include/
│   └── mylib.hpp
├── conanfile.py
└── wscript

{% endhighlight %}

With a ``conanfile.py`` that declares the requirement of all the necessary tools for building the project.

{% highlight python %}

waf_import = python_requires("waf-build-helper/0.1@user/channel")

class MyLibConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    name = "mylib-waf"
    version = "1.0"
    license = "MIT"
    author = "Conan Team"
    description = "Just a simple example of using Conan to package a Waf lib"
    exports = "LICENSE"
    exports_sources = "wscript", "src/mylib.cpp", "include/mylib.hpp"
    build_requires = "waf/2.0.18@user/channel"

    def build(self):
        waf = waf_import.WafBuildEnvironment(self)
        waf.configure()
        waf.build()

    def package(self):
        self.copy("*.hpp", dst="include", src="include", keep_path=False)
        self.copy("*.lib", dst="lib", src="build", keep_path=False)
        self.copy("*.dll", dst="bin", keep_path=False)
        self.copy("*.dylib*", dst="lib", src="build", keep_path=False)
        self.copy("*.so", dst="lib", src="build", keep_path=False)
        self.copy("*.a", dst="lib", src="build", keep_path=False)
        self.copy("LICENSE", dst="licenses", src=".", keep_path=False)

    def package_info(self):
        self.cpp_info.libs = ["mylib"]

{% endhighlight %}

The simplest ``wscript`` to build the library could be like this:

{% highlight python %}

top = '.'
out = 'build'

def options(opt):
    opt.load('compiler_cxx')

def configure(conf):
    conf.load('compiler_cxx')
    conf.load('waf_conan_toolchain', tooldir='.')

def build(bld):
    bld.stlib(target='mylib', source='./src/mylib.cpp')

{% endhighlight %}

The information for the build system is passed through the loading of the ``waf_conan_toolchain.py`` file
that was created by the build-helper.

#### Consuming the library

We could now consume the library even if we didn't have Waf installed but for the sake of completeness, let's
consume it using Waf as well. We will have to declare the needed ``build_requires`` and ``python_requires`` in
the ``conanfile.py``:

{% highlight python %}

waf_import = python_requires("waf-build-helper/0.1@user/channel")

class TestWafConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    name = "waf-consumer"
    generators = "Waf"
    requires = "mylib-waf/1.0@user/channel"
    build_requires = "WafGen/0.1@user/channel", "waf/2.0.18@user/channel"
    exports_sources = "wscript", "main.cpp"

    def build(self):
        waf = waf_import.WafBuildEnvironment(self)
        waf.configure()
        waf.build()

{% endhighlight %}

And create a ``wscript`` that loads all the Conan information in the Waf environment.

{% highlight python %}

def options(opt):
    opt.load('compiler_cxx')

def configure(conf):
    conf.load('compiler_cxx')
    conf.load('waf_conan_libs_info', tooldir='.')
    conf.load('waf_conan_toolchain', tooldir='.')

def build(bld):
    bld.program(source='main.cpp', target='app', use=bld.env.CONAN_LIBS)

{% endhighlight %}

Now, we could build our application using Conan:

{% highlight text %}

conan source . --source-folder=build
conan install . --install-folder=build
conan build . --build-folder=build

{% endhighlight %}

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-07-24/success_waf.gif"  align="center"  alt="When the build is succesful..."/>
</p>

At this point, you should have a general understanding of what Conan *generators*, *build-helpers* and
*installers* are and how they can help you to integrate almost any build system in Conan. Now you can clone
the [Conan examples repository](https://github.com/conan-io/examples) to see the implementation at a higher
detail and start integrating your favourite build system in the Conan package manager.
