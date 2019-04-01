---
layout: post
comments: false
title: "Conan 1.14: Revision mode and Artifactory support, new CMake generator, config install improvements & more!"
---

Lots of fixes and minor improvements landed in the last 1.14 Conan release. Here you have an overview of them!

## Chose the revision mode for your recipes

Coming in the previous 1.14 release, we introduced **revisions** as the way to implicitly version the changes done in a recipe without
bumping the actual reference version. That is something implemented now as part of the Conan model, which means that the latest revision
that exists in a remote is the one that is automatically installed (unless otherwise stated).

Take a look at the revisions section in the documentation to read more about it.

The revisions feature is one of the key steps towards reproducibility, this means that the revisions are computed as a unique ID known as
the "recipe revision" and "package revision".

The new feature coming with this release is the ability to chose the
[revision mode](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#revision-mode) for each recipe. You either use a hash of
the contents of the recipe (by default) as the recipe revision, or the commit for the SCM detected: ``git`` or ``SVN``.

```
from conans import ConanFile


class MyRecipe(ConanFile):
    name = "library"
    version = "1.0.3"
    revision_mode = "scm"
```

Forcing the ``revision_mode = "hash"`` comes handy if you have several recipes in the same repository. In that case you probably don't want
to create a new recipe revision if you only commit changes for one of the recipes, but a new revision only for the recipe that has been
modified.

## Artifactory supports revisions now!

Released right before Conan, the new [6.9 version of Artifactory](https://www.jfrog.com/confluence/display/RTF/Release+Notes#ReleaseNotes-Artifactory6.9) comes with full support for revisions.

All new Artifactory versions will be using revisions by default. This means that packages will be stored in the Conan repositories with a
new layout: ``<user>/<name>/<version>/<channel>/<recipe_revision>/<package_id>/package_revision>``.

Conan clients < 1.13 will still be working and a ``0`` recipe and package revision will be created in the repo to keep compatibility.

Bear in mind that the revision feature is opt in and you would have to activate it in your configuration with ``conan config set general.revisions_enabled=True`` or set the envrionment variable ``CONAN_REVISIONS_ENABLED=1``.

You can start using revisions with [Artifactory Community Edition for C++](https://jfrog.com/open-source/#conan).

## New ``cmake_find_package_multi`` generator

Continuing with the list of new [CMake generators for transparent integration](), we introduce the ``cmake_find_package_multi`` generator to
achieve multi-configuration of packages in Release/Debug modes.

Let's try to make the getting started example with this new generator:

```
$ git clone git@github.com:conan-io/examples.git
$ cd examples/libraries/poco/md5
$ ls
CMakeLists.txt  README.md  build.bat  build.sh*  conanfile.txt  md5.cpp
```

The *CMakeLists.txt* file will be changed to the following one:

```
cmake_minimum_required(VERSION 3.0)
project(MD5Encrypter)

set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
set(CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

find_package(Poco)

add_executable(md5 md5.cpp)
target_link_libraries(md5 Poco::Poco)

```

And let's use the new ``cmake_find_package_multi`` in the *conanfile.txt* too:

```
[requires]
Poco/1.9.0@pocoproject/stable

[generators]
cmake_find_package_multi
```

Now we can install both Release and Debug packages and build with CMake as usual:

```
$ mkdir build && cd build
$ conan install .. -s build_type=Debug
$ conan install .. -s build_type=Release

$ cmake .. -G "Visual Studio 15 2017 Win32"

$ cmake --build . --config Debug
.\Debug\md5.exe
c3fcd3d76192e4007dfb496cca67e13b

$ cmake --build . --config Release
.\Release\md5.exe
c3fcd3d76192e4007dfb496cca67e13b
```

Learn more in the [cmake_find_package_multi documentation](https://docs.conan.io/en/latest/integrations/cmake/cmake_find_package_multi_generator.html).

## Install the Conan configuration to a folder

We are working towards improving the functionality of ``conan config install``, so you can mix configuration files from different sources.
Now you can select the origin folder to get the files form and the target one you want to install the files to.

```
$ conan config install http://url/to/some/config.zip -sf=origin -tf=target
$ conan config install http://url/to/some/config.zip -sf=origin2 -tf=target2
$ conan config install http://other/url/to/other.zip -sf=hooks -tf=hooks
```

The actions will be cached so you can do ``conan config install`` and the previous actions will be executed in order.

This will be useful to set in place **hooks** from different locations, for example, to test the official hooks like this:

```
$ conan config install git@github.com:conan-io/hooks.git --source-folder hooks --target-folder hooks/conan-io
```

This can be also used to install specific profiles or remotes from a repository or zip file.

Read more in the [conan config command documentation](https://docs.conan.io/en/latest/reference/commands/consumer/config.html).

## Install package rebuilding a reference

The command ``conan install . --build`` now accepts a full reference as argument. You can use it to rebuild specific references in the
dependency graph:

```
$ conan install Poco/1.9.0@pocoproject/stable --build zlib/1.2.11@conan/stable
```

This is useful to build dependencies individually in the dependency graph, like private requirements that might be repeated in name but
different in version, user or channel.

You use wildcards with the full reference too:

```
$ conan install Poco/1.9.0@pocoproject/stable --build z*@conan/stable
```

Read more in the [conan install command documentation](https://docs.conan.io/en/latest/reference/commands/consumer/install.html).

## Error on override of dependencies

When [overriding requirements](https://docs.conan.io/en/latest/using_packages/conanfile_txt.html#overriding-requirements) there is a
possibility that instead of doing an override, you would like to explicitly depend on that dependency.

For example, when doing this in a *conanfile.txt*:

```
[requires]
Poco/1.9.0@pocoproject/stable
OpenSSL/1.0.2r@conan/stable
```

The second line will override the ``OpenSSL/1.0.2o@conan/stable`` required by ``Poco`` with ``OpenSSL/1.0.2r@conan/stable``.

```
$ conan install .
...
WARN: Poco/1.9.0@pocoproject/stable requirement OpenSSL/1.0.2o@conan/stable overridden by your conanfile to OpenSSL/1.0.2r@conan/stable
```
As shown above, a warning is printed currently. However, in case that you want Conan to
error on that behavior, you can set the new environment variable or configuration entry in the *conan.conf*:

- Environment variable: ``CONAN_ERROR_ON_OVERRIDE=1``
- Configuration entry: ``error_on_override = True``

```
$ conan config set general.error_on_override=True

$ conan install .
...
ERROR: Poco/1.9.0@pocoproject/stable: requirement OpenSSL/1.0.2o@conan/stable overridden by your conanfile to OpenSSL/1.0.2r@conan/stable
```

In case you want to achieve the behavior of the consumer project really depending on ``OpenSSL/1.0.2r@conan/stable`` but not overriding the
``OpenSSL/1.0.2o@conan/stable`` dependency of ``Poco``, when have an [issue open here](https://github.com/conan-io/conan/issues/4779).

## Configuration of the CA certificate

It is very common in enterprise organizations to have a custom CA certificate to be use on every HTTP request. However, if you want to
install the Conan configuration via ``conan config install`` you are not able to specify the certificate to be used. You could use ``--verify-ssl=False`` to override this check but is not the most appropriate solution.

We have introduced an environment variable and configuration entry to point to the certificate file to be used:

- Environment variable: ``CONAN_CACERT_PATH=~/cacert.pem``
- Configuration entry: ``cacert_path = ~/cacert.pem``

-----------
<br>

Check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html) and don't forget to
[update](https://conan.io/downloads.html).

Finally, if you find a bug or want to start a new discussion, please do not hesitate to open a new issue
[here](https://github.com/conan-io/conan/issues). Many thanks!
