---
layout: post
comments: false
title: "Package ID modes"
---

As we explained in our previous blogpost about [deterministic builds](LINK) it is not possible
to identify a compiled C/C++ artifact by its checksum, same sources will lead to different
binaries, so there is no _correct_ result we can agree on to certify a binary.

This is big problem for many industries where software is a critical component in their
products: aeronautics, medical, automotive,... almost any industry will get into trouble if
its artifacts can be tampered with without noticing. 

Conan doesn't rely on the checksum of the binaries, but on the **package ID to identify the
binaries**, it is an unique identifier that encodes information about settings, options and
requirements of each package. We will explain how knowing the package ID you can know
exactly which are the libraries deployed or even the source code used to generate the artifacts.


## How package ID works

Conan compute a different package ID for any combination of the following elements:
 * **Settings**. Depending on the value of the settings declared in the recipe, a different
   package ID will be computed, so different _operating systems_, _compilers_, _build types_,...
   will produce different IDs.
   
 * **Options**. The value of the options will also be added to generate the
   package ID.
   
 * **Requirements**. Depending on the package ID mode configured for the Conan client or the
   one declared for an specific requirement, different components of the full Conan 
   package reference could affect the package ID of the consumer.
   
   Take into account that transitive requirements (dependencies of my dependencies) are
   encoded into my package ID through the package ID of my requirements.
   
*Note.-* Only the dependencies declared using the ``requires`` attribute or inside the
``requirements()`` method will be considered, **build requires doesn't affect the package ID**.


## Quick reminder about Conan package reference

