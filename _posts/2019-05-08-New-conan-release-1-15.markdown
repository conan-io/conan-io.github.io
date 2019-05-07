---
layout: post
comments: false
title: "Conan 1.15: C++ standard as a subsetting, deploy generator, python requires source reuse and roadmap features ahead"
---

Another month and another Conan release. This time we bring the 1.15 release with some interesting changes and hints about what is coming up
next.

## New settings ``compiler.cppstd`` to handle C++ standard

The Conan internal model takes care of the C++ standard too, up to this version it was possible to define a setting ``cppstd`` in the
recipes and use it to generate different packages depending on its value. In this release, we keep this behavior for backward compatibility,
but we have decided to move it to a subsetting under the ``compiler`` one.

There are two main motivations behind this change: being a subsetting of each compiler allow more fine-grained control over the values this
setting can take for different compilers (i.e.: modern Visual Studio doesn’t have a flag for C++11, GNU compiler can activate extensions or
not using ``gnu++17`` or ``c++17``); the other main motivation is that this will allow existing recipes to benefit from this subsetting
(build helpers and generators will take it into account) without the need of modifying the recipe to explicitly add the ``cppstd`` setting.

Even though the ``cppstd`` setting is now deprecated, it will continue working the same for all the 1.x releases, nevertheless, we encourage
our users to use the new setting and migrate existing recipes to adopt this new behavior (Conan will warn accordingly). Furthermore, the
usage of the setting ``compiler.cppstd`` is not compatible with the deprecated ``cppstd``, you cannot mix both of them. 

To use ``compiler.cppstd`` you only need this subsetting available in your ``settings.yml`` file (the default provided by Conan already has current values) and you should provide a value for it in your profile or using the command line:

*profile*
```
[settings]
os=Windows
arch=x86_64
compiler=Visual Studio
compiler.version=15
compiler.cppstd=17
build_type=Release
```

Conan's build helpers will take into account this value when calling to the compiler and Conan will generate a different package ID for each
of the different values. If no value is given, the default for the given compiler version will be used and, by default, Conan will generate
the same package ID as if that default value had been explicitly set (this package ID will also be the same as the one generated using the
deprecated ``cppstd`` setting).


