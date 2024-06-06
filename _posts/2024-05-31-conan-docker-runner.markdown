---
layout: post
comments: false
title: "Introducing the Conan Docker runners: Running Conan Seamlessly in Docker Containers"
meta_title: "How to run Conan inside a Docker container"
description: "Running Conan inside a Docker container"
---

Runners provide a seamless method to execute Conan on remote build environments like Docker ones, directly from your local setup by simply configuring your host profile.

## Introduction

When you want to test your packages on a different architecture or in a clean environment, it always takes a lot of time to do the first setup and it is not very comfortable to edit your code in one place to test it in a different one. Thanks to the runners, this task is done in a faster, easier and more transparent way. By simply creating a profile and adding the runner section you will almost forget that you are working inside a container.

Before we see how it works, let's review the main features of these runners and the options available to us.

### Seamless integration

When you define a docker runner inside your host profile you are saying that you want to build your code using conan inside a docker image. Conan will try to build or reuse a docker image and run a conan create conan inside it. After that, conan copy the cache information from your docker container inside your host cache, obtaining the same result like an standard conan create.

### Customizable Images

In order to have as much freedom as possible, you can use the precompiled image you want or use a Dockerfile in case you want to create it during the command execution. The only requirement is that the container has installed conan 2.3.0 or higher.

To use our own Dockerfile you have to define its absolute path in the `dockerfile` variable. In addition, you can define the `build_context` of the container in case it is not the same as the one defined in the `dockerfile` variable.

Finally, if you want to use a pre-existing image or you want to give a specific name to the one you are compiling, you have the variable `image` where to define it.

### Different cache modes

To have a better control of what is being built, there are several ways to work with the cache inside the container using the profile variable `cache`.

- `clean`: the container uses an empty cache. This is the default mode.
- `copy`: copy the host cache inside the container using the conan cache save/restore command.
- `shared`: mount the host’s Conan cache as a shared volume.

In all cases the result of the `conan create` command will be exactly the same and will end up stored in the local host cache, what changes is the starting point of the container cache and the way the result of the command ends up in the local host cache.

### Container lifecycle control

By default conan doesn't remove the container once the execution is finished. This way you can reuse the same container in case you want to run another create on the same container.

- `suffix`: *docker* by default. Define the suffix name used to create your container *conan-runner-*`suffix`.
- `remove`: *false* by default. If you want to delete you container after an execution set it to *true*.

### Host profile example

This is an example of how a profile with the runner section would look like for a docker container in which we want to build the image using a specific build_context and keeping the container for future executions.

```
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
[runner]
type=docker
dockerfile=/Users/conan/dockerfiles/Dockerfile.gnu17
build_context=/Users/conan/my_lib/
image=conan-runner-gnu17
cache=copy
suffix=gnu17
remove=true
```

## Lets try it!

In this example we are going to see how to create the zlib/1.3.1 Conan packge inside Docker using a runner. Let’s create two profiles and a Dockerfile inside our project folder.

```bash
$ cd </my/runner/folder>
$ tree
.
├── Dockerfile
├── docker_example_build
└── docker_example_host
```

`docker_example_host` profile

```
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
[runner]
type=docker
dockerfile=</my/runner/folder>
cache=copy
remove=true
```

`docker_example_build` profile

```
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
```

`Dockerfile`

```dockerfile
FROM ubuntu:22.04
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN pip install conan
```

We are going to start from a totally clean environment, without any containers, images or conan package.

```bash
$ conan list "*:*"
Found 0 pkg/version recipes matching * in local cache
```

