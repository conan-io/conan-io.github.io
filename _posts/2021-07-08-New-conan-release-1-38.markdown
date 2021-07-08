---
layout: post 
comments: false 
title: "Conan 1.38 : new self.dependencies model for access to dependencies data, support for jinja2
syntax in conan profiles, new cmake_layout(), new [conf] cli support, new PkgConfigDeps generator."
meta_title: "Version 1.38 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.38 : new self.dependencies model for access to dependencies data, support
for jinja2 syntax in conan profiles, new cmake_layout(), new [conf] cli support, new PkgConfigDeps
generator." 
---

Conan 1.38 is already here and comes with lots of new features and some bug fixes. As we have
explained in previous posts we are paving the way to Conan 2.0, so most of the new features have to
do with that. We have added a new `conanfile.dependencies` model, using a dictionary that returns
information about the dependencies and may be used both directly in the recipe or indirectly to
create custom build integrations and generators. Also, now Conan profiles support `jinja2` syntax
which provides the ability to read environment variables, using platform information, and much more.
We have added a new `cmake_layout()` layout helper to define a multi-platform CMake layout that will
work for different generators (Ninja, Xcode, Visual Studio, Unix), and is multi-config. There is also
a new `--conf` argument to provide command line support for the new
[conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html) system. Finally, we
have added a new `PkgConfigDeps` generator that will replace the existing `pkg_config` generator in
Conan 2.0. 

## New `conanfile.dependencies` model

Starting in 1.38, Conan recipes will provide access to their dependencies through the
`self.dependencies` attribute. The main use is to create new build system integrations and is already
extensively used by Conan generators like `CMakeDeps` or `MSBuildDeps` to generate the necessary
files for the build. It is also possible to access `conanfile.dependencies` from the recipe like this:

```python
class MypkgConan(ConanFile):
    name = "mypkg"
    version = "1.0"
    requires = "libwebsockets/4.2.0"

    def generate(self):
        libwebsockets = self.dependencies["libwebsockets"]
        self.output.info(f"{libwebsockets.ref.version}")       
        self.output.info(f"{libwebsockets.ref.revision}")
        self.output.info(f"{libwebsockets.settings.arch}")
        self.output.info(f"{', '.join([dep.ref.name for dep in libwebsockets.dependencies.values()])}")
```

As you can see we access can get information about the Conan reference, settings, and even the
information about the dependencies of a specific dependency. Please, note that this information is
**read-only** and that it can only be used in methods called after the full dependency graph has been
computed. For more details about this, please [check the
documentation](https://docs.conan.io/en/latest/reference/conanfile/dependencies.html#dependencies-interface).

This new model will also allow iterating the dependencies of a recipe in a dict-like fashion, the key of
that dictionary will contain the specifiers of the relation between the current recipe and the
dependency. At the moment it can tell us if the dependency is a direct requirement (through the
`direct` property) or if it's a *build_require* (returned by the `build` property). Based on these
values there are some helper properties to iterate all the dependencies and filter the ones we want.
For example, if you want to list all the "host" requirements for the dependency you could call to
`self.dependencies.host` and get all direct and transitive requirements that are not *build_require*.

```python
class MypkgConan(ConanFile):
    name = "mypkg"
    version = "1.0"
    requires = "libwebsockets/4.2.0"

    def generate(self):
        trans_deps = self.dependencies.host
        self.output.info(f"transitive deps: {', '.join([dep.ref.name for dep in trans_deps.values()])}")
```

The output would look like this:

```bash
mypkg/1.0: Calling generate()
mypkg/1.0: transitive deps: libwebsockets, openssl
```

Please refer to the [Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/dependencies.html#iterating-dependencies)
for more details on what helper properties are available.

## Support for `jinja2` syntax in Conan profiles

After many users requested having more powerful profiles we made some exploratory attempts with
different implementations and we have finally decided to experimentally provide Conan profiles to
support `jinja2` templating syntax. This provides Conan profiles with some very useful capabilities.
The only thing to be done is to name the profile with the `.jinja` extension. Let's see some of those
capabilities:

* Using environment variables in profiles. Python `os` module is added to the render context so we
  can read environment variables using pure Python syntax. Also, you can define variables for use
  later.

        {% raw %}
        {% set build_type = os.getenv("MY_BUILD_TYPE") %}
        [settings]
        build_type = {{ build_type }}
        {% endraw %}

* Access to platform information. Python `platform` module is also added to the render context so we
  could set settings depending on the operating system we are running Conan into.

        {% raw %}
        [settings]
        os = {{ {"Darwin": "Macos"}.get(platform.system(), platform.system()) }}
        {% endraw %}

* Access to the current profile directory using the variable `profile_dir`.

You have all the information related to this feature in the [Conan
Documentation](https://docs.conan.io/en/latest/reference/profiles.html#profile-templates).

## New `cmake_layout()` layout helper

After releasing the new `layout()` method for *conanfile.py* in *1.37*, for this release, we are
adding a pre-defined layout helper for CMake. This layout will check the CMake generator and set the
corresponding folders according to that. For example, for multi-configuration generators such as
*Visual Studio* or *Xcode*, the folders will be the same irrespective of the build type, and the build
system will manage the different build types inside that folder. However, for single-config generators
like *Unix Makefiles*, different folders will be set for each different configuration.

Using this in a recipe is as simple as this:

```python
from conan.tools.layout import cmake_layout

def layout(self):
    cmake_layout(self)
```

You can check the implementation of this helper [in the
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html). If your layout
differs for example in where the sources are you can override the default value like this:

```python
def layout(self):
    cmake_layout(self)
    self.folders.source = “mysrcfolder”
```

## Configuration `[conf]` support from the command line

Starting in Conan 1.37 you can also [set new configuration
values](https://docs.conan.io/en/latest/reference/config_files/global_conf.html) using the `-c`
argument for some commands. Taking the example from the `cmake_layout()` described above it is very
handy to change the CMake generator using the command line like this:

```bash
conan create . -c tools.cmake.cmaketoolchain:generator=Xcode 
```

## New `PkgConfigDeps` generator

Please also check the new `PkgConfigDeps` generator meant to substitute our "classic" *pkg_config*
generator in Conan 2.0. It makes use of the new conanfile.dependencies model we talked about in
the beginning of this post. Check the
[docs](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html) for more
information on how to use it.

-----------
<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2021) for the
complete list.  

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).  
