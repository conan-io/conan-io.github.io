---
layout: post
comments: false
title: "Conan 1.5: Binaries from different remotes, build requirements in dependency graph & SCM improvements"
---

Conan 1.5 was [released last week](https://docs.conan.io/en/latest/changelog.html#id2) with some progress in features announced for 1.4.
This release is not so full of features but there are still some great new things to share!

## Binaries from different remotes

Introduced some releases ago, ``conan search <pkg_pattern> --remote all`` is a very handy command when it comes to perform a search of a
reference in all remotes. Thanks to the contributors now you can also search for binaries in all remotes in the same way:

``$ conan search <pkg-ref> -r=all``

As this is quite useful to know in which remote are exactly the binaries you need, this feature would not be completed if you were not able
to mix binaries from different remotes. So this is exactly what we did:

```
$ conan install libwebp/1.0.0@bincrafters/stable

libwebp/1.0.0@bincrafters/stable: Not found in local cache, looking in remotes...
libwebp/1.0.0@bincrafters/stable: Trying with 'conan-center'...
...
libwebp/1.0.0@bincrafters/stable: Installing package

Requirements
    libwebp/1.0.0@bincrafters/stable from 'conan-center' - Downloaded
Packages
    libwebp/1.0.0@bincrafters/stable:36cedbf3473b284f710724d0897d2340d94bb47e - Download

libwebp/1.0.0@bincrafters/stable: Retrieving package 36cedbf3473b284f710724d0897d2340d94bb47e from remote 'conan-center'
...
libwebp/1.0.0@bincrafters/stable: Package installed 36cedbf3473b284f710724d0897d2340d94bb47e


$ conan install libwebp/1.0.0@bincrafters/stable -s arch=x86 -r upload_repo

libwebp/1.0.0@bincrafters/stable: Installing package
Requirements
    libwebp/1.0.0@bincrafters/stable from 'conan-center' - Cache
Packages
    libwebp/1.0.0@bincrafters/stable:dc94cc7e740b35dfaacd21a10cbbcb541a20125e - Download
Cross-build from 'Windows:x86_64' to 'Windows:x86'
libwebp/1.0.0@bincrafters/stable: Retrieving package dc94cc7e740b35dfaacd21a10cbbcb541a20125e from remote 'upload_repo'
libwebp/1.0.0@bincrafters/stable: Package installed dc94cc7e740b35dfaacd21a10cbbcb541a20125e
```

## Build requirements in dependency graph

After a huge refactor of the dependency graph now you can see ``build_requires`` represented in it. This feature is visible in
``conan info --graph`` (represented in colors).

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2018-07-06/graph.png"  align="center"
    width="600"  alt="Conan graph with build requires"/>
</p>

With these changes, ``conan install`` and ``conan info`` commands now show extended information of the both recipe's and binaries' status in
the output:

```
...
libwebp/1.0.0@bincrafters/stable: Installing package
Requirements
    libwebp/1.0.0@bincrafters/stable from 'conan-center' - Downloaded
Packages
    libwebp/1.0.0@bincrafters/stable:36cedbf3473b284f710724d0897d2340d94bb47e - Download
```

Dependency declaration order in recipes is respected too (as long as it doesn’t break the dependency graph order).

## SCM improvements

After a lot of new issues with feedback for the new SCM feature, we worked on some improvements to make it better. There is now a new ``submodule`` argument to [recursively clone submodules](https://docs.conan.io/en/latest/reference/conanfile/attributes.html?highlight=scm#scm).

Now you can also use ``exports`` and ``exports_sources`` together with ``scm`` attribute. ``conan create`` will copy exports and export sources first, then it will apply SCM and finally the ``source()`` method (in case you want to use the latest for patching for example).

This will also manage symlinks and, while developing locally, the *gitignored* files won't be copied from the local repository.

Please keep the feedback coming!

## Other highlights

- We released and received a lot of feedback regarding [Workspaces](https://docs.conan.io/en/latest/developing_packages/workspaces.html).
  Stay tuned for improvements!

- ``conan user`` command is now able to show authenticated users and includes a ``--json`` argument for JSON output.

- ``SystemPackageTools`` now also supports Manjaro.

- There is a new Macos version sub-setting in the default *settings.yml* file to account for the "min OSX version" configuration.