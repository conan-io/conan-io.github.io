---
layout: post
comments: false
title: "Introducing the Conan Docker runners: Running Conan Seamlessly in Docker Containers"
meta_title: "How to run Conan inside a Docker container"
description: "Running Conan inside a Docker container"
---

It is very common to want to test our code in as many environments as possible, but this is not always trivial or quick. Thanks to the Runners we can make this process much faster because it provides a seamless method to execute Conan on remote build environments like Docker ones, directly from your local setup by simply configuring your host profile.

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

First of all you need to have docker installed and running, plus conan and the docker python package. In this example we are going to use a virtualenv with both packages.

```sh
$ python3.8 -m venv conan2-runners && source conan2-runners/bin/activate
$ pip install conan docker
$ docker ps
$ CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Once the environment is ready, we are going to create create simple `cmake_lib` Conan template inside Docker using a runner. Let’s create the lib and a Dockerfile inside our project folder.

```bash
$ cd </my/runner/folder>
$ mkdir mylib
$ cd mylib
$ conan new cmake_lib -d name=mylib -d version=0.1
$ tree
.
├── CMakeLists.txt
├── conanfile.py
├── include
│   └── mylib.h
├── src
│   └── mylib.cpp
└── test_package
    ├── CMakeLists.txt
    ├── conanfile.py
    └── src
        └── example.cpp
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

```bash
$ cd </my/runner/folder>/mylib
$ tree
.
...
├── Dockerfile
...
```

Now, we need to define two new profiles inside the conan `profiles` folder. Replace `</my/runner/folder>` with your real project folder path.


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
dockerfile=</my/runner/folder>/mylib
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

Now, it's time to create our library `mylib` using our new runner definition.

```bash
$ conan create . --version 0.1 -pr:h docker_example_host -pr:b docker_example_build
```

If we split and analyze the command output, we can see what is happening and where the commands are being executed.

**1.** Standard conan execution.

```bash
======== Exporting recipe to the cache ========
mylib/0.1: Exporting package recipe: </my/runner/folder>/mylib/conanfile.py
mylib/0.1: Copied 1 '.py' file: conanfile.py
mylib/0.1: Copied 1 '.txt' file: CMakeLists.txt
mylib/0.1: Copied 1 '.h' file: mylib.h
mylib/0.1: Copied 1 '.cpp' file: mylib.cpp
mylib/0.1: Exported to cache folder: /Users/davidsanfal/.conan2/p/mylib4abd06a04bdaa/e
mylib/0.1: Exported: mylib/0.1#8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:22:01 UTC)

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

Dockerfile path: '</my/runner/folder>/mylib/Dockerfile'
Docker build context: '</my/runner/folder>/mylib'

Step 1/4 : FROM ubuntu:22.04

...

---> 2bcf70201cce
Successfully built 2bcf70201cce
Successfully tagged conan-runner-default:latest
```

**3.** Save the local cache running `conan cache save`.

```bash
***********************************************************************************
* Save host cache in: </my/runner/folder>/mylib/.conanrunner/local_cache_save.tgz *
***********************************************************************************

Found 1 pkg/version recipes matching * in local cache
Saving mylib/0.1: mylib4abd06a04bdaa
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

Conan version 2.5.0
```

**6.** Initialize the container conan cache using the host copy running `conan cache restore`.

```bash
***********************************************************************************************************
* Running in container: "conan cache restore "/root/conanrunner/mylib/.conanrunner/local_cache_save.tgz"" *
***********************************************************************************************************

Restore: mylib/0.1 in mylib4abd06a04bdaa
Local Cache
  mylib
    mylib/0.1
      revisions
        8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:22:19 UTC)
          packages
          recipe_folder: mylib4abd06a04bdaa
```

**7.** Run the conan create inside the container and build "mylib".

