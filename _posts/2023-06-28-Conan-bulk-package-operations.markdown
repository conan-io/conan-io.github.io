---
layout: post
comments: false
title: "Conan 2.0 launches bulk upload, download and remove operations with 'packages lists'"
description: "Learn how Conan 2.0 packages lists can be used to do bulk upload, download and remove operations, very useful in Continuous Integration flows"
---


In Conan 1.X, uploading the exact set of packages that were built from source in the last ``conan install --build=missing`` command was not a straightforward task.
It was necessary to have some script that would get the output of the command, and then iterate the resul, executing ``conan upload <ref>`` one reference at a time.

We are happy to launch in Conan 2.0.7 the "packages lists" feature, that makes this highly requested functionality built-in.


## Introduction to packages-lists files

A "packages list" is a json file that contains a list of Conan artifacts, both recipes and package binaries.
This file can be generated as the ``--format=json`` of several commands. For example a ``conan list``
command like the following:


```bash
# The output file name is user defined
$ conan list "*:*" --format=json > pkglist.json
```

will generate a ``pkglists.json`` file that looks like this (simplified, not complete):

```json
{
    "Local Cache": {
        "zlib/1.2.12": {
            "revisions": {
                "b1fd071d8a2234a488b3ff74a3526f81": {
                    "timestamp": 1667396813.987,
                    "packages": {
                        "ae9eaf478e918e6470fe64a4d8d4d9552b0b3606": {
                            "revisions": {
                                "19808a47de859c2408ffcf8e5df1fdaf": {}
                            },
                            "info": {
                                "settings": {
                                    "arch": "x86_64",
                                    "os": "Windows"
                                }
                            }
                        }
                    }
                }
            }
        },
        "zlib/1.2.13": {
        }
    }
}
```

The first level in the ``pkglist.json`` is the "location", it can be a remote or the local cache. In this case, we were listing
packages in the cache, so the origin is "Local Cache".

The ``conan remove``, ``conan upload`` and ``conan download`` can also generate "packages lists" with the ``--format=json``
formatter. For example ``conan upload ... -r=myremote --format=json`` will generate a packages lists for the "myremote" location
as the first level in the resulting json file.

Furthermore, it is also possible to generate a packages list from the result of a ``conan create``, ``conan install`` and ``conan graph info``
commands, as we will see in the examples below.

One of the advantages of packages lists files is that they can be used as inputs to perform bulk operations in several commands:

```bash
$ conan upload --list=pkgs_to_upload.json -r=myremote
$ conan download --list=download.json -r=myremote
$ conan remove --list=pkglists.json  # From the cache or -r=remote
```


Let's see some more complete and useful examples:


## Downloading from one remote and uploading to a different remote

This is something that can be useful to populate or to **promote** packages in an air-gapped environment, where there are 2 servers.
One server is the public one containing some packages that we want to introduce in the isolated environment (with a due diligence). This is fairly common in enterprise environments.

For example, let's say we want to download some packages from ConanCenter, disconnect from the internet, check the packages locally, 
and finally upload them to our own private internal server. (Note: This is an example, for ConanCenter packages a better approach when 
security, reproducibility and robustness are very important would be building the packages from source, from a conan-center-index fork)


<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-06-28/promote_air_gap.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Conan 2.0 graphic demonstrating Promoting packages in air-gapped environments or where network access is limited/forbidden with download upload and upload commands"/>
</p>


With the ``conan download`` command, we can download some packages, for example, all the Windows binaries for ``zlib/1.2.12`` 
(by default only the latest revisions), and generate a ``downloaded.json`` packages list file:

```bash
$ conan download zlib/1.2.12:* -p "os=Windows" -r=conancenter --format=json > downloaded.json
```

The resulting ``downloaded.json`` file will look like:


```json
{
   "Local Cache": {
        "zlib/1.2.12": {
            "revisions": {
                "b1fd071d8a2234a488b3ff74a3526f81": {
                    "timestamp": 1667396813.987,
                    "packages": {
                        // full list of package binaries (Windows)
                    }
                }
            }
        }
    }
}
```

That means that we can now upload this same set of recipes and binaries to a different remote:

```bash
$ conan upload --list=downloaded.json -r=myremote -c
# Upload the artifacts listed in the "Local Cache" location to my own remote
```

One of the important points is that this works irrespective of the cache contents. It doesn't matter if the local cache
contains other artifacts from other commands. The packages uploaded to the ``myremote`` repository will be only the ones listed in the ``downloaded.json``.

Note that this would be a **slow** mechanism to run promotions between different server repositories.
Some servers provide ways to directly copy packages from one repository to another without using a client, 
that are orders of magnitude faster because of file deduplication, so that would be the recommended approach if the 2
repositories can directly talk to each other.



## Building from source and uploading packages

One of the most interesting applications of "packages lists" is the one when some packages are being built in the local cache, with a 
``conan create`` or ``conan install --build=xxx`` command. Typically, we would like to upload the locally built
packages to the server, so they don't have to be re-built again by others. But we might want to upload only
the built binaries, but not all others transitive dependencies, or other packages that we had previously in
our local cache.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-06-28/build_and_upload.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Build from source and upload newly built packages with Conan 2.0 using conan create or conan install build missing and the new graph binary and package list JSON formats supported with 2.0.7"/>
</p>

It is possible to use the graph from any of the commands ``conan install``, ``conan create`` and ``conan graph info`` to compute a package list which can then be used with upload
commands. Then, that package list can be used for the upload. 

For example we can build from source the latest version of ``spdlog`` and its transitive dependencies (this includes ``fmt``) with:


```bash
$ conan install --requires="spdlog/[*]" --build="*" --format=json > build.json
```

This will create a json representation of the graph, with information of what packages have been built (that is, they contain ``"binary": "Build"``),
the ``build.json`` will look like (simplified):

```json
{
  "graph": {
    "nodes": {
        "0": {
            "ref": "conanfile",
            "recipe": "Cli",
            "dependencies": { "1": {"ref": "spdlog/1.11.0"} }
        },
        "1": {
            "ref": "mypkg/0.1#f57cc9a1824f47af2f52df0dbdd440f6",
            "binary": "Build",
            "dependencies": { "2": {"ref": "fmt/9.1.0"}}
        },
        "2": {
            "ref": "fmt/9.1.0#44302d39c5a4bf7de8a39adc50bb4568",
            "binary": "Build"
        }
    }
  }
}
```

We can compute a package list from this file, and then upload those artifacts to the server with:

```bash
$ conan list --graph=build.json --graph-binaries=build --format=json > pkglist.json
```
The resulting ``pkglist.json`` will contain both ``spdlog`` and ``fmt`` recipes and built binaries, and
we can now use this list to upload these exact packages (and not other existing ones in the cache, or other things that 
were not built from sources in my ``install`` command) to my own server:

```bash
$ conan upload --list=pkglist.json -r=myremote -c
```


## Conclusions

One of the advantages of the new Conan 2.0 architecture is that it is enabling the quick development of demanded features.
This new "packages lists" feature is a new powerful addition to the Conan CLI, allowing to do bulk operations over sets of packages that
previously required user custom automation (script files or Continuous Integration jobs), and now are conveniently provided as built-in. 

Feedback is very welcome, please create a [Github issue for any question, comment or suggestion](https://github.com/conan-io/conan/issues) about it.
