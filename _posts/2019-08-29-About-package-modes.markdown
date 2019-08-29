---
layout: post
comments: false
title: "ABI compatibility and Conan package modes"
---

**Application binary interface (ABI)** is the interface between two
binary program modules; these modules could be libraries, operating system
facilities, application or even translation units of the same codebase.
This interface can be affected by many different factors, some of them
are associated with the build environment (compiler, linker flags, name
mangling) and others with the source code itself.

If the binary interface can change, then it makes sense to talk about
ABI compatibility as the property of some modules to release newer versions
providing code changes (features, bug fixes,...) without modifying their ABI,
so other modules consuming them don't need to be recompiled or linked again
and can use the new module right away.

This is something we can achieve with C or C++ using shared libraries. Conan,
as a package manager dedicated to these languages, provides some utilities
integrated in its core model.


# Semantic version

A common practice to handle *interface compatibility* is to use semantic versioning, it is
a version schema with three components ``major.minor.patch`` where each number
has some semantics associated:
 * ``major``: different numbers indicate incompatible interfaces,
 * ``minor``: new features (with compatible interface) should bump this number, and
 * ``path``: versions that only contain bugfixes can modify just this component.
 
It is a nice model, but with some major caveats: it is not always easy to realize
about the impact of code changes in the interfaces and not all projects are committed to
this versioning schema. There is also one additional problem related to compiled languages,
like C and C++, in these languages we have two types of interfaces: the ABI we have already
talked about and the **application programming interface (API)**, and they have different
rules regarding compatibility.

With two interfaces dangling around, semantic versioning is not powerful enough, and projects
tend to abandon it (or limit its usage for the API) and recommend to always build and link
applications against their libraries with any change. This leads to longer build times and
make it quite difficult to reuse already compiled binaries.


# ABI compatibility and Conan: package IDs

One of the main objectives of a package manager is to make it possible to reuse
existing binaries and be confident that the retrieved artifacts will link to or work
with the consumer application. In order to achieve this objective, Conan identifies
each artifact using several coordinates:
 * **reference (``<ref>``)**: it declares the name and version of the library, 
   like ``boost/1.69.0``
 * **recipe revision (``<rrev>``)**: an identifier to track changes in the recipe sources
 * **package ID (``<pid>``)**: the identifier of the artifact itself, it encodes information
   about settings, options and dependencies.
 * **package revision (``<prev>``)**: checksum of all the binaries and any asset included
   in the package (read about deterministic builds ``TODO: ADD LINK TO BLOGPOST!!``).

