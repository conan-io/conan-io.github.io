---
layout: post
comments: false
title: "Conan 1.21: Faster parallel uploads, Intel compiler support, improved Python requires and
matching names in generators for the upstream package!"
---

We are saying goodbye to 2019 with 1.21 release that comes with lots of cool features, bugfixes and
contributions from the community. Let's see some of those.

## Use multiple threads for uploading Conan packages to remotes

After many user requested this feature we have been preparing it since Conan 1.19. First moving to a
progress bar system that supports concurrency and then doing a whole refactor of all the terminal
output. Finally, now, since Conan 1.21 it will be possible to upload Conan packages to remotes faster
thanks to the use of multiple threads. To activate this feature you just have to add the `--parallel`
argument to the `conan upload` command and everything will work out of the box.

There are two levels of paralellitations... first bla bla bla... The maximum level of threads used
for this will be 8.

```
conan upload "*" --confirm --parallel -r my_remote
```

## Intel compiler support



## Improved Python requires

In 1.7 release we introduced the Python requires feature to share Python code between different recipes.
For this release we have a new improved `python_requires` that solves some drawbacks from the old one.
These are the main features of the new implementation:

 * **PackageID modification**. Now python_requires will affect the consumers package_id.

 * **Class attribute**. The syntax declares a class attribute instead of a module function call so
   that recipes are cleaner.

 * **Locked in lockfiles**. Now the python_requires will be part of the information stored in the
   lockfiles.

As we said, the syntax now is easier and more aligned with the rest of the recipe syntax. With the
previous version if you wanted to reuse methods from a base class you had to do something like this:

```python
from conans import ConanFile, python_requires

base = python_requires("pyreq/version@user/channel")

class ConsumerConan(base.get_conanfile()):
    name = "consumer"
    version = base.get_version()
```

And with the new syntax looks like:

```python
from conans import ConanFile

class Pkg(ConanFile):
    python_requires = "pyreq/0.1@user/channel"
    python_requires_extend = "pyreq.MyBase"
```

The version of the python_requires will now affect the packageID of the packages that use them with a
`minor_mode` policy. That means that if you change the minor or major components of the version it
will produce a new package ID but the patch component will not affect the ID.


## Use different names by generator

As you probably know the cpp_info attribute from conanfile is used for storing all the information
needed by consumers of a package like include directories or library names and paths. Since 1.19 we
introduced a new attribute for this object called name so if you set cpp_info.name that name should
be used by some supported generators to create file or variable names instead of using the regular
package name.

Now, in the 1.21 release we extend this feature so you are able to specify this same name per
generator. So, if you want to use CMake and pkg-config generators for the same recipe different names
can be set for each of those.

Let's see an example where you have a conanfile.py with this `package_info` for the package `Mylib/0.1`:

```python
    def package_info(self):
        self.cpp_info.names["cmake"] = "MyLib"
        self.cpp_info.names["pkg_config"] = "my_lib"
```

If we latter install this package using the cmake generator a target with name `CONAN_PKG::MyLib` will
be generated. If you install using the pkg-config generator a file `my_lib.pc` will be generated with a
library name my_lib inside.

## Other things

New tool: cppstd minimum version required https://github.com/conan-io/conan/pull/5997
Environment variables for virtual environments are stored in .env files containing just the key-value pairs. It will help other processes that need to read these variables to run their own commands. https://github.com/conan-io/conan/pull/5989