```bash
$ docker ps --all
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
$ docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

Now, we are going to clone and build zlib from conan-center-index and create it using our new runner definition.

```bash
$ git clone https://github.com/conan-io/conan-center-index.git --depth=1
$ conan create ./conan-center-index/recipes/zlib/all --version 1.3.1 -pr:h </my/runner/folder>/docker_example_host -pr:b </my/runner/folder>/docker_example_build
```

If we split and analyze the command output, we can see what is happening and where the commands are being executed.

**1.** Standard conan execution.

```bash
======== Exporting recipe to the cache ========
zlib/1.3.1: Exporting package recipe: </my/runner/folder>/conan-center-index/recipes/zlib/all/conanfile.py
zlib/1.3.1: exports: File 'conandata.yml' found. Exporting it...
zlib/1.3.1: Calling export_sources()
zlib/1.3.1: Copied 1 '.py' file: conanfile.py
zlib/1.3.1: Copied 1 '.yml' file: conandata.yml
zlib/1.3.1: Copied 1 '.patch' file: 0001-fix-cmake.patch
zlib/1.3.1: Exported to cache folder: /Users/conan/.conan2/p/zlib95420566fc0dd/e
zlib/1.3.1: Exported: zlib/1.3.1#e20364c96c45455608a72543f3a53133 (2024-04-29 17:03:44 UTC)

======== Input profiles ========
Profile host:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux

Profile build:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
```

**2.** Build docker image

```bash
**********************************************
* Building the Docker image: my-conan-runner *
**********************************************

Dockerfile path: '</my/runner/folder>/Dockerfile'
Docker build context: '</my/runner/folder>'

Step 1/4 : FROM ubuntu:22.04

...

---> dba927bb0517
Successfully built dba927bb0517
Successfully tagged my-conan-runner:latest
```

**3.** Save the local cache running `conan cache save`.

```bash
******************************************************************************************************************
* Save host cache in: </my/runner/folder>/conan-center-index/recipes/zlib/all/.conanrunner/local_cache_save.tgz *
******************************************************************************************************************

Found 1 pkg/version recipes matching * in local cache
Saving zlib/1.3.1: p/zlib95420566fc0dd
```

**4.** Create and initialize the docker container.

```bash
*********************************
* Creating the docker container *
*********************************

*****************************************
* Container conan-runner-docker running *
*****************************************
```

**5.** Check if the container has a conan version with the runner feature.

```bash
*******************************************
* Running in container: "conan --version" *
*******************************************

Conan version 2.3.0
```

**6.** Initialize the container conan cache using the host copy running `conan cache restore`.

```bash
*********************************************************************************************************
* Running in container: "conan cache restore "/root/conanrunner/all/.conanrunner/local_cache_save.tgz"" *
*********************************************************************************************************

Restore: zlib/1.3.1 in p/zlib95420566fc0dd
Local Cache
zlib
    zlib/1.3.1
    revisions
        e20364c96c45455608a72543f3a53133 (2024-04-29 17:19:32 UTC)
        packages
        recipe_folder: p/zlib95420566fc0dd
```

**7.** Run the conan create inside the container and build zlib.

```bash
*****************************************************************************************************************************************************************************************************************************************************
* Running in container: "conan create /root/conanrunner/all --version 1.3.1 -pr:h /root/conanrunner/all/.conanrunner/profiles/docker_example_host_1 -pr:b /root/conanrunner/all/.conanrunner/profiles/docker_example_build_0 -f json > create.json" *
*****************************************************************************************************************************************************************************************************************************************************


======== Exporting recipe to the cache ========
zlib/1.3.1: Exporting package recipe: /root/conanrunner/all/conanfile.py
zlib/1.3.1: exports: File 'conandata.yml' found. Exporting it...
zlib/1.3.1: Calling export_sources()
zlib/1.3.1: Copied 1 '.yml' file: conandata.yml
zlib/1.3.1: Copied 1 '.py' file: conanfile.py
zlib/1.3.1: Copied 1 '.patch' file: 0001-fix-cmake.patch
zlib/1.3.1: Exported to cache folder: /root/.conan2/p/zlib95420566fc0dd/e
zlib/1.3.1: Exported: zlib/1.3.1#e20364c96c45455608a72543f3a53133 (2024-04-29 17:19:32 UTC)

======== Input profiles ========
Profile host:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux

Profile build:
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux


======== Computing dependency graph ========
Graph root
    cli
