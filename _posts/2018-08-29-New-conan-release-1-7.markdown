---
layout: post
comments: false
title: "Conan 1.7: Python requires, support for Python 3.7, SCM feedback and usability enhancements"
---

Summer holidays came to an end and we are back with a new Conan release. We have performed huge internal refactoring clearing the path to
accommodate a number of the most requested features. Here is the summary:

## Introducing the Python requires

One of our [most requested features](https://github.com/conan-io/conan/issues/1271) is now alive in this release. Python requires improve
the usability of Python code across multiple recipes to enable the possibility of subclassing a ConanFile and reusing it as a Conan
dependency.

This how a recipe using python requires looks like:

```
from conans import python_requires

base = python_requires("MyBase/0.1@user/channel")

class PkgTest(base.MyBase):
    pass
```

As you can see it's as easy as importing the new python_requires module and using it  globally to require a reference of a Python recipe.

There is also the possibility of just reusing functions without subclassing a ConanFile:

```
from conans import ConanFile, python_requires

base = python_requires("MyBuild/0.1@user/channel")

class PkgTest(ConanFile):
    ...
    def build(self):
        base.my_build(self.settings)
```

This has been released as an **experimental feature** so feedback is really welcome. For more information, please read the
[updated documentation](https://docs.conan.io/en/latest/mastering/python_requires.html#python-requires).

## Support for Python 3.7

Following the [deprecation notice of Python 2.7](https://blog.conan.io/2018/08/13/Its-Time-To-Deprecate-Python-2.html), we have added
support for [Python 3.7](https://www.python.org/downloads/release/python-370/) in this release. This should work on all supported platforms
with the current Conan requirements. Test it out and if it is not the case, please report it in the issue tracker.

## SCM Improvements and Fixes Following Your Feedback

The SCM feature released in [Conan 1.4](https://blog.conan.io/2018/05/30/New-conan-release-1-4.html) is getting a lot traction and we
continue improving it thanks to the feedback and users contributions.

Now SCM copies the *.git* folder similar to ``git clone`` and initializes submodules correctly to ``*HEAD*`` prior to checking out the
referenced revision.

There is also SVN support in development that will be available in the next release.

## Other Usability Enhancements

- You can now filter the uploads with the query parameter: ``conan upload --query``.

- A number of  enhancements have been added to the MSBuild build helper. You can now run builds in parallel and set the right toolchain for
  x86 architectures. A new parameter has been added to include custom properties like ``/p:MyCustomProperty=true``.

- Version ranges resolution speed has been improved by caching remote requests.

- The CMake generator now manages the C++20 flag.

Check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html#august-2018) and don't forget to
[update](https://conan.io/downloads.html)!
