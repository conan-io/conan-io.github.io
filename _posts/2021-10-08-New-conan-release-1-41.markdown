---
layout: post
comments: false
title: "Conan 1.41: IntelOneAPI support, better support for layout() local flows and editables, environment multi-config support, new cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe."
meta_title: "Version 1.41 of Conan C++ Package Manager is Released"
meta_description: "The new version features include IntelOneAPI support, better support for layout() local flows and editables, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.41 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.41 Conan C/C++ package manager version",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Conan Team", 
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan release", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
},
 "datePublished": "2021-10-08",
 "description": "IntelOneAPI support, better support for layout() local flows and editables, environment multi-config support, cpp_info.objects model (and CMakeDeps support), support multiple toolchains in one recipe.",
 }
</script>

We are pleased to announce that Conan 1.41 is out and comes with some significant new features and
bug fixes. We introduced support for [Intel oneAPI](https://www.oneapi.io/) tools with a new
`intel-cc` compiler setting. Also, local flows and editables are now easier using
[layout()](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html). The new
environment supports now multi-configuration generators. We have added a new `objects` attribute for
the conanfile's
[cpp_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info) to support
object (_.obj_ and _.o_) files. Finally, from  this version it's possible to use multiple different
toolchains like
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html),
[BazelToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html#bazeltoolchain)
and
[CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
in the same recipe.

## Intel oneAPI support in Conan 1.41



## Easier local flows and editable handling using layout()

For this release we have fixed some issues regarding the new
[layout()](https://blog.conan.io/2021/06/10/New-conan-release-1-37.html) feature introduced in Conan
1.37. This feature makes it easier to work with packages in [editable
mode](https://docs.conan.io/en/latest/developing_packages/editable_packages.html) and also using the
[local developement flow](https://docs.conan.io/en/latest/developing_packages/package_dev_flow.html).
Packages that are in editable mode make it possible for Conan to find dependencies in the local work
folder instead in the Conan Cache, that allows faster workflows without the need of doing a ``conan create`` 
for each change in the sources of the package being developed.



## Multi-config support for environment generators

Since [Conan 1.35](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html) [new
tools](https://docs.conan.io/en/latest/reference/conanfile/tools/env.html) are available for managing
the environment. Now, the generated files for
[VirtualRunEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualbuildenv.html)
and
[VirtualBuildEnv](https://docs.conan.io/en/latest/reference/conanfile/tools/env/virtualrunenv.html)
take the ``build_type`` and ``arch`` settings into account for the names of the launcher files to
improve the integration with multi-configuration generators. Then, calling to ``conan install
cmake/3.20.0@ -g VirtualBuildEnv --build-require -s build_type=Release`` for example will create a
file called ``conanbuildenv-release-x86_64.sh`` and will not be overwriten for other ``build_type``
value.

Also, now it is possible to group the generated environment variables launcher scripts under
different names. By deafault they are all aggregated to the group ``build`` for
[Environment](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html) and
``VirtualeBuildEnv`` and group ``run`` for ``VirtualRunEnv`` leading to a
``conan(build/run).(sh/bat)`` script that sets all the declared enviornments. Now declaring something
like this in the conanfile:

```python
class PkgConan(ConanFile):
    ...
    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
        env1 = Environment(self)
        env1.define("env_name", "env1")
        env1.save_script("env1_launcher", group="mygroup")
        env2 = Environment(self)
        env2.define("env_name", "env2")
        env2.save_script("env2_launcher", group="mygroup")
        env3 = Environment(self)
        env2.define("env_name", "env3")
        env2.save_script("env3_launcher")
    ...
  ```

Will create a `conanmygroup.sh` file to set both `env1` and `env2` and a default `conanbuild.sh` that will
only set `env3` variables.


## Define object files in cpp_info.objects new attribute

Starting in Conan 1.41 you can set a list of object files (_.obj_ and _.o_) in the
[cpp_info](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info) `objects`
attribute. This attribute is only compatible with the
[CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) generator
for the moment. It will add the declared objects to the generated CMake target so those objects can
be later consumed by packages that declare the dependency. Let's see an example:

We create a Linux package `pkg/1.0` that builds and packages one _myobject.obj_ file. The same way
you would declare the libraries that must be consumed by packages that depend on `pkg/1.0` setting
the `cpp_info.libs` attribute you can declare that this library packages some object files that the
consumers need to add. This can be done setting that information in the package_info of the
conanfile:

```python
class Pkg(ConanFile):
    name = 'pkg'
    version = '1.0'
    ...
    def package_info(self):
        self.cpp_info.objects = ['lib/myobject.o']
    ...
```

Then, when this package is consumed by other using the `CMakeDeps` generator, the path of that object
will added to the target so that the consumer can link against that _myobject.obj_ file.


## Use different toolchains in the same recipe

We have added the argument _namespace_ to the new tools helpers for
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html),
[Bazel](https://docs.conan.io/en/latest/reference/conanfile/tools/google.html) and
[Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html). This arguments
provides the possibility of using more than one toolchain in the same recipe, for example, when parts
of the same package are built with different build systems. With this argument the generated
intermediate files for the toolchains helpers will not collide and will be possible to see something
like this in the recipes if necessary:

```python
  from conans import ConanFile
  from conan.tools.gnu import AutotoolsToolchain, Autotools
  from conan.tools.google import BazelToolchain, Bazel
  from conan.tools.cmake import CMakeToolchain, CMake
  class Conan(ConanFile):
      settings = "os", "arch", "compiler", "build_type"
      def generate(self):
          autotools = AutotoolsToolchain(self, namespace='autotools')
          autotools.generate()
          bazel = BazelToolchain(self, namespace='bazel')
          bazel.generate()
          cmake = CMakeToolchain(self, namespace='cmake')
          cmake.generate()
      def build(self):
          autotools = Autotools(self, namespace='autotools')
          autotools.configure()
          autotools.make()
          bazel = Bazel(self, namespace='bazel')
          bazel.configure()
          bazel.build(label="//main:hello-world")
          cmake = CMake(self, namespace='cmake')
          cmake.configure()
          cmake.build()
  ```


---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#oct-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
