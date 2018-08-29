---
layout: post
comments: false
title: "Conan 1.7: Python requires, support for Python 3.7, SCM feedback and usability enhancements"
---

Here we are after the summer holidays with a new release of Conan. In this release there has been a huge refactor of the internals that
clears the path for some of the more requested features. Here is the summary:

## Python requires

One of our [most requested features](https://github.com/conan-io/conan/issues/1271) has come live in this release. Python requires improves
the usability of python code among recipes enabling the possibility of subclassing a ``ConanFile`` and reuse it as a Conan dependency.

This how a recipe using python requires looks like:

```
from conans import python_requires

base = python_requires("MyBase/0.1@user/channel")

class PkgTest(base.MyBase):
    pass
```

As you can see is as easy as importing the new ``python_requires`` module and use it globally to require a reference of a python recipe.

There is also the possibility to reuse just functions without subclassing a ConanFile:

```
from conans import ConanFile, python_requires

base = python_requires("MyBuild/0.1@user/channel")

class PkgTest(ConanFile):
    ...
    def build(self):
        base.my_build(self.settings)
```

This has been released as an **experimental feature** so feedback is really welcome. Please read more about it in the
[updated documentation](https://docs.conan.io/en/latest/mastering/python_requires.html#python-requires).

## Support for Python 3.7

Following the [deprecation notice of Python 2.7](https://blog.conan.io/2018/08/13/Its-Time-To-Deprecate-Python-2.html), we have added
support for [Python 3.7](https://www.python.org/downloads/release/python-370/) in this release. This should be working in all supported platforms with the current Conan requirements. Test it out and if it is not your case please report it in the issue tracker.

## SCM improvements and fixes thanks to feedback

The SCM feature released in [Conan 1.4](https://blog.conan.io/2018/05/30/New-conan-release-1-4.html) is getting a lot traction and we
continue improving it thanks to the feedback and users contributions.

Now SCM copies the *.git* folder as in a normal ``git clone`` and initializes submodules correctly to ``*HEAD*`` prior to checking out the referenced revision.

There is also SVN support in development that will be available in the next release.

## Other usability enhancements

- Now there is the possibility to filter the uploads with a query parameter: ``conan upload --query``.

- There has been some enhancements to the MSBuild build helper. Now it is able to run builds in parallel and set the right toolchain for x86
  architectures. It also includes a new parameter to include custom properties like ``/p:MyCustomProperty=true``.

- Version ranges resolution speed has been improved trough caching remote requests.

- CMake generator now manages the C++20 flag.

Check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html#august-2018) and don't forget to
[update](https://conan.io/downloads.html)!