Before moving on, we need to introduce what a Conan package reference is and which are its
components. A Conan package reference is the unique identifier of the products of a build that
are bundled into a package, it is compounded by the following parts:

 * **Conan reference**. It is the identifier of the recipe, like ``fmt/5.3.0@bincrafters/stable``
   for example, it contains the _name_ and the _version_ of the recipe, and the _user/channel_
   information: ``<name>/<version>@<user>/<channel>``.
   
   Conan v1.10 introduced [recipe revision](https://docs.conan.io/en/latest/versioning/revisions.html),
   which is a way to version the recipe sources without touching the main components of the
   recipe reference. This is an example of a full Conan reference:
   
   ```bash
   fmt/5.3.0@bincrafters/stable#500ad2e039e90e5aa50b8ceb6a35a3e1
   ```
   
   Notice that Conan will interpret the ``<version>`` component as SemVer if possible.
   
 * **Package ID**. It is the unique identifier of the package binaries, we will elaborate on it
   on next sections in this blogpost.
   
 * **Package revision**. Introduced in Conan v1.10, it is the hash of the contents of the package.
   As it was said before, same sources will tipically generate different binaries even using the
   same environment.
   
Given all this components, a full Conan package reference will contain all these information
``<name>/<version>@<user>/<channel>#<rrev>:<pkg_id>#<prev>`` and it identifies uniquely
every Conan package build.


## Importance of package ID modes

Conan has the ability to identify every single package build, and all this information could
be propagated to the consumer's package ID, but this would lead to a big drawback: any build
of a requirement (or transitive requirement) would modify all the package IDs down in the
dependency graph, those new IDs wouldn't have binaries available and we would need to compile
them. In most cases this is an undesirable effect.

Here relies the utility and importance of package ID modes, they allow to configure which
components of the full package reference should be considered to compute the package ID of
the consumer.

These modes go from ``unrelated_mode`` where nothing from the requirement is taken into
account to ``package_revision_mode`` where everything (including package revisions) will
modify the package ID. And there are many other modes in between.

Choosing the right package ID mode for your project is an important decision. You should
carefully consider the versioning schema of your dependencies, your CI times, the criticity
of source code changes in your system (can a bugfix be a breaking change?),... all these
factors can be managed using the right package ID mode in your recipes.

## Conan default behavior: ``semver_direct_mode``

By default Conan uses ``semver_direct_mode`` which means that it will compute a different
package ID whenever the _major component_ of the version of its requirements is different.
This is a quite relaxed method with big assumptions: all the dependencies use properly a
SemVer versioning schema, my application is not sensible to new features or bugfixes, and
it is ok to ignore changes in options or settings of my requirements.
Although it might be adecuate for general purpose libraries and the open source community,
it is probably not the best approach for company software.

Let's explore it with the example recipe in the ``conanfile.py`` below: 

```python
from conans import ConanFile

class Library(ConanFile):

    name = "name"
    version = "version"
    
    settings = "os", "compiler", "build_type"
    options = {"shared": [True, False]}
    default_options = {"shared": True}
    
    requires = "fmt/5.3.0@bincrafters/stable"
```

Using the Conan client we can compute the package ID of the generated package with
the command [``conan info`](https://docs.conan.io/en/latest/reference/commands/consumer/info.html#conan-info):

 ```bash
⇒  conan info . --profile=default
...
conanfile.py (name/version)
    ID: f38e4ae2fcc1fd3b6f76fde9093cfce7d4d11f94
...
```

The ID obtained depends on the values of the settings and options used, here we are telling Conan
to use explicitly the profile ``default``. If you want to reproduce the same package ID values
that appear in this post, you can use this profile:

 ```bash
⇒  conan profile show default

Configuration for profile default:
[settings]
os=Macos
arch=x86_64
compiler=apple-clang
compiler.version=10.0
compiler.libcxx=libc++
build_type=Release
[options]
[build_requires]
[env]
```

As we've already said, only a change in the _major component_ of the requirements will affect
the package ID value using the ``semver_direct_mode`:

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
 
In the output above it is shown that the package ID for the recipe
changes (from ``38dbf89d`` to ``19d34f4e``) only when the _major_ component of
the requirement ``fmt`` changes (although the package ID for ``fmt`` is the same).
And it doesn't change if we modify an option of the ``fmt`` package, the package ID
corresponding to ``fmt`` changes but the one of the example recipe doesn't.
 
With the ``semver_direct_mode``, as long as the _major_ doesn't change, we can
modify the transitive dependencies (even add or remove them) as much as we want: we
can modify options to activate features or switch behaviors, we can use different linking
options,... it all depends on the library writer, but we can agree that there are too
many degrees of freedom under the same package ID of our library. We won't be able
to dissambiguate as many configuration lead to the same package ID.


## Other package ID modes

There are many more package ID modes to use (see [full list](https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html#versioning-schema)),
here we are going to show just some of them:

  * **``full_version_mode``**: it will take into account all the components of the
    SemVer version:

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
    required recipe modify its package ID and a new value is computes for our package:

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

The two last fields of the Conan reference of the requirements, ``user`` and ``channel`` does
not affect for most of the package ID modes, only ``full_recipe_mode`` and ``full_package_mode``
(and modes for revisions that we'll write about below) will take them into account.


## Working with revisions

Conan v1.10.0 introduced
[revisions for recipes and packages](https://docs.conan.io/en/latest/versioning/revisions.html),
although the feature is experimental we are pretty sure that it arrived to stay and
will become stable soon. Revisions for recipes (``<rrev>``) provide a way to version the recipe
sources without changing the version of the recipe itself, while package revisions (``<prev>``) are a
way to differentiate binaries built using exactly the same recipe sources (see
[reproducible builds](TODO: LINK TO BLOGPOST)).

Together with revisions, two new modes were added to the available list of package ID modes to
optionally consider these components of the full Conan reference (``<ref>#<rrev>:<pkg_id>#<prev>``)
of the requirements. These modes are:

 * **``recipe_revision_mode``**: it is like the ``full_package_mode``, but it takes into account
   the recipe revision too.
 * **``package_revision_mode``**: additionally it takes into account the package revision.

Using these modes, Conan will compute a new package ID for any change in the requirements, usually
it's more than needed but it's the safest way to ensure binary traceability and reproducibility:
only the same set of requirements configured the same way will be able to generate the same
package ID, and with the mode ``package_revision_mode`` only using the same actual packages will
generate the same package ID.

To play the following example we need to activate revisions and use different revisions of
the requirements. Take into account that the Conan cache will store only one revision at a time,
you will need to use one Artifactory server (download free
[JFrog Artifactory Community Edition for C/C++](https://jfrog.com/blog/announcing-jfrog-artifactory-community-edition-c-c/))
if you want to persist them because Bintray repositories doesn't implement revisions. Follow
this steps for the ``recipe_revision_mode``:

  1. Configure Conan for this example:

     ```bash
     ⇒  conan config set general.revisions_enabled=1
     ⇒  conan config set general.default_package_id_mode=recipe_revision_mode
     ```

  2. Check the ID generated with one revisions of the ``fmt`` requirement:

     ```bash
     ⇒  git clone https://github.com/bincrafters/conan-fmt.git
     ⇒  cd conan-fmt
     ⇒  git checkout 7d9dce3
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
     ⇒  git checkout 7d9dce3
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
requirements too. Let's see what happens if the binaries for the ``fmt`` recipe are not 
available:

```bash
⇒  conan remove fmt/5.3.0@bincrafters/stable -p
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

⇒  conan config set general.default_package_id_mode=package_revision_mode
⇒  conan info . --only id --profile=default         
fmt/5.3.0@bincrafters/stable
    ID: 853c4b61e2571e98cd7b854c1cda6bc111b8b32c
conanfile.py (name/version)
    ID: b2110045f8b2598a521adad9753eb610ba4059ee
```

Remember that the package ID for our recipe is taking into account the package revision
of ``fmt``, which is computed using the checksum of the generated binaries, so every
compilation will get a different package revision for that requirement and the computed
package ID will be different. That's the reason why the last value is not reproducible if
you are executing the examples, and you will get a new value with each compilation of the
``fmt`` library.
 

## Conclusion

Conan package ID modes allow really fine-grained control to choose how the dependencies
may affect the package ID of your libraries, if you make the deploy of your applications
using Conan packages and keep track of these identifiers, you can control which are the
requirements included in any release.

Software more sensitive should use more strict modes, while the community will tipically
use relaxed modes, but with Conan is easy to change the mode as we've seen along the post,
it is just a value in the Conan settings.
