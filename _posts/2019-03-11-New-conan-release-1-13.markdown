---
layout: post
comments: false
title: "Conan 1.13: Recipe and package revisions, package ID versioning mode, update on editable packages and workspaces"
---

We are bringing Conan 1.13 release and here you have a new edition of the highlighted features you may find handy in this new version. Let's
check them out!

## Recipe and package revisions

Some releases ago we started to include some of the changes needed to adapt the Conan internals to work with the new revisions concept, that
is an implicit way of creating revisions of the same version of a package without having to bump the version explicitly.

The motivation to include this concept in packages an recipes was mainly driven by the fact that in most of the situations when developing a
Conan package, the recipe *conanfile.py* follows a different development cycle. An example of this could be a recipe adding support for
building in another OS. Adding this change would probably not require any change in the library itself nor in the build system, however, to
reflect that change you would need to upload the recipe to a remote with the same reference (e.g. ``lib/1.1.2@user/channel``) and overwrite
the previous version.

This has problems for the traceability of packages (you lose the old version -in fact "revision"-) and have no way to go back to previous
state. Some users already noticed it when using Conan in production and started to append the commit or just a number at the end of the
library version, something like ``lib/1.1.2-<commit-hash>@user/channel``. Although this solved the traceability issue, this has the
disadvantage of having to bump the version on every other recipe depending on the updated one.

We have realized that to make it work properly, this behavior should be implemented as part of the Conan model and that's why this release
includes the first experimental version of Conan working with revisions!

### Revisions explained

The current Conan model uses *references* to talk about a recipe associated to a scope created with a user and a channel ``<package_name>/<version>@<user_name>/<channel>`` and a *package ID* which is a hash of the settings options and requirements used to identify the binary
packages.

Normally to indicate a binary package of package you would need something like: ``<package_name>/<version>@<user_name>/<channel>:<package_id>``

This model has not changed and you will still be able to use this *package reference* in the commands and recipes. However, we have added
two more levels:

- Recipe revision (*RREV*): A unique ID using the latest VCS hash or a checksum of the recipe manifest (*conanfile.py* with files exported
  if any).
- Package revision (*PREV*): A unique ID using the checksum of the package manifest (all files stored in a binary package).

This would mean that now to specifically refer to a binary package you would have to indicate something like:
``<package_name>/<version>@<user_name>/<channel>#<RREV>:<package_id>#<PREV>``

### Working with revisions

The concept of revisions is mostly server side, where all the recipe revisions and package revisions will be stored. In the client side we
only have one revision always.

To try and work with revisions in the client, you would need to opt in setting ``CONAN_REVISIONS_ENABLED=1`` in the environment or enabling
that in the configuration file:

```
$ conan config set general.revisions_enabled=True
```

You would also need a ``conan_server`` updated to 1.13 and it will be fully supported in upcoming versions of JFrog Artifactory soon.

Now, every time a recipe is exported or a package is created, it will get a new revision:

```
$ conan create . user/channel
(py37-conan) λ conan create . user/channel
Exporting package recipe
...
IrrXML/1.2@user/channel: Folder: C:\Users\danimtb\.conan\data\IrrXML\1.2\user\channel\export
IrrXML/1.2@user/channel: Using git commit as the recipe revision: 681d7e590d2da0a164166f737a49cf32c735ee6c
...
Requirements
    IrrXML/1.2@user/channel from local cache - Cache
Packages
    IrrXML/1.2@user/channel:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 - Build
...
IrrXML/1.2@user/channel: Package '6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7' created
```

You can search the packages created as usual but also the recipe revision just created:

```
$ conan search IrrXML/1.2@user/channel --revisions

Revisions for 'IrrXML/1.2@user/channel':
681d7e590d2da0a164166f737a49cf32c735ee6c (No time)
```

The "(No time)" output is just a reference to get when it was exported, however this time will come from the server. If the commit of the
repo where the recipe is living changes, there will be a new revision created that will replace the current one in the client. However, you
can upload it to the server and you will have different revisions:

```
$ conan search IrrXML/1.2@user/channel --revisions --remote server

Revisions for 'IrrXML/1.2@user/channel' at remote 'conan-local':
72389507bbaab233bb3bad798432c19a05752ae7 (2019-03-11 14:26:25 UTC)
681d7e590d2da0a164166f737a49cf32c735ee6c (2019-03-11 13:42:50 UTC)
```