```bash
*********************************************************************************************************************************************************
* Running in container: "conan create /root/conanrunner/mylib --version 0.1 -pr:h docker_example_host -pr:b docker_example_build -f json > create.json" *
*********************************************************************************************************************************************************


======== Exporting recipe to the cache ========
mylib/0.1: Exporting package recipe: /root/conanrunner/mylib/conanfile.py
mylib/0.1: Copied 1 '.py' file: conanfile.py
mylib/0.1: Copied 1 '.txt' file: CMakeLists.txt
mylib/0.1: Copied 1 '.cpp' file: mylib.cpp
mylib/0.1: Copied 1 '.h' file: mylib.h
mylib/0.1: Exported to cache folder: /root/.conan2/p/mylib4abd06a04bdaa/e
mylib/0.1: Exported: mylib/0.1#8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:22:20 UTC)

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
    mylib/0.1#8760bf5a311f01cc26f3b95428203210 - Cache

======== Computing necessary packages ========
mylib/0.1: Forced build from source
Requirements
    mylib/0.1#8760bf5a311f01cc26f3b95428203210:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe - Build

======== Installing packages ========

-------- Installing package mylib/0.1 (1 of 1) --------


...

[ 50%] Building CXX object CMakeFiles/example.dir/src/example.cpp.o
[100%] Linking CXX executable example
[100%] Built target example


======== Testing the package: Executing test ========
mylib/0.1 (test package): Running test()
mylib/0.1 (test package): RUN: ./example
mylib/0.1: Hello World Release!
  mylib/0.1: __x86_64__ defined
  mylib/0.1: _GLIBCXX_USE_CXX11_ABI 1
  mylib/0.1: __cplusplus201703
  mylib/0.1: __GNUC__11
  mylib/0.1: __GNUC_MINOR__4
mylib/0.1 test_package
```

**8.** Copy just the package created inside the container using the `pkglist.json` info from the previous `conan create`, restore this new package inside the host cache running a `conan cache save` and remove the container.

```bash
************************************************************************************************************************************
* Running in container: "conan cache save --list=pkglist.json --file "/root/conanrunner/mylib"/.conanrunner/docker_cache_save.tgz" *
************************************************************************************************************************************

Saving mylib/0.1: mylib4abd06a04bdaa
Saving mylib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe: b/mylib503035e4ee8ae/p
Saving mylib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe metadata: b/mylib503035e4ee8ae/d/metadata
Local Cache
  mylib
    mylib/0.1
      revisions
        8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:22:20 UTC)
          packages
            8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe
              revisions
                ded6547554ff2306db5250451340fa43
                  package_folder: b/mylib503035e4ee8ae/p
                  metadata_folder: b/mylib503035e4ee8ae/d/metadata
              info
                settings
                  os: Linux
                  arch: x86_64
                  compiler: gcc
                  compiler.cppstd: gnu17
                  compiler.libcxx: libstdc++11
                  compiler.version: 11
                  build_type: Release
                options
                  fPIC: True
                  shared: False
          recipe_folder: mylib4abd06a04bdaa


******************************************************************************************
* Restore host cache from: </my/runner/folder>/mylib/.conanrunner/docker_cache_save.tgz  *
******************************************************************************************

Restore: mylib/0.1 in mylib4abd06a04bdaa
Restore: mylib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe in b/mylib503035e4ee8ae/p
Restore: mylib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe metadata in b/mylib503035e4ee8ae/d/metadata

**********************
* Stopping container *
**********************


**********************
* Removing container *
**********************
```

If we now check the status of our conan and docker cache, we will see the new mylib package compile for Linux and the new docker image but we don’t have any container because we define `remove=true`

```bash
$ conan list "*:*"
Found 1 pkg/version recipes matching * in local cache
Local Cache
  mylib
    mylib/0.1
      revisions
        8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:33:28 UTC)
          packages
            8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe
              info
                settings
                  arch: x86_64
                  build_type: Release
                  compiler: gcc
                  compiler.cppstd: gnu17
                  compiler.libcxx: libstdc++11
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
my-conan-runner   latest    2bcf70201cce   11 minutes ago   531MB
```

## what just happened?

What we have just done is to compile a library from scratch inside a Docker container without running any Docker command and retrieve the generated packages in a totally transparent and easily debuggable way thanks to our terminal output.


In this way, we can work as we have always done regardless of whether it is on our machine or in a container, without several open terminals and having the result of each operation in the same cache, being able to reuse the compiled packages from a previous compilation in another container automatically and transparently.

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

