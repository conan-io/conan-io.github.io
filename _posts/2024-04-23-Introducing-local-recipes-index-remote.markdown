---
layout: post
comments: false
title: "Introducing the Local-Recipes-Index: A New Repository Type in Conan"
meta_title: "Understanding Conan's Local-Recipes-Index to improve package management for C/C++ - Conan Blog"
description: "Explore the capabilities of Conan's local-recipes-index feature and how it enhances dependency management for C and C++ libraries."
---

ConanCenter, the central open-source repository for C and C++ libraries, is a success
story, containing a vast collection of C and C++ open-source packages. It processes hundreds
of thousands of download requests daily, building its packages [from a central GitHub
repository](https://github.com/conan-io/conan-center-index), which is organized in a
specific folder layout and received nearly 6,000 pull requests from contributors in
2023 alone.

However, ConanCenter does not fit all use cases. For instance, it cannot include
closed-source libraries or tools that might still be beneficial to the community.
Additionally, some organizations, particularly large enterprises, prefer not to use
binaries downloaded from the internet. Instead, they build their own binaries in-house
using the `conan-center-index` recipes. These organizations often need to customize these
recipes to meet unique requirements that are not applicable to the broader community,
making such contributions unsuitable for the upstream repository. The Conan documentation
[acknowledges this
practice](https://docs.conan.io/2/devops/conancenter/hosting_binaries.html), recommending
working from a fork of `conan-center-index` for such needs.

For all those reasons in version 2.2.0, Conan introduced a new repository type called
`local-recipes-index`, designed to offer more flexibility by allowing a Conan remote to
point to a local copy of Conan recipes with a specific layout.

The `local-recipes-index` allows users to maintain a local folder with the same structure
as the `conan-center-index` GitHub repository, using it as a source for package recipes.
This new type of repository is recipes-only, necessitating the construction of package
binaries from source on each machine where the package is used. For sharing binaries
across teams, we continue to recommend [using a Conan remote server like
Artifactory](https://docs.conan.io/2/tutorial/conan_repositories/setting_up_conan_remotes/artifactory/artifactory_ce_cpp.html)
for production purposes.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2024-04-23/general-flow-diagram.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Diagram of the general workflow"/>
</p>

In this post, we will explore how this feature facilitates the following:

- This feature enables contributors to share package recipes with the community for
  libraries that might not be suitable for ConanCenter due to various reasons, such as
  licensing constraints or binary distribution policies. An example of this could be CUDA
  or other proprietary libraries, which are distributed as precompiled closed-source
  binaries.

- It simplifies the adoption of best practices outlined [in the Conan
  documentation](https://docs.conan.io/2/devops/conancenter/hosting_binaries.html) for
  organizations requiring custom-built binaries or modified ConanCenter recipes to meet
  unique requirements. This approach grants users complete control over their third-party
  dependencies, ensuring they are both robust and fully customizable.

Next, we'll delve into practical examples to demonstrate these two use cases of the
`local-recipes-index` repository.

## Using a local-recipes-index repository with your own recipes

In this section, we will illustrate how to use the `local-recipes-index` feature for
scenarios where certain libraries or tools, due to licensing restrictions or proprietary
nature, are not suitable for ConanCenter.

For demonstration purposes, let's create a `local-recipes-index` repository for a hypothetical
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

    $ conan remote add mylocalrepo ./repo --allowed-packages="hello/*"

Please pay special attention to the `--allowed-packages` argument. This argument ensures
that all packages other than `hello` are discarded by Conan. This can be used to minimize
the surface area for a potential supply chain attack.

Now you can list and install packages from this new repository:

    $ conan list "*" -r=mylocalrepo
    $ conan install --requires=hello/0.1 -r=mylocalrepo --build=missing

At this point, you could push this repository to your GitHub account and share it with the
community. Please be aware that, as we commented earlier, this feature is specifically
tailored for scenarios where certain libraries are not suitable for ConanCenter. Remember,
a "local-recipes-index" repository has limitations: it is not fully reproducible as it
models only versions and not revisions, and it does not provide binaries. Therefore,
outside of these cases, it is advised to use a remote package server such as Artifactory.

Now, users simply need to clone the GitHub repository and add the cloned folder as a local
repository themselves.

## Building Binaries from a private `conan-center-index` fork

As outlined in [the Conan DevOps
Guide](https://docs.conan.io/2/devops/using_conancenter.html), there are many cases where
organizations need to operate independently of ConanCenter by building their own binaries.
Being decoupled from the public upstream ConanCenter server and building your own binaries
from a fork of ``conan-center-index`` as suggested in the linked documentation page can have
many advantages, including absolute control and possibility to customize recipes, giving
us the ability for the repository to act as a snapshot of versions, be completely robust
against possible continuous changes and new releases in upstream ConanCenter, etc.

The `local-recipes-index` repository allows you to easily build binaries from a fork of
`conan-center-index`, and then hosting them on a Conan remote repository like Artifactory.
The main difference with the process explained [in the Conan DevOps
guide](https://docs.conan.io/2/devops/conancenter/hosting_binaries.html) is the ability
to immediately test multiple local changes without the need to export each time a recipe
is modified.

Note that in this case, mixing binaries from ConanCenter with locally built binaries is
not recommended for several reasons:

- Binary compatibility: There may be small differences in setup between the ConanCenter CI
and the user's CI. Maintaining a consistent setup for all binaries can mitigate some issues.

- Full control over builds: Building all binaries yourself ensures you have complete control
over the compilation environment and dependency versions.

Instead, it's recommended to build all your direct and transitive dependencies from the fork.
To begin, remove the upstream ConanCenter as it will not be used, everything will come
from our own fork:

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

Finally, upload the binary package to our Artifactory repository to make it available for
our organization, users and CI jobs:

    $ conan remote add myartifactoryrepo <artifactory_url>
    $ conan upload zlib* -r=myartifactoryrepo -c

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

One of the advantages of this approach is that all the changes that we do in every single
recipe are automatically available for the Conan client. For example, changes to the
`recipes/zlib/config.yml` file are immediately recognized by the Conan client. If you
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

### Using local-recipes-index Repositories in Production

Several important points should be considered when using this new feature:

- It is designed for **third-party packages**, where recipes in one repository are creating
  packages with sources located elsewhere. To package your own code, the standard practice
  of adding `conanfile.py` recipes along with the source code and using the standard
  `conan create` flow is recommended.

- The `local-recipes-index` repositories point to **local folders in the filesystem**.
  While users may choose to sync that folder with a git repository or other version
  control mechanisms, Conan is agnostic to this, as it is only aware of the folder in the
  filesystem that points to the (current) state of the repository. Users may choose to run
  git commands directly to switch branches/commit/tags and Conan will automatically
  recognise the changes

- This approach operates at the source level and does not generate package binaries. For
  deployment for development and production environments, the use of a remote package
  server such as Artifactory is crucial. It's important to note that this feature is not a
  replacement for Conan's remote package servers, which play a vital role in hosting
  packages for regular use.

- Also, note that a server remote can retain a history of changes storing multiple recipe
  revisions. In contrast, a `local-recipes-index` remote can only represent a single
  snapshot at any given time. 

Furthermore, this feature does not support placing server URLs directly in recipes; remote
repositories must be explicitly added with `conan remote add`. Decoupling abstract package
requirements, such as "zlib/1.3.1", from their specific origins is crucial to resolving
dependencies correctly and leveraging Conan's graph capabilities, including version
conflict detection and resolution, version-ranges resolution, [opting into
pre-releases](https://docs.conan.io/2/devops/versioning/resolve_prereleases.html),
[platform_requires](https://docs.conan.io/2/reference/config_files/profiles.html#platform-requires),
[replace_requires](https://docs.conan.io/2/reference/config_files/profiles.html#replace-requires),
etc. This separation also facilitates the implementation of modern DevOps practices, such
as package immutability, full relocatability and package promotions.

## Conclusions

The `local-recipes-index` repository type introduces a new tool that enables workflows
previously not possible with Conan 1.X:

- It allows the easy creation of packages from forks of the `conan-center-index` GitHub
  repository. Many enterprises require this due to policies necessitating private
  customizations in recipes that are unsuitable for merging into the upstream repository.

- It provides a solution for packaging closed-source libraries and tools within the C/C++
  ecosystem that cannot be included in ConanCenter, enabling their recipes to be shared
  and conveniently used within the Conan community.
