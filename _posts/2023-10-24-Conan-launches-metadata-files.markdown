---
layout: post
comments: false
title: "Conan launches metadata files management"
meta_title: "Conan launches metadata files management"
description: "Conan 2.0 new feature metadata-files allows creating, storing, adding, upload and retrieving metadata files as build logs, test results, etc."
---


A C or C++ package is typically composed of several C and C++ artifacts, headers, compiled libraries and executables. But there are other files that might not be necessary for the normal consumption of such a package, but that could be very important for technical or business reasons, like regulations, compliance, security, reproducibility and traceability. Some examples would be:

- Full build logs
- The tests executables
- The tests results from running the test suite
- Debugging artifacts like heavy .pdb files
- Coverage, sanitizers, or other source or binary analysis tools results
- Context and metadata about the build, exact machine, environment, author, CI data
- Other compliance and security related files

The problem with these files is that they can be large/heavy, if we store them inside the package (just copying the artifacts in the ``package()`` method), this will make the packages much larger, and it will affect the speed of downloading, unzipping and using packages in general. And this typically happens a lot of times, both in developer machines but also in CI, and it can have an impact on the developer experience and infrastructure costs. Furthermore, packages are immutable, that is, once a package has been created, it shouldn't be modified. This might be a problem if we want to add extra metadata files after the package has been created, or even after the package has been uploaded.

The new **metadata files** feature allows to create, upload, append and store metadata associated to packages in an integrated and unified way, while avoiding the impact on developers and CI speed and costs, because metadata files are not downloaded and unzipped by default when packages are used.

## Creating metadata

Recipes can directly define metadata, a common use case would be to store the build logs as metadata, explicitly in recipes, which can be done by just copying files or folders to the ``self.package_metadata_folder``:

```python
import os
from conan import ConanFile
from conan.tools.files import copy


class Pkg(ConanFile):
  name = "pkg"
  version = "0.1"

  def build(self):
      # logs originated at build() step, the most common ones
      # assume that "mylogs.txt" is the output of some build steps 
      copy(self, "mylogs.txt", src=self.build_folder,
          dst=os.path.join(self.package_metadata_folder, "logs"))
```

When this recipe builds from source, either in the Conan cache with ``conan create`` or locally with ``conan build``, it will copy those logs to the “metadata” folder. When the package is created in the cache, we can easily inspect the metadata folder with the help of the ``conan cache path`` command:

```bash
$ conan create .
$ conan cache path pkg/0.1:package_id --folder=metadata
# folder containing the specific "package_id" binary metadata
```

If the same files are created in the build of multiple packages, we can also use hooks. Let’s take this simpler recipe, that is not explicitly storing the metadata of the build logs, but just generates the files at build time.

```python
from conan import ConanFile
from conan.tools.files import save


class Pkg(ConanFile):
  name = "pkg"
  version = "0.1"

  def build(self):
      # logs originated at build() step, the most common ones
      # assume that "mylogs.txt" is the output of some build steps
      save(self, "mylogs.txt", "some logs!!!")
```

A ``post_build`` hook can be defined that has the same effect as the in-recipe version, with the main difference is that hooks apply to all packages:

```python
import os
from conan.tools.files import copy


def post_build(conanfile):
      conanfile.output.info("post_build")
      copy(conanfile, "*", src=conanfile.build_folder,
        dst=os.path.join(conanfile.package_metadata_folder, "logs"))
```

Metadata files can also be added or modified after the package has been created. To achieve this, using the ``conan cache path`` command will return the folders to do that operation, so copying, creating or modifying files in that location will achieve this. And this operation is allowed, as opposed to modifying package files, as packages must be immutable.

```bash
$ conan create . --name=pkg --version=0.1
$ conan cache path pkg/0.1:package_id --folder=metadata
# we can copy and put files in that folder
```

## Uploading metadata

So far the metadata has been created locally, stored in the Conan cache. Uploading the metadata to the server is integrated with the existing ``conan upload`` command:

```bash
$ conan upload "*" -c -r=myremote
# Uploads recipes, packages and metadata to the "myremote" remote
...
pkg/0.1: Recipe metadata: 1 files
pkg/0.1:da39a3ee5e6b4b0d3255bfef95601890afd80709: Package metadata: 1 files
```

By default, ``conan upload`` will upload recipes and packages metadata when a recipe or a package is uploaded to the server.

But there are some situations that Conan will completely avoid this upload, if it detects that the revisions do already exist in the server, it will not upload the recipes or the packages. If the metadata has been locally modified or added new files, we can force the upload of the metadata explicitly with the ``--metadata`` argument:

```bash
# We added some metadata to the packages in the cache
# But those packages already exist in the server
$ conan upload "*" -c -r=myremote --metadata="*"
...
pkg/0.1: Recipe metadata: 1 files
pkg/0.1:da39a3ee5e6b4b0d3255bfef95601890afd80709: Package metadata: 1 files
```

The ``--metadata`` argument allows us to specify the metadata files that we are uploading. If we structure them in folders, for example, we could specify ``--metadata=logs*`` to upload only the logs metadata.

```bash
# Upload only the logs metadata of the zlib/1.2.13 binaries
# This will upload the logs even if zlib/1.2.13 is already in the server
$ conan upload "zlib/1.2.13:*" -r=myremote -c --metadata="logs/*"
# Multiple patterns are allowed:
$ conan upload "*" -r=myremote -c --metadata="logs/*" --metadata="tests/*"
```

## Downloading metadata

As described in the introduction, metadata is not downloaded by default. When packages are downloaded with a ``conan install`` or ``conan create`` fetching dependencies from the servers, the metadata from those servers will not be downloaded.

The way to recover the metadata from the server is to explicitly specify it with the ``conan download`` command:

```bash
# Get the metadata of the "pkg/0.1" package
$ conan download pkg/0.1 -r=myremote --metadata="*"
...
$ conan cache path pkg/0.1:package_id --folder=metadata
# Inspect the package metadata for binary "package_id"
```

The retrieval of the metadata is done with ``download`` per-package. If we want to download the metadata for a whole dependency graph, it is necessary to use "package-lists":

```bash
$ conan install . --format=json -r=myremote > graph.json
$ conan list --graph=graph.json --format=json > pkglist.json
# the list will contain the "myremote" origin of downloaded packages
$ conan download --list=pkglist.json --metadata="*" -r=myremote
```

Note that the "package-list" will only contain the packages associated to the "myremote" origin that were downloaded. If they were previously in the cache, then they will not be listed under the "myremote" origin and the metadata will not be downloaded. If you want to collect the dependencies metadata, recall to download it when the package is installed from the server.
There are other possibilities, like a custom command that can automatically collect and download dependencies metadata from the servers.


## Conclusions

The **metadata files** has been a popular feature request for a long time, and we are very excited to be able to release it. We believe that it will help many users to better manage their metadata files and assets, simplifying the management, storage, tracking and retrieval of those files. And this can reduce efforts and costs of implementing better compliance, reproducibility, traceability and security.

It is important to highlight that the addition of this new feature is thanks to the new Conan 2.0 architecture and capabilities. One of the reasons why this new major 2.0 version was necessary was to unlock these awaited features that couldn’t be implemented while in Conan 1.X.

For more information about the metadata files and other related features, check the new documentation [Devops guide](https://docs.conan.io/2/devops.html)

We are looking forward to hearing your feedback, use cases and needs, to keep improving this feature. Please report it in [Github issues](https://github.com/conan-io/conan/issues)