Requirements
    zlib/1.3.1#e20364c96c45455608a72543f3a53133 - Cache

======== Computing necessary packages ========
zlib/1.3.1: Forced build from source
Requirements
    zlib/1.3.1#e20364c96c45455608a72543f3a53133:b647c43bfefae3f830561ca202b6cfd935b56205 - Build

======== Installing packages ========
zlib/1.3.1: Calling source() in /root/.conan2/p/zlib95420566fc0dd/s/src

...

[ 50%] Building C object CMakeFiles/test_package.dir/test_package.c.o
[100%] Linking C executable test_package
[100%] Built target test_package

======== Testing the package: Executing test ========
zlib/1.3.1 (test package): Running test()
zlib/1.3.1 (test package): RUN: ./test_package
Compressed size is: 21
Compressed string is: Conan Package Manager
Compressed size is: 22
Compressed string is: xsKHLNLOUMRE
ZLIB VERSION: 1.3.1
```

**8.** Copy just the package created inside the container using the `pkglist.json` info from the previous `conan create`, restore this new package inside the host cache running a `conan cache save` and remove the container.

```bash
**********************************************************************************************************************************
* Running in container: "conan cache save --list=pkglist.json --file "/root/conanrunner/all"/.conanrunner/docker_cache_save.tgz" *
**********************************************************************************************************************************

Saving zlib/1.3.1: p/zlib95420566fc0dd
Saving zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205: p/b/zlib8dd8e27348e8c/p
Saving zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205 metadata: p/b/zlib8dd8e27348e8c/d/metadata
Local Cache
zlib
    zlib/1.3.1
    revisions
        e20364c96c45455608a72543f3a53133 (2024-04-29 17:19:32 UTC)
        packages
            b647c43bfefae3f830561ca202b6cfd935b56205
            revisions
                fd85b1346d5377ae2465645768e62bf2
                package_folder: p/b/zlib8dd8e27348e8c/p
                metadata_folder: p/b/zlib8dd8e27348e8c/d/metadata
            info
                settings
                os: Linux
                arch: x86_64
                compiler: gcc
                compiler.version: 11
                build_type: Release
                options
                fPIC: True
                shared: False
        recipe_folder: p/zlib95420566fc0dd


************************************************************************************************************************
* Restore host cache from: </my/runner/folder>/conan-center-index/recipes/zlib/all/.conanrunner/docker_cache_save.tgz *
************************************************************************************************************************

Restore: zlib/1.3.1 in p/zlib95420566fc0dd
Restore: zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205 in p/b/zlib8dd8e27348e8c/p
Restore: zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205 metadata in p/b/zlib8dd8e27348e8c/d/metadata

**********************
* Stopping container *
**********************


**********************
* Removing container *
**********************
```

If we now check the status of our conan and docker cache, we will see the new zlib package compile for Linux and the new docker image. We don’t have any container because we define `remove=true`

```bash
$ conan list "*:*"
Found 1 pkg/version recipes matching * in local cache
Local Cache
zlib
    zlib/1.3.1
    revisions
        e20364c96c45455608a72543f3a53133 (2024-04-29 17:18:07 UTC)
        packages
            b647c43bfefae3f830561ca202b6cfd935b56205
            info
                settings
                arch: x86_64
                build_type: Release
                compiler: gcc
                compiler.version: 11
                os: Linux
                options
                fPIC: True
                shared: False
```

```bash
$ docker ps --all
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
$ docker images
REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
my-conan-runner   latest    383b905f352e   22 minutes ago   531MB
ubuntu            22.04     437ec753bef3   12 days ago      77.9MB
```

### Bonus track: Do you need more control when running or building your containers? The configfile runner is the answer.

If you need more control over the build and execution of the container, you can define more parameters inside a configfile yaml.

For example, you can add arguments in the build step or environment variables when you launch the container.

This is the template with all the parameters it accepts:

```yaml
image: image_name # The image to build or run.
build:
    dockerfile: /dockerfile/path # Dockerfile path.
    build_context: /build/context/path # Path within the build context to the Dockerfile.
    build_args: # A dictionary of build arguments
        foo: bar
    cacheFrom: # A list of images used for build cache resolution
        - image_1