With all this components, a full package reference is of the form of ``<ref#rrev:pid#prev>``.
Take into account that [*revisions* for recipes and packages](https://docs.conan.io/en/latest/versioning/revisions.html)
will only be available if activated explicitly in the Conan configuration.


# Conan package ID

Given a *reference* and a *recipe revision*, an artifact is identified using the package ID,
it encodes many information, let's explore it with the example recipe in the ``conanfile.py``
below:

```python
from conans import ConanFile

class Library(ConanFile):
    name = "name"
    version = "version"
    
    settings = "os", "compiler", "build_type"
    options = {"shared": [True, False]}
    default_options = {"shared": True}
    
    requires = "fmt/5.3.0@bincrafters/stable"
    build_requires = "cmake_installer/3.15.2@conan/stable"

```

Using the Conan client we can compute the package ID of the generated package with
the command [``conan info`](https://docs.conan.io/en/latest/reference/commands/consumer/info.html#conan-info):

```bash
⇒  conan info . --profile=default
...
conanfile.py (name/version)
    ID: e428eb64754bfe27c70898e9876b5c3fd718e9cb
...
```

The ID obtained depends on the values of your ``default`` profile as we are going to see
in the following sections.

#### Settings

The package ID will be different depending on the values of **the settings declared in the
recipe**, other settings won't affect the package ID (I will omit all non-relevant output):

```bash
⇒  conan info . --profile=default -s build_type=Debug -s arch=x86_64
conanfile.py (name/version)
    ID: a750fa83b6f24d4476c40c25590041ff2645ab31

⇒  conan info . --profile=default -s build_type=Release -s arch=x86_64
conanfile.py (name/version)
    ID: e428eb64754bfe27c70898e9876b5c3fd718e9cb

⇒  conan info . --profile=default -s build_type=Release -s arch=x86
conanfile.py (name/version)
    ID: e428eb64754bfe27c70898e9876b5c3fd718e9cb
```

As it is shown, changing the ``build_type`` value modifies the ID because it is declared
in the recipe, but changing the ``arch`` doesn't. 

#### Options

Values for options also modifies the package ID. The recipe declared a ``shared`` option
with two possible values, the package ID will be different for each of them:

```bash
⇒  conan info . --profile=default -o shared=True
conanfile.py (name/version)
    ID: e428eb64754bfe27c70898e9876b5c3fd718e9cb

⇒  conan info . --profile=default -o shared=False
conanfile.py (name/version)
    ID: 408c4649c4bdbaa4d09ddad02708b60bc019c9ec
```

#### Dependencies 

The package ID also takes into account information from the dependencies, and here Conan
provides huge flexibility with the different **package ID modes**. Depending on the 
package ID mode configured for the Conan client (see [``general.default_package_id_mode``](https://docs.conan.io/en/latest/reference/config_files/conan.conf.html#general)
configuration variable) or the one selected for an specific requirement, the full package
reference (even with recipe and package revisions) of the requirements could affect
the package ID. I'll dedicate the next section to elaborate on this matter.


# Package ID modes

We have already explained that the package ID is the hash that encodes all the information
related to the configuration, options and dependencies of a package. Conan provides several
package ID modes that allow actual fine-grained customization on how changing dependencies
of a recipe may may modify its package ID.

The package ID mode has always a Conan client-wide mode that will be applied to all the
dependencies unless the recipe overrides explicitly the mode for all its requirements or for
a particular require. This can be done in the ``package_id()`` method:

```python
def package_id(self):
    self.info.requires.semver_direct_mode()
    self.info.requires["zlib"].full_version_mode()

```

These modes go from ``unrelated_mode`` to ``package_revision_mode``, using the first one
nothing from the dependencies will affect the package ID (not even adding an additional
requirement), while the last one will generate a different package ID for any change in the
requirement (even a new build of the same binary if it produces a different package revision).


TODO: REQUIRES -vs- BUILD_REQUIRES
TODO: NOTE ABOUT LIBRARIES NOT FOLLOWING SEMVER


#### Default behavior: ``semver_direct_mode`

The default Conan behavior is to use ``semver_direct_mode``, it is adecuated if the
dependencies follow the _semantic versioning_ scheme applied to the ABI that I've
commented above. 

Coming back to the example of the recipe introduced above, with ``semver_direct_mode``
only a change in the _major_ component of the ``cmake_installer`` version will result
in a different package ID, while any other change won't affect that ID:

```bash
⇒  conan config set general.default_package_id_mode=semver_direct_mode

⇒  conan info . --only id --profile=default
fmt/5.3.0@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: 38dbf89d158028a99d09852abf8b8a82ede43714

⇒  conan info . --only id --profile=default
fmt/5.2.1@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: 38dbf89d158028a99d09852abf8b8a82ede43714

⇒  conan info . --only id --profile=default
fmt/4.1.0@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: 19d34f4e911e399b2fb93166523221c5e1f14f06

⇒  conan info . --only id --profile=default -o fmt:shared=True
fmt/4.1.0@bincrafters/stable
    ID: 95b87e2c9261497d05b76244c015fbde06fe50b3
conanfile.py (name/version)
    ID: 19d34f4e911e399b2fb93166523221c5e1f14f06

```

In the output above it is shown that the package ID for the recipe only
changes when the _major_ component of the requirement ``fmt`` changes (although
the package ID for ``fmt`` is the same). And it doesn't change if we modify
an option of the ``fmt`` package, the package ID corresponding to ``fmt`` changes
but the one of the example recipe doesn't.


#### Other package ID modes

#### Working with revisions


# Conclusion

