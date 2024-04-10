---
layout: post
comments: false
title: "Conan launches new local-recipes-index repository type"
meta_title: "Introducing Local-Recipes-Index in Conan - Conan Blog"
description: "Dive into the local-recipes-index feature by Conan."
---

ConanCenter, the central open-source repository for C and C++ libraries, is a success
story, containing a vast majority of C and C++ open-source packages. It processes hundreds
of thousands of download requests daily, building its packages from a central GitHub
repository (https://github.com/conan-io/conan-center-index), which is organized in a
specific folder layout and has received nearly 6,000 pull requests from contributors in
2023 alone.

However, ConanCenter does not fit all use cases. For instance, it cannot include
closed-source libraries or tools that might still be beneficial to the community.
Additionally, some organizations, particularly large enterprises, prefer not to use
binaries downloaded from the internet. Instead, they build their own binaries in-house
using the `conan-center-index` recipes. These organizations often need to customize these
recipes to meet unique requirements that are not applicable to the broader community,
making such contributions unsuitable for the upstream repository. The Conan documentation
(https://docs.conan.io/2/devops/conancenter/hosting_binaries.html) acknowledges this
practice, recommending working from a fork of `conan-center-index` for such needs.

For all those reasons in version 2.2.0, Conan introduced a new repository type called
`local-recipes-index`, designed to offer more flexibility by allowing a Conan remote to
point to a local copy of Conan recipes with a specific layout. This feature, combined with
a remote repository like Artifactory, provides an integrated workflow for managing
dependencies, especially for organizations that need to adhere to strict security or
compliance requirements.

The `local-recipes-index` allows users to maintain a local folder with the same structure
as the `conan-center-index` GitHub repository, using it as a source for package recipes.
This method requires building package binaries from source, which must then be stored on a
remote Conan server for production use. 

<b>THIS IMAGE IS A PLACEHOLDER TO CHANGE FOR A BETTER ONE</b>
<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2024-04-12/general-flow-diagram.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Diagram of the general workflow"/>
</p>

In this post, we will explore how this feature facilitates the following:

- This feature makes it possible for contributors to share package recipes with the
  community for libraries like CUDA or other propietary libraries, which are distributed
  as precompiled closed-source binaries. This includes libraries that may not be suitable
  for ConanCenter due to various reasons such as licensing constraints or binary
  distribution policies. While direct repackaging of the binaries is not permitted, these
  recipes enable users to use the official installers provided by the library owners
  within the Conan ecosystem.

- It simplifies the adoption of best practices outlined in
  https://docs.conan.io/2/devops/conancenter/hosting_binaries.html for organizations
  requiring custom-built binaries or modified ConanCenter recipes to meet unique
  requirements. This approach grants users complete control over their third-party
  dependencies, ensuring they are both robust and fully customizable.

Next, we'll delve into practical examples to demonstrate these two use cases of the
`local-recipes-index` repository.

## Using a local-recipes-index repository with your own recipes

In this section, we will illustrate how to use the `local-recipes-index` feature for
scenarios where certain libraries or tools, due to licensing restrictions or proprietary
nature, are not suitable for ConanCenter.

For demonstration, let's create a `local-recipes-index` repository for a hypothetical
`hello` closed-source library using the `local_recipes_index` template for the `conan new`
command:

    $ mkdir repo && cd repo
    $ conan new local_recipes_index -d name=hello -d version=0.1 \
      -d url=https://github.com/conan-io/libhello/archive/refs/tags/0.0.1.zip \
      -d sha256=1dfb66cfd1e2fb7640c88cc4798fe25853a51b628ed9372ffc0ca285fe5be16b
    $ cd ..

The `conan new local_recipes_index` command creates a template that assumes CMake as the
build system alongside other heavy assumptions. In practice, it will require customizing
it, but for this demo, it works as-is. It will create a folder layout equal to the
`conan-center-index` GitHub repository:

    .
    └── repo
        └── recipes
            └── hello
                ├── all
                │   ├── conandata.yml
                │   ├── conanfile.py
                │   └── test_package
                │       ├── CMakeLists.txt
                │       ├── conanfile.py
                │       └── src
                │           └── example.cpp
                └── config.yml

After setting up the repository, we add it as a local remote to Conan:

    $ conan remote add mylocalrepo ./repo

Now you can list and install packages from this new repository:

    $ conan list "*" -r=mylocalrepo
    $ conan install --requires=hello/0.1 -r=mylocalrepo --build=missing

At this point, you could push this repository to your GitHub account and share it with the
community. The only thing they would have to do is clone the GitHub repository and add the
cloned folder as a local repository themselves.

## Building Binaries from a private `conan-center-index` fork

As outlined in [the Conan DevOps
Guide](https://docs.conan.io/2/devops/using_conancenter.html), there are many cases where
organizations need to operate independently of ConanCenter by building their own binaries.
Being decoupled from the public upstream ConanCenter server and building your own binaries
from a fork of ``conan-center-index`` as suggested in that documentation page can have
many advantages, including absolute control and possibility to customize recipes, no need
to use lockfiles, be completely robust against possible continuous changes and new
releases in upstream ConanCenter, etc.

The `local-recipes-index` repository allows you to easily building binaries
from a fork of the `conan-center-index`. It is important not to mix binaries from
ConanCenter with locally built ones but instead to build all dependencies directly from
the fork.

To begin, remove the upstream ConanCenter as it will not be used, everything will come from our own fork:

    $ conan remote remove conancenter

Then we will clone our fork (in this case, we are cloning directly the upstream for demo
purposes, but you would be cloning your fork instead):

    $ git clone https://github.com/conan-io/conan-center-index

Add this as our `mycenter` remote:

    # Add the mycenter remote pointing to the local folder
    $ conan remote add mycenter ./conan-center-index

And that’s all! Now you're set to list and use packages from your `conan-center-index` local folder:

    $ conan list "zlib/*" -r=mycenter
    mycenter
    zlib
        zlib/1.2.11
        zlib/1.2.12
        zlib/1.2.13
        zlib/1.3
        zlib/1.3.1

We can also install packages from this repo, for example we can do:

    $ conan install --requires=zlib/1.3
    ...
    ======== Computing dependency graph ========
    zlib/1.3: Not found in local cache, looking in remotes...
    zlib/1.3: Checking remote: mycenter
    zlib/1.3: Downloaded recipe revision 5c0f3a1a222eebb6bff34980bcd3e024
    Graph root
        cli
    Requirements
        zlib/1.3#5c0f3a1a222eebb6bff34980bcd3e024 - Downloaded (mycenter)

    ======== Computing necessary packages ========
    Requirements
        zlib/1.3#5c0f3a1a222eebb6bff34980bcd3e024:72c852c5f0ae27ca0b1741e5fd7c8b8be91a590a - Missing
    ERROR: Missing binary: zlib/1.3:72c852c5f0ae27ca0b1741e5fd7c8b8be91a590a

As we can see, Conan managed to get the recipe for ``zlib/1.3`` from ``mycenter``, but
then it failed because there is no binary. This is expected, **the repository only contains
the recipes, but not the binaries**. We can build the binary from source with
``--build=missing`` argument:

    $ conan install --requires=zlib/1.3 --build=missing
    ...
    zlib/1.3: package(): Packaged 2 '.h' files: zconf.h, zlib.h
    zlib/1.3: package(): Packaged 1 file: LICENSE
    zlib/1.3: package(): Packaged 1 '.a' file: libz.a
    zlib/1.3: Created package revision 0466b3475bcac5c2ce37bb5deda835c3
    zlib/1.3: Package '72c852c5f0ae27ca0b1741e5fd7c8b8be91a590a' created
    zlib/1.3: Full package reference: zlib/1.3#5c0f3a1a222eebb6bff34980bcd3e024:72c852c5f0ae27ca0b1741e5fd7c8b8be91a590a#0466b3475bcac5c2ce37bb5deda835c3
    zlib/1.3: Package folder /home/conan/.conan2/p/b/zlib1ed9fe13537a2/p
    WARN: deprecated: Usage of deprecated Conan 1.X features that will be removed in Conan 2.X:
    WARN: deprecated:     'cpp_info.names' used in: zlib/1.3

    ======== Finalizing install (deploy, generators) ========
    cli: Generating aggregated env files
    cli: Generated aggregated env files: ['conanbuild.sh', 'conanrun.sh']
    Install finished successfully

We can see now the binary package in our local cache:

    $ conan list zlib:*
    Local Cache
    zlib
        zlib/1.3
        revisions
            5c0f3a1a222eebb6bff34980bcd3e024 (2024-04-10 11:50:34 UTC)
            packages
                72c852c5f0ae27ca0b1741e5fd7c8b8be91a590a
                info
                    settings
                    arch: x86_64
                    build_type: Release
                    compiler: gcc
                    compiler.version: 9
                    os: Linux
                    options
                    fPIC: True
                    shared: False

Finally, upload the binary package to our server to make it available for our
organization, users and CI jobs:

    $ conan upload zlib* -r=myprivateserver -c

This way, consumers of the packages will not only enjoy the pre-compiled binaries and
avoid having to always re-build from source all dependencies, but that will also provide
stronger guarantees that the dependencies build and work correctly, that all dependencies
and transitive dependencies play well together, etc. Decoupling the binary creation
process from the binary consumption process is the way to achieve faster and more reliable
usage of dependencies.

Remember, in a production setting, the `conan upload` command should be executed by CI,
not developers, following the [Conan
guidelines](https://docs.conan.io/2/knowledge/guidelines.html). This approach ensures that
package consumers enjoy pre-compiled binaries and consistency across dependencies.

### Modifying the local-recipes-index repository files

One of the advantages of this approach is that all the changes that we do in the folder
are automatically available for the Conan client. For example, changes to the
`recipes/zlib/config.yml` file, are immediately recognized by the Conan client. If you
edit that file and remove all versions but the latest and then we `list` the recipes:

    $ conan list "zlib/*" -r=mycenter
    mycenter
    zlib
        zlib/1.3.1

When some of the recipes change, then note that the current Conan home already contains a
cached copy of the package, so it will not update it unless we explicitly use the
``--update``, as any other Conan remote.

So if we do a change in the ``zlib`` recipe in ``recipes/zlib/all/conanfile.py`` and
repeat:

    $ conan install --requires=zlib/1.3.1 -r=mycenter --update --build=missing

We will immediately have the new package binary locally built from source from the new
modified recipe in our Conan home.

### Using local-recipes-index repositories in production

When implementing this feature, consider the following:

- It's intended for third-party packages, meaning recipes should manage packages whose
  sources are elsewhere.

- `local-recipes-index` repositories are intended as local directories, not git remote
  repositories, ensuring reproducibility by building packages from specific repository
  states.

- While it enables source-level management, a package server is necessary for production
  to host the binaries.