Now, anyone installing or performing a ``conan install --update`` will automatically get the latest revision from the server. Moreover, they
can also target target a specific recipe revision:

```
$ conan install IrrXML/1.2@user/channel#681d7e590d2da0a164166f737a49cf32c735ee6c --remote server

(py37-conan) λ conan install IrrXML/1.2@user/channel#681d7e590d2da0a164166f737a49cf32c735ee6c -r conan-local --update
...
[==================================================] 372B/372B
IrrXML/1.2@user/channel: WARN: The package IrrXML/1.2@user/channel:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 doesn't belong to the installed recipe revision, removing folder
Installing package: IrrXML/1.2@user/channel
Requirements
    IrrXML/1.2@user/channel from 'conan-local' - Cache
Packages
    IrrXML/1.2@user/channel:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 - Download
...
```

Read more about revisions in the (documentation)[https://docs.conan.io/en/latest/mastering/revisions.html] and don't forget that we are open
to any feedback.

## Package ID versioning mode

From the beginning Conan has always used (Semantic Versioning)[https://semver.org/] for requirements version to calculate the package ID has
for every binary package. That means that a package ``libA/1.2.3`` which is a dependency of ``libB/1.0.0`` will change the binary hash of
``libB`` only if the major part of the version is changed. Otherwise it will hash to the same package ID.

Let's make test it:

- *libA/1.2.3*

  *conanfile.py*
  ```
  from conans import ConanFile

  class Lib(ConanFile):
      pass
  ```

  ```
  $ conan create conanfile.py libB/1.2.3@user/channel
  ...
  $ conan create conanfile.py libB/1.2.3@user/channel
  ...
  $ conan create conanfile.py libB/2.0.0@user/channel
  ...
  ```

- *libB/1.0.0*:

  *conanfile.py*
  ```
  from conans import ConanFile

  class Lib(ConanFile):
      name = "libB"
      version = "1.0.0"
      requires = "libA/1.2.3@user/channel"
  ```

  ```
  $ conan info .
  ...
  libA/1.2.3@user/channel
      ID: 5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9
      BuildID: None
      Remote: None
      Recipe: Cache
      Revision: 7ee2bfe571d258167c9356f2d7f503b3
      Binary: Cache
      Binary remote: None
      Creation date: 2019-03-11 16:09:47
      Required by:
          conanfile.py (libB/1.0.0@None/None)
  conanfile.py (libB/1.0.0@None/None)
    ID: 8a4d75100b721bfde375a978c780bf3880a22bab
    BuildID: None
    Requires:
        libA/1.2.3@user/channel
  ```

  You can see that the binary ID generated for *libA* would be ``8a4d75100b721bfde375a978c780bf3880a22bab``. If we change the requirement to
  ``libA/1.3.3@user/channel`` we will get the same ID for *libA*. However, if we change the requirement to the major version
  ``libA/2.0.0@user/channel`` this will be reflected as a **new package ID** for *libA*, in this case
  ``f1fc64edd1a6c2fb7d41b78ecf5972a0e7a85df8``.

  ```
  $ conan info conanfile.py
  libA/2.0.0@user/channel
      ID: 5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9
      BuildID: None
      Remote: None
      Recipe: Cache
      Revision: 233bc35f1c94fcf2a2f18420d0d2bb45
      Binary: Cache
      Binary remote: None
      Creation date: 2019-03-11 16:19:42
      Required by:
          conanfile.py (libB/1.2.3@None/None)
  conanfile.py (libB/1.2.3@None/None)
      ID: f1fc64edd1a6c2fb7d41b78ecf5972a0e7a85df8
      BuildID: None
      Requires:
          libA/2.0.0@user/channel
  ```

This behavior was the default and couldn't be changed until Conan 1.13, where you are able to set this globally in your configuration file
*conan.conf*:

```
[general]
default_package_id_mode = full_package_mode
```

Following the previous example but using the default package ID mode to ``full_package_mode``, will indicate a new libA binary for any
change on the version of *libB*.

Any of the modes described in
(Defining Package ABI compatibility)[https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html#id3] section from the
documentation can be used and setting this will come handy to anyone who wants to have fine control over the package ID generation and the
compatibility of binaries regarding its dependencies.

## Update on editable packages

In latest release we also brought *editable* packages as a way to map a custom layout of a project to consume the binaries of a package
without the need of exporting them to the cache.

In this release we have enhanced this feature with useful changes:

- Layout files now allow the usage of (Jinja templating)[http://jinja.pocoo.org/] for settings and options:

  ```
  [includedirs]
  src/core/include
  src/cmp_a/include

  [libdirs]
  {% if options.shared %}
  build/{{settings.build_type}}/shared
  {% else %}
  build/{{settings.build_type}}/static
  {% endif %}
  ```

- Command has been renamed to ``conan editable`` with the corresponding subcommands ``conan editable add``,
  ``conan editable remove``.

- Now you can show all the packages that are configured as editable too:

  ```
  $ conan editable list
  libB/1.2.3@user/channel
    Path: C:\Users\danimtb\test
    Layout: None
  ```

Check the docs for more info about (editable packages)[https://docs.conan.io/en/latest/developing_packages/editable_packages.html].

## New implementation for Workspaces

The workspaces feature is back with a new implementation on top of the *editables*. The use case for this feature was the fact of working
simultaneously on more than one package. Making changes on any dependency will require to issue a Conan command to make the changes
available in the cache to be consumed by a downstream package.

The Conan workspaces allow to have more than one package in user folders, and have them to directly use other packages from user folders
without needing to put them in the local cache. Furthermore, it enables incremental builds on large projects containing multiple packages.

Basically, you define a workspace YAML file with the layout of your projects:

*conanws.yml*
```
editables:
    say/0.1@user/testing:
        path: say
    hello/0.1@user/testing:
        path: hello
    chat/0.1@user/testing:
        path: chat
layout: layout_gcc
workspace_generator: cmake
root: chat/0.1@user/testing
```

And you indicate a general (editable layout file)[https://docs.conan.io/en/latest/reference/config_files/editable_layout.html] or set a
specific one for each package as well as the root *consumer* package you are building for.

Finally a workspace generator that will be the wrapper for all the packages in the workspace. Similar to the concept of Visual Studio with
the projects (editable packages) that can be included in a global solution (workspace). Currently the only supported generator is CMake,
although a Visual Studio one could be feasible.

We have introduced a specific command and subcommand for workspaces, ``conan workspace install``, that will use the aforementioned workspace
file to set the libraries into editable mode and generate the workspace generator file *conanworkspace.cmake* to be used:

```
$ conan workspace install ../cmake/conanws_gcc.yml

Requirements
    chat/0.1@user/testing from user folder - Editable
    hello/0.1@user/testing from user folder - Editable
    say/0.1@user/testing from user folder - Editable
Packages
    chat/0.1@user/testing:586bfc45a254754b47be1e6553aab648a85e425b - Editable
    hello/0.1@user/testing:98ce62312cb8b844c4a47cba2e495294a7e3e4ba - Editable
    say/0.1@user/testing:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 - Editable

say/0.1@user/testing: Generator cmake created conanbuildinfo.cmake
say/0.1@user/testing: Generated conaninfo.txt
say/0.1@user/testing: Generated graphinfo
say/0.1@user/testing: Generated conanbuildinfo.txt
hello/0.1@user/testing: Generator cmake created conanbuildinfo.cmake
hello/0.1@user/testing: Generated conaninfo.txt
hello/0.1@user/testing: Generated graphinfo
hello/0.1@user/testing: Generated conanbuildinfo.txt
chat/0.1@user/testing: Generator cmake created conanbuildinfo.cmake
chat/0.1@user/testing: Generated conaninfo.txt
chat/0.1@user/testing: Generated graphinfo
chat/0.1@user/testing: Generated conanbuildinfo.txt
```

Take a look at the (workspaces documentation)[https://docs.conan.io/en/latest/developing_packages/workspaces.html] things like changing the
layout of packages, having more than one root or how to use multi configuration (Release/debug) packages.

----
<br>

In case you want to learn more about the changes in this release, check the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html) with the link to the Pull Request with the implementation and discussion details
and don't forget to [update](https://conan.io/downloads.html).

Finally, if you find a bug or want to start a new discussion, please do not hesitate to open a new issue
[here](https://github.com/conan-io/conan/issues). Many thanks!