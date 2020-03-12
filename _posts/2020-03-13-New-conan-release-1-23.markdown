---
layout: post 
comments: false 
title: "Conan 1.23: Parallel installation of binaries, CONAN_V2_MODE environment variable to enable
Conan v2 behavior and more"
---

March brings us a new Conan release but sadly it also brought us the notice of having to postpone
ConanDays due to growing concerns about the Coronavirus. This was a hard decision to make for the
safety and well being of all of you, but we hope it will make possible for an even greater meeting of
the Conan community soon. But let's focus on the good news and see what comes with Conan 1.23.

## Parallel binary downloads

As you know, we have been doing a great effort to speed-up several Conan commands to make the CI
faster. We already implemented some cool features in Conan 1.21 and 1.22:

 - [Parallel
   uploads](https://docs.conan.io/en/latest/reference/commands/creator/upload.html#conan-upload):
   since Conan 1.21, it is possible to upload Conan packages to remotes faster thanks to the use of
   multiple threads. To activate this feature, add the `--parallel` argument to the `conan upload`
   command. Parallel uploads can achieve an **increase in speed for around 400%** depending on the
   situation. 

 - [Download
   cache](https://docs.conan.io/en/latest/configuration/download_cache.html#download-cache): in Conan
   1.22 we introduced a download cache that can be concurrently used by several Conan instances using
   different `CONAN_USER_HOME` folders. This cache can be shared between different simultaneous CI
   jobs, so if the files were previously downloaded, they will be reused from the cache without the
   need to download them again. Use this feature setting `storage.download_cache="path/to/the/cache"`
   in *conan.conf*.

Now, as the icing on the cake in Conan 1.23, we are providing the possibility to download
binaries in parallel. To use it, set `general.parallel_download` in `conan_conf`. This parameter
has to be set to the number of threads you want to use for downloading and will speed-up. This
setting will be used when dependencies are installed (`conan install`, `conan create`) and when
multiple binaries for the same package are retrieved via `conan download` command.

Let's see an example of how much time we could save using this feature if we need, for example, to
download a package for lots of configurations. We will download zlib/1.2.11 for all the 82 different
configurations available in [Conan-Center Index](https://github.com/conan-io/conan-center-index).
Doing this would typically take **around 3 minutes** for a conventional Internet connection.

We will set the number of download threads to 8 but feel free to play with this setting depending on
your machine.

```
➜ conan config set general.parallel_download=8
➜ time conan download zlib/1.2.11
Downloading conanmanifest.txt completed [0.29k]
Downloading conanfile.py completed [7.59k]
Downloading conan_export.tgz completed [0.23k]
Decompressing conan_export.tgz completed [0.00k]
Downloading conan_sources.tgz completed [6.91k]
Decompressing conan_sources.tgz completed [0.00k]
...
Downloading conaninfo.txt completed [0.46k]
Downloading conan_package.tgz completed [88.12k]
Decompressing conan_package.tgz completed [0.00k]
zlib/1.2.11: Package installed c83d8b197f1a331ca3b55943846d427ad4f7f8e1
conan download zlib/1.2.11@ -r conan-center  4.23s user 0.96s system 16% cpu
30.536 total
```

As you can see it just took around 30 seconds to download all the binaries what means an
**improvement of around a 600% in time**.

If you try this feature you may experience some message overlaps in the command line output. We have
prioritized the feature over a clean output but will solve these output problems shortly.

Use all of these features in combination or separate and please tell us if they are making your CI's
faster.

## CONAN_V2_MODE to start testing Conan v2 deprecated features

Although we still have plenty of time and work ahead before Conan 2.0 we would like to start testing
the deprecation of features for Conan 2.0. We have introduced the `CONAN_V2_MODE` [environment
variable](https://docs.conan.io/en/latest/reference/conan_v2_mode.html#conan-v2-mode) that activates
some behaviors and defaults that are intended to be in the next major release.

Some of the most important default behaviours for Conan 2.0 will be:

* Revisions are enabled by default (adds `revisions_enabled=1` to *conan.conf*).
* No hooks activated by default.
* SCM data will be stored into *conandata.yml*.
* GCC >= 5 autodetected profile will use `libstdc++11`.

Our objective is to minimize the impact on existing recipes when Conan 2.0 is released and start
gathering feedback about the new configuration and behavior. **Be advised that this mode is only for
experimenting, please do not activate this mode in a production environment!** 

## Other cool things

 * `clean-modified` subcommand for `graph` command. When a package of a dependency graph is going
   to be re-built, using a given lockfile, it is desired to finish the build knowing which packages
   of the graph have been rebuilt as a result of the last command. This command will clean
   all the previously existing "modified" flags before such build, so after the build the "modified"
   are only those that have been built now.
   https://docs.conan.io/en/latest/reference/commands/misc/graph.html#conan-graph-clean-modified
 * `full_transitive_package_id` can now be activated in *conan.conf* to include transitive
   dependencies even when the direct dependencies remove them, for example when depending on a
   header-only library that depends on a static library. Read more about this
   [here](https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html#enabling-full-transitivity-in-package-id-modes).

<br>

-----------

<br>

Have a look at the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html).

Please, report any bug or share your feedback opening a new issue in our [issue
tracker](https://github.com/conan-io/conan/issues) and don't forget to
[update](https://conan.io/downloads.html).
