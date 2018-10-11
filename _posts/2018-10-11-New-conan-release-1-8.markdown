---
layout: post
comments: false
title: "Conan 1.8: Plugins system, SVN support for SCM, recipe conventions & much more!"
---

After a long and awaited period, here we have the new Conan 1.8 release. It comes packed of new features and fixes and some great
contributions from the community. Let's go through some of the highlights shipped in this new release.

## Plugins system

Many people were asking for a way of customizing the Conan behavior to suit their needs in order to perform tasks after some actions such as
installation of new packages, uploads to a server… We thought that the best approach for this would be to have a plugin feature in the Conan
client, so this is what we have come up with.

Plugins are python files with some **pre** and **post** functions that receive information through parameters and are executed right before
and after an action executed by Conan. Those actions are normally self-described by their name.

Here you can see a simple example of a plugin:

*example_plugin.py*
```
def pre_export(output, conanfile, conanfile_path, reference, **kwargs):
     # Check basic meta-data
     for field in ["url", "license", "description"]:
         field_value = getattr(conanfile, field, None)
         if not field_value:
             output.warn("Conanfile doesn't have '%s'. It is recommended to add it as an attribute"
                         % field)
```

Plugins can have many functions and do different things in each of them. They might also have private functions or imposts from pip
installed modules or relative ones.

Plugins are stored under the *~/.conan/plugins* directory that can be activated on demand using ``conan config set`` and
``conan config rm``.

There are still some things to define regarding plugins, such as the way they are installed, how they can be managed or linked to a recipe,
include new functions in the future or even change current functions signature… This is why this feature is also released as experimental
and will require more testing from the community. Feel free to report any issue or improvement in the Conan issue tracker using `[PLUGINS]`
in the title.

