---
layout: post
comments: false
title: "Conan 1.19: Better integration for CMake and Pkg-Config, OSX frameworks support, enabling and disabling remotes, Clang 9 and
GCC 9.2 versions and command line suggestions"
---

Another release full of new features, many bugfixes and contributions coming from the community! In this release, we focused our efforts on
improving the model of `cpp_info`, the support of new compiler versions, some usability improvements and we are joining Hacktoberfest!
Let's review all the details below!

## Model the name of a library for CMake and Pkg-Config generators

Back in Conan 1.15, we started to work on new key features for Conan. Since then, we released
[revisions](https://docs.conan.io/en/latest/versioning/revisions.html) and improved the package ID modes (Read our
[last blog post](https://blog.conan.io/2019/09/27/package-id-modes.html)!), we created [lockfiles](https://docs.conan.io/en/latest/versioning/lockfiles.html) and included `conan graph` commands to manage them and now it's time for improving the `cpp_info` model in `package_info()`.

The features in this release were included in the *Components* one. The first one is the ability to model a name for a package that is
different from the reference one.

```
class Conan(ConanFile):
    name = "libcurl"
    ...

    def package_info(self):
        self.cpp_info.name = "CURL"
```

This new `cpp_info.name` will be used by CMake and Pkg-Config generators to generate the appropriate file names (like *findCURL.cmake*) and
targets to be used later in your build system. This will be very helpful to integrate more transparently with CMake's `find_package()` as we
discussed in a previous post about a [better CMake integration](https://blog.conan.io/2018/06/11/Transparent-CMake-Integration.html).

Check the full documentation [here](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#cpp-info).

## Support for Apple OSX frameworks

The second feature is related to OSX frameworks, where libraries can generate files such as `sfml-system.framework` that have to be consumed
with the `-framework` flag. Some recipes were declaring flags to link with frameworks libraries using `cpp_info.exelinkflags` and
`cpp_info.sharedlinkflags` but this is not the right place to declare this information.

So this Conan release is including two more variables to `cpp_info` dedicated for this purpose:

- `cpp_info.frameworks`:A list containing the names of the frameworks created by the package.
- `cpp_info.framework_paths`: A list of the relative directories to package folder used to locate the framework binaries (Default to
  `["Frameworks"]`).

This feature also includes setting the `DYLD_FRAMEWORK_PATH` variable in the `RunEnvironment()` build helper to manage those frameworks in
the same way it is done with `DYLD_LIBRARY_PATH`.

You can read about how to manage Apple frameworks in the [documentation](https://docs.conan.io/en/latest/howtos/link_apple_framework.html).

## Enabling and disabling remotes

Conan uses a decentralized model in order to retrieve and share your packages. This means that you can have different remotes configured in
the client and choose which one to install packages from or upload those to. However, sometimes remotes are not available for connection
(working behind a proxy for example) when a `conan install` is done and it fails.

With `conan remote disable <remote>` you can now disable  the remotes that you don't want to use for an installation. The remote will
not be used but it won't be removed from the remote list in the Conan configuration, so you can always activate it back again with
`conan remote enable <remote>`.

Additionally, if a remote is disabled, it will be shown when listed:

```
$ conan remote disable *-center

$ conan remote list

conan-center: https://conan.bintray.com [Verify SSL: True, Disabled: True]
art-local: http://localhost:8081/artifactory/api/conan/art-local [Verify SSL: True]
```

## Clang 9 and GCC 9.2 support

Contributed by the community, Conan 1.19 includes support for both Clang 9 and GCC 9.2 in the default *settings.yml* files and we are
working towards the integration of the Intel C++ Compiler for the next releases.

Meanwhile, remember that the values in the *settings.yaml* file are a convention for open source packages but it is
[fully customizable](https://docs.conan.io/en/latest/extending/custom_settings.html) to fit your needs. You can see an example of how to customize your settings in our [recommendations to manage sanitizers](https://docs.conan.io/en/latest/howtos/sanitizers.html).

## Command line suggestions

Conan 1.19 has now command line suggestions when commands are misspelled giving feedback about the most similar ones:

```
$ conan craete .
'craete' is not a Conan command. See 'conan --help'.

The most similar command is
    create

ERROR: Unknown command 'craete'
```

Together with this, we have linked at the end of the
[installations steps for Conan](https://docs.conan.io/en/latest/installation.html#initial-configuration) a project maintained by the
community for autocompletion of Conan commands in Bash. You can check and try it here: <https://gitlab.com/akim.saidani/conan-bashcompletion>

## Dropped support for Python 3.4

In the last days, we have faced some issues in our test suite regarding Python 3.4 version of Conan. While fixing the issues we realized that Python 3.4 is being widely dropped by the Python community as some of Conan's dependencies are not supported anymore.

Since Conan 1.19, the tests of our suite won't run with Python 3.4 and we will not work on fixes for it.

Also, remember that we will be stopping support for Python 2.7 this year, so we encourage everyone still using it to migrate to Python 3 as
soon as possible.

## We're joining Hacktoberfest 2019!

We're excited to announce that we're participating in this year's Hacktoberfest! An annual celebration for all open source projects, Hacktoberfest was launched as a partnership between DigitalOcean and GitHub in 2014 and rallies a global community of contributors.

If you want to take part, enter the [Hacktoberfest website](https://hacktoberfest.digitalocean.com/) for details. We have already added the `Hacktoberfest` label to some issues where we'd like to get help from the community: <https://github.com/conan-io/conan/labels/Hacktoberfest>

We would be glad to receive and review new PRs during this month to make Conan better!

-----------
<br>

Finally, you can have a look at the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html).

As always, do not hesitate to report any bug or share your feedback opening a new issue in our
[issue tracker](https://github.com/conan-io/conan/issues) and don't forget to [update](https://conan.io/downloads.html).
