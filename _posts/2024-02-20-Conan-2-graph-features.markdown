---
layout: post
comments: false
title: "Conan 2 new graph features: replacing dependencies with system requirements and API compatible dependencies"
meta_title: "Conan 2 new graph features: replacing dependencies with system requirements and API compatible dependencies"
description: "Conan 2 implements new very demanded features: the ability to replace Conan dependencies by system ones, replacing any requirement for an API compatible one (like zlib -> zlib-ng), and a new command to explain why binaries are missing"
---


We are happy to announce that one of the latest releases of Conan 2.0 has implemented some features that have been demanded for a long time, but which due to the legacy and constraints of Conan 1.X were almost impossible to implement. One of the great advantages of Conan 2.0 is that its new architecture and design allow the maintainers to quickly build and release features like these 3 new ones:

- The ability to completely drop ``requires`` defined in any Conan recipe in the dependency graph, and use system installed ones, with the ``[plaform_requires]`` feature. This feature can be very useful in different scenarios, like avoiding recipes fetching a ``cmake`` Conan package because they are ``tool_requires = "cmake/version"`` and use the system installed one, without modifying any recipe at all.
- The possibility to replace any recipe ``requires`` dependency in the dependency graph by any other dependency (as long as it is API compatible) with the ``[replace_requires]`` feature. This feature can be used to replace regular ``requires`` for system wrapper equivalents or to do a replacement of api compatible packages like swapping ``zlib`` for ``zlib-ng`` or ``libjpeg`` for ``libjpeg-turbo``, without having to modify any recipe.
- The capability of explaining in detail when a binary is missing, comparing the settings, options and dependencies of the missing binary against existing ones in cache and in remote repos, showing a diff-like result, with the new ``conan graph explain`` command.

Furthermore the first 2 features have the capability of applying to both for regular ``requires`` and ``tool_requires``. Let's have a look at these new features in detail.

## Replace Conan dependencies with system ones

Conan recipes can have both ``requires`` and ``tool_requires`` in their code, let’s use for example a typical ``tool_requires`` to a Conan ``cmake`` package, with at least version 3.25, because the ``CMakeLists.txt`` in ``mypkg`` is requiring some modern CMake features:

```python
from conan import ConanFile

class Pkg(ConanFile):
    name =   "mypkg"
    tool_requires = "cmake/[>=3.25]"
```

Now, whenever ``mypkg`` is being built from source, it will download a ``cmake/xxx`` Conan package, inject it and use it to build. This happened in the past irrespective of any CMake that the user might have installed in their system.
With this new feature, a user could define in their profile:

```ini
[platform_tool_requires]
cmake/3.26
```

Defining which version they have installed in their system. With this profile, now ``mypkg`` will no longer download a ``cmake`` package from the server, and use the system installed one. The only condition is that the system installed one must be available for the build, in this CMake case, it should be in the system PATH (or location defined in ``tools.cmake:cmake_program`` configuration).

The platform-requires system is able to check the versions. For example if some recipe had a ``tool_requires = "cmake/[>=3.27]"``, then it will know that the system installed CMake is not enough, and it will still download a ``cmake`` package that satisfies the constraint and it will use it for that package, using the system installed CMake for all the other packages that are happy with the system 3.26`` version.

The same functionality is provided for regular ``requires`` via the ``[platform_requires]`` feature. This could be the case of dropping a Conan dependency like ``requires = "openssl/3.1"`` that requires a Conan package and uses instead a system installed ``openssl``. This might be desirable for example when cross-building to some embedded targets that will provide their own specific ``openssl`` in the system (like in the sysroot while building) that must be used. Note that the system ``openssl`` must be available and usable for consumers to link it fully transparently, as Conan will no longer be injecting any information about it to the consumers. Having such a transparent usage will not be possible in many cases, because consumers still need some extra information to locate and use those system installed dependencies. In that case the following ``[replace_requires]`` will be the recommended approach:

## Replace API-compatible requirements with [replace_requires]

There are some situations where changing defined ``requires`` in the dependency graph might be very convenient.

For example, if we have all recipes in our projects requiring ``requires = "zlib/1.3"``, and then we want to introduce the ability to use ``zlib-ng`` alternative, there were 2 different approaches: just replace everywhere the requirements and use ``zlib-ng`` always (if we could drop ``zlib``), or implement conditional requirements based on input ``options`` or ``conf``. The first approach could be impossible in places like ConanCenter and the second one can be tedious and error prone.

With this new feature, it is possible by defining in the profile:

```ini
[replace_requires]
zlib/*: zlib-ng/*
```

This will replace every ``requires = "zlib/<anyversion>"`` for the same requirement, equivalent to ``requires = "zlib-ng/<anyversion>"`` using the same version as the declared one.

But sometimes, there is no 1:1 mapping between versions, for those cases it is also possible to explicitly declare the mapping:

```ini
[replace_requires]
zlib/1.0: zlib-ng/11.0
zlib/2.0: zlib-ng/12.0
```

Likewise, it is also possible to do the replacement using version ranges:

```ini
[replace_requires]
zlib/3.0: zlib-ng/[>=13.0]
```

In this case, the exact matches to ``zlib/3.0`` will be replaced by the ``zlib-ng`` one in that specific range. But other versions of ``zlib/xxx`` will not be replaced. It is possible to define also version ranges in the first pattern:

```ini
[replace_requires]
zlib/[>=3.0]: zlib-ng/[>=13.0]
```

In this case, the replacement will happen if the original range ``zlib/[>=3.0]`` is satisfied with the recipes ``requires``, either by an exact version within the range or if the recipe also declares a version range, as long as there is some overlap between the ranges.


This feature has also some other interesting use cases: For example, it can be used to **temporarily** resolve conflicts without having to modify any ``conanfile`` at all. Please note that this is not intended as a permanent conflict resolution strategy, but it can be useful while developing and testing things.

Finally, for the case explained in the section above, about scenarios like some embedded cross-building with some packages, like ``openssl`` that must be used from the system (probably it is in the sysroot), but for some reason there is information missing about them in order to easily be consumed by other packages. In cases like this, users can:

First write an alternative ``openssl/<version>@system``, that does not build anything, but mostly define in its ``package_info()`` the information to locate and use it for other packages.

Then define a profile containing:

```ini
[replace_requires]
openssl/*: openssl/*@system
```

Using that profile, the occurrences of ``requires = "openssl/version"`` will be replaced by ``requires = "openssl/version@system"`` that will use the wrapper recipe provided before with details about that dependency in that sysroot.


The ``[replace_requires]`` is valid for regular ``requires``. There is also a ``[replace_tool_requires]`` intended for the same purpose, but for ``tool_requires``, with the same rules and behavior.

## Usage of [platform_requires] and [replace_requires] in the build and host profiles

As ``[platform_requires]``, ``[platform_tool_requires]``, ``[replace_requires]`` and ``[replace_tool_requires]`` are defined in profiles, it is possible to define them in "host" and "build" profiles.

That means that it is possible to control in which context those replacements are done. For example the cross-build scenario with the ``[replace_requires]`` for ``openssl`` in the sysroot, it is very likely that if for some reason the build context happens to need openssl as transitive dependency, the build context doesn’t want to use that ``openssl`` in the sysroot. So the ``[replace_requires]`` should happen only in the "host" profile, but not in the "build" profile.

On the other hand, the above CMake example with ``[platform_tool_requires]`` would be applicable to both cases. Even if we are cross building or not, packages in the "host" (regular libraries and applications) context will be using the system installed CMake. But also, if any dependency in the "build" context, any application we use as ``tool_requires`` need to be built from source, it might need CMake itself as a transitive ``tool_requires``, and it can use the system installed CMake if possible. For this case we want to define the same ``[platform_tool_requires]`` both in the "host" and "build" profile.


## Bonus graph feature: Understand why some binaries are missing with "conan graph explain"

One of the common struggles in Conan 1.X is when installing Conan packages that were supposed to exist as pre-compiled binaries and then hitting a "Missing binary" error that looked like this:

```bash
$ conan install --requires=zlib/1.3 -s build_type=Debug
```

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2024-02-20/conan_missing_binary.png" alt="conan missing binary"/>
</p>

Even if this error message provides some information about the missing binary, it is not evident why the binary is missing. Now, as the error message suggests, we have the ``conan graph explain``. Basically typing the same ``conan install`` command, but now using ``graph explain`` to obtain something like:

```bash
$ conan graph explain --requires=zlib/1.3 -s build_type=Debug
```

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2024-02-20/conan_graph_explain.png" alt="conan graph explain"/>
</p>


That clearly explains and highlights in colors the reason why this binary is missing. In this case, it is because ConanCenter is not building Debug binaries for this compiler version, and the Release binaries are the only ones available.

The ``conan graph explain`` command is designed to explain all possible differences that cause binaries to be missing, from differences in settings, options, dependencies’ versions, configuration, etc.


## Conclusions

The new additions in Conan 2 provide some very powerful features that allow for more flexibility in the dependency resolution and implement some long time requests, like being able to replace API-compatible requirements or use system installed tools instead of the recipes declared ones.

Please check the documentation for [replace_requires](https://docs.conan.io/2/reference/config_files/profiles.html#replace-requires), [platform_requires](https://docs.conan.io/2/reference/config_files/profiles.html#platform-requires) and [conan graph explain](https://docs.conan.io/2/reference/commands/graph/explain.html). We are looking forward to hearing your feedback about these, please don’t hesitate to share it, report any bugs or ask any questions about it on GitHub issues.