You have more information in [this section](https://docs.conan.io/en/latest/howtos/manage_cpp_standard.html) of the docs and you can also
check the new [settings.yml](https://docs.conan.io/en/latest/reference/config_files/settings.yml.html) file.

## Deploy generator

It was a recurrent feature requested by users on how to extract the artifacts from the Conan cache to the userspace. There have been long
discussions about the ``deploy()`` method and the need of having a default deploy behavior for every package. Although that is something we
have not discarded, we wanted to explore another approach.

Currently, the recipe is the one that describes how a package is deployed and it makes sense: the package knows what are the artifacts
needed for its deployment and the resources needed from its dependencies. However, there are scenarios where you may want to have the
deployment logic separated from the recipe and the ability to deploy every package in the same way.

Following that rationale, we thought that that point of view was closer to the consumer side and letting they chose how the deployment should
be done. Thanks to the feedback of users and proof-testing some ideas, we came out with the idea of __deployment generators__:
[Custom generator packages](https://docs.conan.io/en/latest/howtos/custom_generators.html) with the deployment logic that can be used to
consume/deploy any existing package.

The [deploy](https://docs.conan.io/en/latest/reference/generators/deploy.html) generator is just a Conan built-in one that copies the
contents of package folder (LINK) of every package in the dependency graph to the installation folder.

For example:

```
$ conan install paho-cpp/1.0.1@conan/stable -g deploy -if deployment
...
paho-c/1.3.0@conan/stable: Package installed 77ff8c6f250452f5f8a074c1c5192b5d1e08ca01
paho-c/1.3.0@conan/stable: Downloaded package revision 0
paho-cpp/1.0.1@conan/stable: Retrieving package 4afa3667876e410c5723826d8099526aa8c90bb1 from remote 'conan-center'
...
paho-cpp/1.0.1@conan/stable: Package installed 4afa3667876e410c5723826d8099526aa8c90bb1
paho-cpp/1.0.1@conan/stable: Downloaded package revision 0
Generator deploy created deploy_manifest.txt
Generator txt created conanbuildinfo.txt
```

Then, in the installation folder you will find the contents of the packages:

```
$ ls deployment
paho-cpp/  paho-c/  deploy_manifest.txt  conanbuildinfo.txt
```

In case you want to customize the deployment layout, you can create a custom script that copies the files from this basic layout to your
custom one, or you could create your own [generator](https://docs.conan.io/en/latest/reference/generators/custom.html#custom-generator).

## Reusing source files trough python requires

In Conan 1.9 we introduced a way of reusing source files that were exported with `exports_sources` in a python require. One of the problems
of this is that the behavior was somehow unexpected and introduced some intrinsic knowledge. (SIMPLIFY THIS)

In Conan 1.15 we have removed this default behavior and added an explicit way of doing this through the
[python_requires](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#python-requires) attribute. One could use something
like `self.python_requires["pyreq"].exports_sources_folder` to reuse the exported sources of a python require.

Moreover, if you want to reuse sources and inherit from base `ConanFile`, our recommendation is to follow this approach for the python
require recipe:

*conanfile.py*
```
import os
import shutil
from conans import ConanFile


class PythonRequires(ConanFile):
    name = "pyreq"
    version = "version"

    exports_sources = "CMakeLists.txt"


def get_conanfile():

    class BaseConanFile(ConanFile):

        settings = "os", "compiler", "build_type", "arch"
        options = {"shared": [True, False]}
        default_options = {"shared": False}
        generators = "cmake"
        exports_sources = "src/*"

        def source(self):
            # Copy the CMakeLists.txt file exported with the python requires
            pyreq = self.python_requires["pyreq"]
            shutil.copy(src=os.path.join(pyreq.exports_sources_folder, "CMakeLists.txt"),
                        dst=self.source_folder)

    return BaseConanFile
```
*conanfile.py with a python require and a base ConanFile reusing a CMakeLists.txt*

Note the function ``get_conanfile()`` to be used as a way to avoid the double declaration of a `ConanFile` object and keep the logic of the
python require separated.

You can find an extended example and more information about the documentation:
[Python requires: reusing code](https://docs.conan.io/en/latest/extending/python_requires.html)

## Roadmap features development

As we continue to develop Conan, we have agreed on some important features that can have a big impact on the evolution of the tool and the improvement of the user experience. We have been working in parallel with other big features in the past, such as the
[revisions](https://docs.conan.io/en/latest/mastering/revisions.html) or the
[workspaces](https://docs.conan.io/en/latest/developing_packages/workspaces.html). From the next release, we will start to focus more on the
relevant features.

Here is a brief list of the features we would like to bring in the near future:

- Graph lock: Create a way to lock dependencies taking into account the graph relations and be able to reproduce a build with the information gathered (LINK)
- Cross-building: New approach for the cross-building model focused on the concept of "context building"
  (https://github.com/conan-io/conan/projects/4).
- Components: How to model the internal relations of libraries inside the same package (https://github.com/conan-io/conan/issues/5090).
- Build helpers and generators: Separate the build logic from the dependency information in generators and be able to feed build systems
with all the information that the build helpers use (https://github.com/conan-io/conan/projects/5).

This means that we will focus the development effort in key features for Conan, although we would not stop our monthly release schedule.
There will be releases with bugfixes and small improvements coming on every release and we will be introducing the roadmap features in a
more paced way.

We believe this is the right path to bring meaningful features to the community and that this will help to shape the future of a better tool towards Conan 2.0.

-----------
<br>

Don't forget to check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html) and to
[update](https://conan.io/downloads.html).

Finally, do not hesitate to open a [new issue](https://github.com/conan-io/conan/issues) with any bug report or feedback for discussion.
Many thanks!
