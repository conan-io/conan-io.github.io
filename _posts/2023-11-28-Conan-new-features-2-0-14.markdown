---
layout: post
comments: false
title: "New Conan Features for CI and Production Environments"
meta_title: "New Conan Features for CI and Production Environments"
description: "Discover the latest features in Conan designed to enhance CI and production workflows: Cache Save/Restore and LRU Cleanup."
---

As Conan 2 continues to evolve, we're excited to announce the recent release of [Conan
2.0.14](https://github.com/conan-io/conan/releases/tag/2.0.14). This update introduces new
features aimed at enhancing productivity and efficiency in production environments. In
this post, we'll focus on two recent additions: Cache Save/Restore and LRU (Least Recently
Used) Cleanup.

## Save and Restore Packages from/to the Cache

This feature is designed for temporary package movement, offering an efficient way to
transfer packages between different Conan caches. It is ideal for scenarios like:

- **CI Pipelines**: It facilitates the sharing of intermediate build stages or
  dependencies across different jobs. Particularly beneficial for parallel jobs, as the
  Conan cache is not concurrent.

- **Air-Gapped Environments**: Useful where direct internet access is restricted, and
  packages must be transferred via the client side.

It's crucial to note that saving and restoring packages is a short-term mechanism and not
intended for long-term storage or as a backup strategy. The storage format and
serialization, although effective within the same Conan version, may not be stable or
compatible with future Conan versions. For long-term backup of Conan packages, server-side
backup strategies are recommended.

#### How It Works

For example, imagine we are building our application in CI for three different platforms.
The main job in our CI would trigger the three different builds on different agents. 

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2023-11-28/ci-flow-cache-save-restore.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Conan cache save/restore"/>
</p>

After each build, you could save a selection of packages from the cache in a `tgz` for
each platform using the conan `cache save` command. As an argument for the command, you
can pass a reference pattern (like in the [conan
list](https://docs.conan.io/2/reference/commands/list.html) command) or a [package-list
json
file](https://docs.conan.io/2/examples/commands/pkglists.html#examples-commands-pkglists).
Let's save the latest revision of all packages in the Conan cache:


```bash
# save the last revision of all packages in the cache
$ conan cache save "*/*:*" --file=conan_cache_save_linux.tgz
Saving app/2.71: p/autoc5f0e65aa481c3
Saving app/2.71:da39a3ee5e6b4b0d3255bfef95601890afd80709: p/autocf3e6879dde7f6/p
Saving bzip2/1.0.8: p/bzip2b261b4dea28b4
Saving bzip2/1.0.8:e3dc948df7773c2c60edf3a72557250108721b20: p/bzip23cfe2c0da64ba/p
Saving cmake/3.27.7: p/cmake9a3eb5e13dc53
Saving cpp-httplib/0.11.3: p/cpp-hd3892a337ccc3
Saving eigen/3.4.0: p/eigenecaf3dc594b0c
...
# creates conan_cache_save_linux.tgz
```

The saved `.tgz` file encompasses recipe folders, package metadata, and other essential
contents, excluding temporary folders like "build" or "download". You save the packages
for each parallel job and at the end of each job, stash them to later recover in the main
job where you can restore all the saved packages in the Conan cache by using `conan cache
restore`:

```bash
$ conan cache restore conan_cache_save.tgz 
Restore: app/2.71 in p/autoc5f0e65aa481c3
Restore: app/2.71:da39a3ee5e6b4b0d3255bfef95601890afd80709 in p/autocf3e6879dde7f6/p
Restore: bzip2/1.0.8 in p/bzip2b261b4dea28b4
Restore: bzip2/1.0.8:e3dc948df7773c2c60edf3a72557250108721b20 in p/bzip23cfe2c0da64ba/p
Restore: cmake/3.27.7 in p/cmake9a3eb5e13dc53
Restore: cpp-httplib/0.11.3 in p/cpp-hd3892a337ccc3
Restore: eigen/3.4.0 in p/eigenecaf3dc594b0c
...
```

For more details on how to use this feature, please refer to the [Conan
documentation](https://docs.conan.io/2/devops/save_restore.html).

## LRU: Removing Unused Packages from the Cache

Conan now supports an LRU (Least Recently Used) policy to efficiently manage cache size.
This feature is important for maintaining an optimized package cache as the Conan cache
does not implement any automatic expiration policy, so its size will always increase
unless packages are removed or the cache is cleared from time to time.

#### How It Works

The use of the LRU feature is through the ``--lru`` argument of the `conan remove` and
`conan list` commands. You can use it to remove old package binaries or to remove recipes
along with their associated binaries. The LRU time follows the rules of the `remove`
command. If we are removing recipes with a "*" pattern, only the LRU times for recipes
will be checked. If a recipe has been recently used, it will keep all the binaries, and if
the recipe has not been recently used, it will remove itself and all its binaries.

For example, if we want to remove all binaries (but not recipes) not used in the last 2
months, we would do:

```bash
$ conan remove "*:*" --lru=2M -c
```

To also remove all recipes (and their associated binaries):

```bash
$ conan remove "*" --lru=2M -c
```

You could also use the `conan list` command to generate a list of the least recently used
packages with the LRU argument, and then pass the generated package-list to the `conan
remove` command. An equivalent approach for the removal of all recipes and packages not
used in the last two months would be:

```bash
# List all unused (last 2 months) recipe revisions
$ conan list "*#*" --lru=2M --format=json > old.json
# Remove those recipe revisions (and their binaries)
$ conan remove --list=old.json -c
```

## Conclusion

The addition of the cache save/restore and LRU cleanup features in Conan significantly
enhances efficiency, particularly in CI environments, and will assist in maintaining
optimal performance in production.

For more detailed information and examples, visit our [DevOps
Guide](https://docs.conan.io/2/devops.html) and the [Other Features
Tutorial](https://docs.conan.io/2/tutorial/other_features.html).

We are keen to hear your thoughts and suggestions about these new features. Please don't
hesitate to share your experiences and ideas on [GitHub
issues](https://github.com/conan-io/conan/issues).
