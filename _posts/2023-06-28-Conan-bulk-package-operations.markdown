---
layout: post
comments: false
title: "Conan 2.0 launches bulk upload, download and remove operations with 'packages lists'"
description: "Learn how Conan 2.0 packages lists can be used to do bulk upload, download and remove operations, very useful in Continuous Integration flows"
---


In Conan 1.X, uploading the exact set of packages that were built from source in the last ``conan install --build=missing`` command was not a straightforward task.
It was necessary to have some script that would get the output of the command, and then execute ``conan upload <ref>``, one reference at a time.

We are happy to launch the "package lists" feature, that makes this highly requested functionality built-in. 👏 

Conan 2.0.7 introduces a new json file format that is able to list a set of Conan recipes and packages, the "package list". This file can be used to perform bulk remove, download and upload operations.

Let's start with a simple use case to define the concepts:



## Listing and downloading packages

We can do any ``conan list``, for example, to list all ``zlib`` versions above ``1.2.11``, the latest recipe revision,
all Windows binaries for that latest recipe revision, and finally the latest package revision for every binary.
Note that if we want to actually download something later, it is necessary to specify the ``latest`` package revision,
otherwise only the recipes will be downloaded.

```bash
$ conan list "zlib/[>1.2.11]#latest:*#latest" -p os=Windows --format=json -r=conancenter > pkglist.json
```

The output of the command is sent in ``json`` format to the file ``pkglist.json`` that looks like (simplified ``pkglist.json`` file):


```json
"conancenter": {
    "zlib/1.2.12": {
        "revisions": {
            "b1fd071d8a2234a488b3ff74a3526f81": {
                "timestamp": 1667396813.987,
                "packages": {
                    "ae9eaf478e918e6470fe64a4d8d4d9552b0b3606": {
                        "revisions": {
                            "19808a47de859c2408ffcf8e5df1fdaf": {
                            }
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
        },
    "zlib/1.2.13": {
    }
  }
}
```

The first level in the ``pkglist.json`` is the "origin" remote or "Local Cache" if the list happens in the cache. 
In this case, as we listed the packages in ``conancenter`` remote, that will be the origin.


We can now do a download of these recipes and binaries with a single ``conan download`` invocation:

```bash
$ conan download --list=pkglist.json -r=conancenter
# Download the recipes and binaries in pkglist.json
# And displays a report of the downloaded things
```

Of course this was a relatively trivial example, but let's move to a more useful one:


Downloading from one remote and uploading to a different remote
---------------------------------------------------------------

This is something that can be useful to populate or to **promote** packages in an air-gapped environment, where there are 2 servers.
One server is the public one containing some packages that we want to introduce in the isolated environment (with a due diligence).
For example we want to download some packages from ConanCenter, disconnect from the internet, check the packages locally, 
and finally upload them to our own private internal server. (Note: This is an example, for ConanCenter packages a better approach when 
security, reproducibility and robustness are very important would be building the packages from source, from a conan-center-index fork)


<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-06-28/promote_air_gap.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Promote packages in air-gapped environment with download+upload"/>
</p>


With the ``conan download`` command, we can generate a new package list containing the packages downloaded to the local cache:

```bash
$ conan download --list=pkglist.json -r=conancenter --format=json > downloaded.json
# Download the recipes and binaries in pkglist.json
# And stores the result in "downloaded.json"
```
It really doesn't matter if the input to ``conan download`` is already a list or a pattern. The resulting ``downloaded.json`` 
will be almost the same as the ``pkglist.json`` file, but in this case, the "origin" of those packages is the ``"Local Cache"`` 
(as the downloaded packages will be in the cache):


```json
{
   "Local Cache": {
        "zlib/1.2.12": {
            "revisions": {
               // Should there not be something here is we did the download?
            }
        }
    }
 }
```

That means that we can now upload this same set of recipes and binaries to a different remote:

```bash
$ conan upload --list=downloaded.json -r=myremote -c
# Upload those artifacts to the same remote
```

One of the important points is that this works irrespective of the cache contents. It doesn't matter if the local cache
contains other artifacts from other commands. The packages uploaded to the server will be only the ones listed in the ``downloaded.json``.

Note that this would be a **slow** mechanism to run promotions between different server repositories. Servers like
Artifactory provide ways to directly copy packages from one repository to another without using a client, 
that are orders of magnitude faster because of file deduplication, so that would be the recommended approach if the 2
repositories can directly talk to each other.




## Building from source and uploading packages

One of the most interesting flows is the one when some packages are being built in the local cache, with a 
``conan create`` or ``conan install --build=xxx`` command. Typically, we would like to upload the locally built
packages to the server, so they don't have to be re-built again by others. But we might want to upload only
the built binaries, but not all others transitive dependencies, or other packages that we had previously in
our local cache.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-06-28/build_and_upload.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Build from source and upload newly built packages with Conan 2.0 using conan create or conan install build missing and the new graph binary and package list JSON formats supported with 2.0.7"/>
</p>

It is possible to compute a package list from the output of a ``conan install``, ``conan create`` and ``conan graph info``
commands. Then, that package list can be used for the upload. Step by step:

First let's say that we have our own package ``mypkg/0.1`` and we create it:

```bash
$ conan new cmake_lib -d name=mypkg -d version=0.1
$ conan create . --format=json > create.json
```

This will create a json representation of the graph, with information of what packages have been built (that is, they contain ``"binary": "Build"``),
the ``create.json`` will look like (simplfied):

```json
    {
    "graph": {
        "nodes": {
            "0": {
                "ref": "conanfile",
                "id": "0",
                "recipe": "Cli",
                "context": "host",
                "test": false
            },
            "1": {
                "ref": "mypkg/0.1#f57cc9a1824f47af2f52df0dbdd440f6",
                "id": "1",
                "recipe": "Cache",
                "package_id": "2401fa1d188d289bb25c37cfa3317e13e377a351",
                "prev": "75f44d989175c05bc4be2399edc63091",
                "build_id": null,
                "binary": "Build"
            }
        }
      }
    }
```

We can compute a package list from this file, and then upload those artifacts to the server with:

```bash
$ conan list --graph=create.json --graph-binaries=build --format=json > pkglist.json
# Create a pkglist.json with the known list of recipes and binaries built from sources
$ conan upload --list=pkglist.json -r=myremote -c
```


## Conclusions

The better Conan 2.0 architecture and design have allowed to implement "packages lists". This feature is a new powerful addition to the Conan CLI, allowing to do bulk operations over sets of packages that
previously required user custom automation (script files or Continuous Integration jobs), and now are conveniently provided as built-in. 

Feedback is very welcome, please create a [Github issue for any question, comment or suggestion](https://github.com/conan-io/conan) about it.