There is also a new repository [conan-io/plugins](https://github.com/conan-io/plugins) where we will develop the official plugins and manage
suggestions for new ones in its own issue tracker. 


## SVN support for SCM

As said in previous releases, the SCM feature keeps improving and finally we have support for SVN in the recipes.

There has been a huge interaction with the community with [more than 80 comments](https://github.com/conan-io/conan/pull/3192) and reviews
to develop this new feature.

Here you can see that it can be transparently used the same way it was done for git:

```
from conans import ConanFile, tools

class ConanLib(ConanFile):
    name = "lib"
    version = "0.1"
    scm = {
        "type": "svn",
        "url": "auto",
        "revision": "auto",
        "subfolder": "onesubfolder"
    }
```

There is also a new [SVN tool wrapper](https://docs.conan.io/en/latest/reference/tools.html#tools-svn) that can be used inside your recipes
for any purpose you want.

Keep in mind that the this feature is still experimental as other SCM types might be added eventually that can change the interface.
However, we encourage SVN users to try this feature and report new issues or suggest improvements using `[SVN]` in the issue title.

## SCM Improvements and Fixes Following Your Feedback

The SCM feature released in [Conan 1.4](https://blog.conan.io/2018/05/30/New-conan-release-1-4.html) is getting a lot traction and we
continue improving it thanks to the feedback and users contributions.

Now SCM copies the *.git* folder similar to ``git clone`` and initializes submodules correctly after checking out the referenced revision
rather than to the default ``*HEAD*`` immediately following cloning.

There is also SVN support in development that will be available in the next release.

## New conventions for recipes

### Protected ConanFile members
We have seen a great evolution of recipes being created and with the development of new features we think there is a need for a naming
convention for the `ConanFile` attributes and methods.

From now on, we encourage users to use protected members in their recipes in case they want to use custom attributes:

```
class MyConanFile(ConanFile):
    name = “myconan”
    version = “1.0.0”
    _custom_attribute = “some_value”  # user protected attribute

    def _custom_method(self):
         self.output.info(_custom_attribute)
```

A note has been included in the [reference section](https://docs.conan.io/en/latest/reference/conanfile.html) to make users aware of this
new convention.

### Raising ConanInvalidConfiguration

There were some points in the Conan documentation (https://docs.conan.io/en/1.7/mastering/conditional.html) where we encouraged to raise
exceptions in ``configure()`` for configurations not supported in a library.

We have introduced a special exception called
[`ConanInvalidConfiguration`](https://docs.conan.io/en/latest/reference/conanfile/methods.html#invalid-configuration) for this purpose that
has different treatment on the return codes of the Conan client. This way exceptions of this type could be interpreted as a different error
by tools like ``ConanPackageTools`` (WIP).

Here you can see an example:

```
from conans import ConanFile
from conans.errors import ConanInvalidConfiguration

class MyConan(ConanFile):
    name = “myconan”
    version = “0.1.3”
    settings = “os”, “compiler”, “arch”, “build_type”

    def configure(self):
        if self.settings.os != "Windows":
            raise ConanInvalidConfiguration("Library 'myconan' is only supported for Windows")
```

### Default options as a dictionary

The syntax for default options and its inferred types have always been tricky, so we have done some work to document the behavior of the
[option values comparison](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#options).

There is still room for improvement but is not easy to come up with a solution without breaking existing recipes. So, in order to clear the
path for future development, the recommended way to declare default options is using a dictionary in *conanfile.py*.

```
class MyPkg(ConanFile):
    ...
    requires = “OtherPkg/0.1@user/channel”
    options = {"shared": [True, False],
               "option1": ["value1", "value2"],
               "option2": "ANY"}
    default_options = {"shared": True,
                       "option1": "value1",
                       "option2": 42,
                       “OtherPkg:shared”: True}
```

## Build helpers with fixed installation directories

Following the issues reported from some users using SUSE and similar Linux distributions, we realized that the installation directories in
the ``AutoToolsBuildEnvironment`` build helper was dependent on the platform, mainly using *lib64* folder instead of *lib* folder.

This was breaking recipes rebuilt from sources, as the default library directory declared in ``self.cpp_info.libdirs`` for consumers is
always *lib*.

The build helpers can't generate a different directory structure depending on where is it executed, so we have fixed these output
directories to the most common default ones for both CMake (see
[installation definitions](https://docs.conan.io/en/latest/reference/build_helpers/cmake.html#definitions)) and AutoTools (see
[configure()](https://docs.conan.io/en/latest/reference/build_helpers/autotools.html#configure)) build helpers. There is also a flag
``use_default_install_dirs`` in ``AutoToolsBuildEnvironment`` to skip this behavior.

You will find a warning regarding this change in the AutoTools reference section with a clear [explanation of the issue](https://docs.conan.io/en/latest/reference/build_helpers/autotools.html#autotools-lib64-warning).

## New generator: B2
This release brings a new generator for B2, also known as Boost Build. This generator comes with full-fledged features such as the use of
subprojects and targets. It enhances the capabilities and deprecates the
[`boost-build` generator](https://docs.conan.io/en/latest/reference/generators/boost_build.html).

You have more information about it in the documentation reference: https://docs.conan.io/en/latest/reference/generators/b2.html

## Tools and output

There are new tools and improvements available in this release too:

- ``tools.replace_path_in_file()``: New tool to replace a path in a file with another string. In Windows, it will match the path even if
the casing and the path separator doesn’t match.

- ``tools.collect_libs()`` now searches for libraries in ``self.cpp_info.libdirs``.

- ``tools.vcvars()`` has been enhanced to avoid hitting issues with max size of environment variables and it can also be used with
  ``clang-cl``.

Finally, there has been some changes in the output:

- Now, every time a ``conan install`` is issued, the configuration of the profile is printed in the output. Note that this configuration
resembles the profile used for the installation and not strictly the final values applied to the package.

- Following the roadmap of deprecating Python 2, there is a new warning for Python 2 users recommending the migration to Python 3.

  ```
  $ conan create . conan/stable

  Python 2 will soon be deprecated. It is strongly recommended to use Python 3 with Conan:
  https://docs.conan.io/en/latest/installation.html#python-2-deprecation-notice

  Exporting package recipe
  box2d/2.3.1@conan/stable export: Copied 1 '.txt' file: CMakeLists.txt
  ...
  ```

If you want to know more about the changes in this release, check the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html) and don’t forget to [update](https://conan.io/downloads.html)!
