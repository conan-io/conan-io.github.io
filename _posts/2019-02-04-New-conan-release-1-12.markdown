---
layout: post
comments: false
title: "Editable packages, Composable profiles, Command improvements & New architectures"
---

This time we have 1.12 out to start the 2019 year and there are some interesting features and improvements we would like to highlight. Let's
go over them!

## Editable packages

It is fairly common that to test new code in packages with other dependencies while developing, you had to go through the slow
``conan create`` process to store new code in the cache.

Following the path of other package managers, we tried to imagine how an “editable” mode for Conan should work and there were some main
points:
    - The user has to be able to compile without Conan (IDE/command line, not ``conan build``).
    - Freedom to choose any project structure for header folders, source code, library folders...
    - Handle any configuration of settings without creating artificial packages for all of them.

To illustrate how editable package work, we have created a repo [here](https://github.com/memsharded/editables-examples) that we would use
it as example.

Let's say we are developing a final "hello" application and we are relying on another library called "say" to print our message. We are
developing the "say" library and would like to check the changes in the "hello" app. The normal way would be to make changes in the "say"
library and run ``conan create`` to put its binaries in the local cache. After that, consume it from the "hello" app with a
``conan install``.

With this feature, we have a command to tell Conan that we want to consume the "say" library under the package name``say/0.1@user/testing``
directly from the current folder instead from the Conan cache.

```
$ cd cmake/say
$ mkdir build && cd build
$ conan link .. say/0.1@user/testing --layout=../layout
```

The *layout* indicates Conan that it has to search in the following paths relative to the directory of the *conanfile.py* used in the
command. Here is the content of that file:

```
[includedirs]
src

[libdirs]
build/lib
```

Now we can build in the development folder (this could also be triggered by an IDE):

```
$ conan install ..  # get possible dependencies from conan
$ cmake ../src -G "Visual Studio 15 2017 Win64"
$ cmake --build . --config Release
```

Let's consume the "say" library from the "hello" app now:

```
$ cd ../../hello
$ mkdir build && cd build
$ conan install ..
…
conanfile.py (hello/0.1@None/None): Installing package
Requirements
    say/0.1@user/testing from user folder - Editable
Packages
    say/0.1@user/testing:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 - Editable
...
$ cmake ../src -G "Visual Studio 15 2017 Win64"
$ cmake --build . --config Release
$ bin\app.exe
Release: Hello World Release!
```

Now we make some changes in the "say" library without moving it to the cache. For example, we change the ``Release:`` message to
``****** Release ******:`` and build it:

```
$ cd ../../hello
$ cmake --build . --config Release
```

Finally, out "hello" app should be built with the modified "say":

```
$ cmake --build . --config Release
$ bin\app.exe
******* Release *******: Hello World Release!
```

As you can see, having this new workflow is very convenient during development and the compilation is not coupled with Conan, only a
``conan install`` is necessary.

If you want to read more, here is the [link to the docs section](https://docs.conan.io/en/latest/developing_packages/editable_packages.html)
explaining this new feature and the possibility to use different layout files.

There are some pending issues like having a proper [layout templating system](https://github.com/conan-io/conan/issues/4424) or showing
packages that are in editable mode when searching, but we hope to have them fixed for next release.

### New path for workspaces

We are aware that there has been a lot of interest in the experimental
[workspaces feature](https://docs.conan.io/en/latest/developing_packages/workspaces.html). However, as releases came out and development
continued we started to think the implementation of workspaces was lacking at some points.

Additionally, the idea of the package layouts and editable mode was something really interesting to explore. So our decision was to delay
the development of issues regarding workspaces until editable packages were released.

There has been some work done already to redesign and reimplement workspaces on top of the editable mode feature and our first impressions
are good. We will try to restart the development of them for the following releases.

## Composable profiles

With Conan 1.12, commands with the ``--profile`` parameter are now provided with the possibility of using it multiple times to achieve a
profile composition.

```
$ conan install . --profile windows --profile 32bit
```

The priority of the applied values is from right to left. In the case of the example, the "32bits" profile configuration will have priority
over the "windows" profile configuration.

It is a very useful feature when you want to add build require tools like CMake, which is something not specific to a configuration. For
example, having a profile ``cmake`` with build require ``cmake_installer`` and a ``mingw`` one with the "gcc" compiler and the
``mingw_installer`` too would make it very easy to apply to a and to use it:

```
$ conan install . --profile mingw --profile cmake
```

## Full reference and JSON for some commands

As you might now, some commands had some issues when referencing names of other packages. For example, the ``conan install --build <name>``
was only using the name of a requirement, which could be problematic when using dependencies with the same name but coming from different
users. Now you can do this:

```
$ conan install . --build liba/1.0@user/channel
```

Together with this feature, the install command also includes now an additional reference for consumer packages that comes handy to have
some information defined like the user or the channel.

```
$ conan install . liba/1.0@user/channel
```

There is more information in [this section](https://docs.conan.io/en/latest/reference/commands/consumer/install.html) of the documentation.

To end with the new commands, the ``conan info`` has now a generalized ``--json`` parameter not only for build order but for the dependency
graph information. We are sure this will come handy for those orchestrating CIs using Conan. Check the
[output section](https://docs.conan.io/en/latest/reference/commands/output/info.html) to see how it looks like.

## New architectures supported

New architectures arrived at this release too. This time we included new ones for Apple and PowerPC.

Apple introduced a new one for watchOS called ``arm64_32``. As we had already followed the ``armvX`` pattern and ``amrv8`` was already in
place, we decided to call this one ``armv8_32``. Similarly, the new iOS architecture called ``arm64e`` was introduced in *settings.yaml* as
``armv8.3``. You can manage this conversions with ``tools.to_apple_arch()``.

Finally, there was a request to support PowerPC 32-bit architecture, so there is also a new ``ppc32`` one too.

Those can be correctly handled with apple tools and ``tools.get_gnu_triplet()`` and will be taken into account in some generators like
``b2``.

Check that your *settings.yaml* is updated when you install Conan 1.12 and run a new ``conan install``. In case your *settings.yaml* was
modified, a new *settings.yaml.new* will be created so you can check the diff.

## Generators: Template files & variable naming convention

Some releases ago we introduced a new ``make`` generator and there were some issues with the naming of the variables that could be
misleading to users (See [conan-io/docs#955](https://github.com/conan-io/docs/pull/955#issuecomment-442754327)).

As the Conan ``cpp_info`` model includes a ````cppflags`` that is confusing, we finally decided to rename ``CONAN_CPPFLAGS`` to
``CONAN_CXXFLAGS`` in the generator and follow this path for premake too, following the convention that was already in place in the
cmake generator. There is also an issue open to create a ``cpp_info.cxxflags`` attribute deprecating ``cpp_info.cppflags`` used in
``package_info()`` method of conanfile without breaking ([conan-io/conan#4461](https://github.com/conan-io/conan/issues/4461)).

In the other hand, some users requested the the possibility to export some kind of templating files in order to make the task of generating
the *conanbuildinfo* files easier in some cases. now the use of ``exports`` attribute is allowed in custom generators:

```
class MyCustomGeneratorPackage(ConanFile):
    name = "custom"
    version = "0.1"
    exports = "mytemplate.txt"
```

You can see a full example in this
[howt-to](https://docs.conan.io/en/latest/howtos/custom_generators.html#using-template-files-for-custom-generators).

## Other improvements

There are new tools and improvements available in this release too:

- ``tools.Git()`` and ``tools.SVN()`` have anew method ``get_tag()`` that checks the name of the tag has been checked out.
  (See [link](https://docs.conan.io/en/latest/reference/tools.html#tools-git)).

- ``MSBuild()`` build helper has now a definitions dictionary that can be used to set any property to the project during the build. Also
  the default toolset is now applied although no toolset was specified in the profile. This should not break the old behavior as this was
  the default value already applied in ``PlatformToolset`` flag.
  (See [link](https://docs.conan.io/en/latest/reference/build_helpers/visual_studio.html#build)).

- ``tools.environment_append()`` is now able to unset variables using the ``None`` value.
  (See[link](https://docs.conan.io/en/latest/reference/tools.html#tools-environment-append)).

- Short paths feature now generates them in a deterministic way instead of having a random path in the short paths directory.


If you want to know more about the changes in this release, check the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html) (it includes links to the related Pull Request) and don't forget to [update](https://conan.io/downloads.html)!
