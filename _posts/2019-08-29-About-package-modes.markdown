---
layout: post
comments: false
title: "The riddle of C++ builds"
subtitle: "ABI compatibility and Conan package modes"
---

> **Thulsa Doom:** There was a time, boy, when I searched for steel, when steel
>     meant more to me than gold or jewels.
>
> **Conan:** The riddle... of steel.
>
> **Thulsa Doom:** Yes! You know what it is, don't you boy? Shall I tell you?
>
> <div style="text-align: right">Conan the Barbarian (John Milius, 1982)</div>


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
changes (from ``38dbf89d`` to ``19d34f4e``) when the _major_ component of
the requirement ``fmt`` changes (although the package ID for ``fmt`` is the same).
And it doesn't change if we modify an option of the ``fmt`` package, the package ID
corresponding to ``fmt`` changes but the one of the example recipe doesn't.


#### Other package ID modes

There are many more package ID modes to use (see [full list](https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html#versioning-schema)),
here we are going to show just some of them:

 * **``full_version_mode``**: it will take into account all the components of the
   semver version:
   
   ```bash
   ⇒  conan config set general.default_package_id_mode=full_version_mode
   
   ⇒  conan info . --only id  --profile=default                         
   fmt/5.2.1@bincrafters/stable
       ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
   conanfile.py (name/version)
       ID: 840962321acb965eeab4e8507bdb9e85c11a06fd
   
   ⇒  conan info . --only id  --profile=default                         
   fmt/5.2.0@bincrafters/stable
       ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
   conanfile.py (name/version)
       ID: 8e9392814f9e6f0132c2e383d60364623ca759b5
   ``` 
   
 * **``full_package_mode``**: any change in the package reference (excluding revisions) will
   modify the package ID of the consumer recipe. Let's see how modifying an option in the
   required recipe affects the recipe itself:
   
   ```bash
   ⇒  conan config set general.default_package_id_mode=full_package_mode
   
   ⇒  conan info . --only id  --profile=default -o fmt:shared=False
   fmt/5.2.0@bincrafters/stable
       ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
   conanfile.py (name/version)
       ID: 50fb56084639e9d7f970e1c79e36f53b452eb552
   
   ⇒  conan info . --only id  --profile=default -o fmt:shared=True
   fmt/5.2.0@bincrafters/stable
       ID: 95b87e2c9261497d05b76244c015fbde06fe50b3
   conanfile.py (name/version)
       ID: 159983fa331b57530730eaf05aedeb3628307264
   
   ```

Try other modes in your machine changing the versions of your requirements and see how the
package ID of the consumer recipe changes. All these modes provide a high level of 
customization that allow fine-grained control over the package ID.


#### Working with revisions

Conan v1.10.0 introduced [revisions for recipes and packages](https://docs.conan.io/en/latest/versioning/revisions.html),
although the feature is experimental we are pretty sure that it arrived to stay and
will become stable soon. Revisions for recipes (``<rrev>``) provide a way to version the recipe
sources without changing the version of the recipe itself, while package revisions (``<prev>``) are a
way to differentiate binaries built using exactly the same recipe sources (see [reproducible builds](TODO: Add link to zoido's)).

Together with revisions, two new modes were added to the available list of package ID modes to
optionally consider these components of the full Conan reference (``<ref>#<rrev>:<pid>#<prev>``)
of the requirements. These modes were:

 * **``recipe_revision_mode``**: it is like the ``full_package_mode``, but it takes into account
   the recipe revision too.
 * **``package_revision_mode``**: to take into account the full reference including the package
   and recipe revisions.
   
Using these modes, Conan will compute a new package ID for any change in the requirements, usually
it is more than needed but it is the safest way to ensure ABI compatibility: it the package ID
computed has been already compiled, then we can be sure that the binary available will be ABI
compatible.

To play the following example we need to activate revisions and use different revisions of
the requirements. Take into account that the Conan cache will store only one revision at a time,
you wll need to use one Artifactory server (download free
[JFrog Artifactory Community Edition for C/C++](https://jfrog.com/blog/announcing-jfrog-artifactory-community-edition-c-c/))
if you want to persist them because Bintray repositories doesn't implement revisions:

 1. Let's configure Conan for this example (use the proper URL for the repository in your
    Artifactory instance):

    ```bash
    ⇒  conan config set general.revisions_enabled=1
    ⇒  conan config set general.default_package_id_mode=recipe_revision_mode
    ```
    
 2. Now we will check the ID generated with one revisions of the ``fmt`` requirement:
 
    ```bash
    ⇒  git clone https://github.com/bincrafters/conan-fmt.git
    ⇒  cd conan-fmt
    ⇒  conan export . bincrafters/stable
    ...
    fmt/5.3.0@bincrafters/stable: Exported revision: 500ad2e039e90e5aa50b8ceb6a35a3e1
    ```
    
    We can ask Conan to compute the package ID of our recipe, it will use the recipe of the
    ``fmt`` library that we have just exported:
    
    ```bash
    ⇒  conan info . --only id  --profile=default
    fmt/5.3.0@bincrafters/stable
        ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
    conanfile.py (name/version)
        ID: 46516d5f2debf0f4b7e55da9e75bfe277d26a1fc  
    ```
    
 3. We can modify the recipe of ``fmt`` to generate a different revision, and we can export it
    to the Conan cache (it will override the existing one as only one revision can be in the
    cache at a time):
    
    ```bash
    ⇒  git clone https://github.com/bincrafters/conan-fmt.git
    ⇒  cd conan-fmt
    ⇒  echo "# Add a comment at the end of the file" >> conanfile.py
    ⇒  conan export . bincrafters/stable
    ...
    fmt/5.3.0@bincrafters/stable: Exported revision: 30bb32c064e1c43b70d5cb9e2749e484
    ```
    
    If we compute the package ID of our recipe, now it is a different one, and only the recipe
    revision of the ``fmt`` package has changed.

    ```bash
    ⇒  conan info . --only id  --profile=default
    fmt/5.3.0@bincrafters/stable
        ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
    conanfile.py (name/version)
        ID: 859c7995b3e1554bd4a456aee82a45f0c6ade2f7  
    ```

As a final note related to the revisions, if we try to compute the package ID of our recipe using
the ``package_revision_mode`` Conan will take into account the package revision of the
requirements too. In the previous steps we have just exported a new recipe revision for
the ``fmt`` package, but we haven't generated the binaries:

```bash
⇒  conan config set general.default_package_id_mode=package_revision_mode
⇒  conan info . --only id --profile=default       

fmt/5.3.0@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: Package_ID_unknown
```

With this mode enabled, Conan cannot compute the package ID because it cannot know the package
revision of the ``fmt`` package it would use if it were available. Once we compile the binary,
Conan will be able to compute the package ID:

```bash
⇒  conan install fmt/5.3.0@bincrafters/stable --profile=default --build fmt

⇒  conan info . --only id --profile=default         

fmt/5.3.0@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: b2110045f8b2598a521adad9753eb610ba4059ee
```

# Conclusion

ABI compatibility should be a major concern of any build engineer involved in a C++ project.
Understanding ABI complexity, defining a meaningful version scheme for the libraries involved
in the project and using the right tools for the problem, CI build times and developers
compile efforts could be reduced in several orders of magnitude with confidence.

Conan provides the tools, it is up to the project manager to define a versioning scheme and
everything should be ready to exploit a CI system without wasting resources.