run:
    name: container_name # The name for this container.
    containerEnv: # Environment variables to set inside the container.
        env_var_1: env_value
    containerUser: user_name # Username or UID to run commands as inside the container.
    privileged: False # Run as privileged
    capAdd: # Add kernel capabilities.
        - SYS_ADMIN
        - MKNOD
    securityOpt: # A list of string values to customize labels for MLS systems, such as SELinux.
        - opt_1
    mount: # A dictionary to configure volumes mounted inside the container.
        /home/user1/: # The host path or a volume name
            bind: /mnt/vol2 # The path to mount the volume inside the container
            mode: rw # rw to mount the volume read/write, or ro to mount it read-only.
```

To use it, you just need to add it in the host profile as always.

```
[settings]
...
[runner]
type=docker
configfile=</my/runner/folder>/configfile
cache=copy
remove=false
```

**How to use**

Let’s create two profiles and a Dockerfile inside your project folder.

```bash
$ cd </my/runner/folder>
$ tree
.
├── Dockerfile
├── configfile
├── docker_example_build
└── docker_example_host
```

``docker_example_host`` profile

```
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
[runner]
type=docker
configfile=</my/runner/folder>/configfile
cache=copy
remove=false
```

``docker_example_build`` profile

```
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
os=Linux
```

```dockerfile
ARG BASE_IMAGE
FROM $BASE_IMAGE
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN pip install conan
```

Now, we need to write the `configfile` to defile the `BASE_IMAGE` variable defined inside the Dockerfile.

``configfile``

```yaml

    image: my-conan-runner-image
    build:
        dockerfile: </my/runner/folder>
        build_context: </my/runner/folder>
        build_args:
            BASE_IMAGE: ubuntu:22.04
    run:
        name: my-conan-runner-container
```

Now, lets clone and build zlib from conan-center-index like the previous example.

```bash    
$ git clone https://github.com/conan-io/conan-center-index.git --depth 1
$ conan create ./conan-center-index/recipes/zlib/all --version 1.3.1 -pr:h </my/runner/folder>/docker_example_host -pr:b </my/runner/folder>/docker_example_build

...

┌──────────────────────────────────────────────────┐
| Building the Docker image: my-conan-runner-image |
└──────────────────────────────────────────────────┘

Dockerfile path: '</my/runner/folder>/Dockerfile'
Docker build context: '</my/runner/folder>'

Step 1/5 : ARG BASE_IMAGE

Step 2/5 : FROM $BASE_IMAGE

...

Successfully built 286df085400f
Successfully tagged my-conan-runner-image:latest

...

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
| Running in container: "conan create /root/conanrunner/all --version 1.3.1 -pr:h /root/conanrunner/all/.conanrunner/profiles/docker_example_host_1 -pr:b /root/conanrunner/all/.conanrunner/profiles/docker_example_build_0 -f json > create.json" |
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

...

[ 50%] Building C object CMakeFiles/test_package.dir/test_package.c.o
[100%] Linking C executable test_package
[100%] Built target test_package

======== Testing the package: Executing test ========
zlib/1.3.1 (test package): Running test()
zlib/1.3.1 (test package): RUN: ./test_package
Compressed size is: 21
Compressed string is: Conan Package Manager
Compressed size is: 22
Compressed string is: xsKHLNLOUMRE
ZLIB VERSION: 1.3.1


┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
| Restore host cache from: </my/runner/folder>/conan-center-index/recipes/zlib/all/.conanrunner/docker_cache_save.tgz |
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Restore: zlib/1.3.1 in p/zlib95420566fc0dd
Restore: zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205 in p/zlibd59462fc4358e/p
Restore: zlib/1.3.1:b647c43bfefae3f830561ca202b6cfd935b56205 metadata in p/zlibd59462fc4358e/d/metadata

┌────────────────────┐
| Stopping container |
└────────────────────┘
```