Let’s create a Dockerfile inside your project folder, a cmake_lib `myparamlib` like the previous example and two profiles. 

```bash
$ cd </my/runner/folder>
$ mkdir myparamlib
$ cd myparamlib
$ conan new cmake_lib -d name=myparamlib -d version=0.1
$ cd </my/runner/folder>
$ tree
.
├── CMakeLists.txt
├── conanfile.py
├── include
│   └── myparamlib.h
├── src
│   └── myparamlib.cpp
└── test_package
    ├── CMakeLists.txt
    ├── conanfile.py
    └── src
        └── example.cpp
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

```bash
$ cd </my/runner/folder>/myparamlib
$ tree
.
...
├── Dockerfile
...
├── configfile
...
```

``docker_param_example_host`` profile

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
configfile=</my/runner/folder>/myparamlib/configfile
cache=copy
remove=false
```

``docker_param_example_build`` profile

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

Now it's time to create our new library.

```bash
$ conan create . --version 0.1 -pr:h docker_param_example_host -pr:b docker_param_example_build

...

****************************************************
* Building the Docker image: my-conan-runner-image *
****************************************************

Dockerfile path: '</my/runner/folder>/myparamlib/Dockerfile'
Docker build context: '</my/runner/folder>/myparamlib'

Step 1/5 : ARG BASE_IMAGE

Step 2/5 : FROM $BASE_IMAGE

...

Successfully built caa8071cdff7
Successfully tagged my-conan-runner-image:latest

...

**************************************************************************************************************************************************************************
* Running in container: "conan create /root/conanrunner/myparamlib --version 0.1 -pr:h docker_param_example_host -pr:b docker_param_example_build -f json > create.json" *
**************************************************************************************************************************************************************************

...

[ 50%] Building CXX object CMakeFiles/example.dir/src/example.cpp.o
[100%] Linking CXX executable example
[100%] Built target example

======== Testing the package: Executing test ========
myparamlib/0.1 (test package): Running test()
myparamlib/0.1 (test package): RUN: ./example
myparamlib/0.1: Hello World Release!
  myparamlib/0.1: __x86_64__ defined
  myparamlib/0.1: _GLIBCXX_USE_CXX11_ABI 1
  myparamlib/0.1: __cplusplus201703
  myparamlib/0.1: __GNUC__11
  myparamlib/0.1: __GNUC_MINOR__4
myparamlib/0.1 test_package


**********************************************************************************************
* Restore host cache from: </my/runner/folder>/myparamlib/.conanrunner/docker_cache_save.tgz *
**********************************************************************************************

Saving myparamlib/0.1: mypar36e44205a36b9
Saving myparamlib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe: b/mypare0dc449d4125d/p
Saving myparamlib/0.1:8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe metadata: b/mypare0dc449d4125d/d/metadata
```

If we now check the status of our conan cache, we will see the `mylib` package and the new `myparamlib` pacakge.

```sh
    $ conan list "*:*"
    Found 2 pkg/version recipes matching * in local cache
    Local Cache
    mylib
        mylib/0.1
        revisions
            8760bf5a311f01cc26f3b95428203210 (2024-07-08 12:33:28 UTC)
            packages
                8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe
                info
                    settings
                    arch: x86_64
                    build_type: Release
                    compiler: gcc
                    compiler.cppstd: gnu17
                    compiler.libcxx: libstdc++11
                    compiler.version: 11
                    os: Linux
                    options
                    fPIC: True
                    shared: False
    myparamlib
        myparamlib/0.1
        revisions
            11cb359a0526fe9ce3cfefb59c5d1953 (2024-07-08 12:47:21 UTC)
            packages
                8631cf963dbbb4d7a378a64a6fd1dc57558bc2fe
                info
                    settings
                    arch: x86_64
                    build_type: Release
                    compiler: gcc
                    compiler.cppstd: gnu17
                    compiler.libcxx: libstdc++11
                    compiler.version: 11
                    os: Linux
                    options
                    fPIC: True
                    shared: False
```