---
layout: post
comments: false
title: "Deployment of C++ projects: different approaches"
---

## Deployment of C++ projects: different approaches

For the time being, it's frequently asked on how to deploy C++ applications, and how to generate a deployment artifact after the build.

## Approaches

### System package manager

Although usage of system package managers is usually a recommended way, there are some minor disadvantages:

- Scalability problem - each distribution requires its package format, like ``pacman`` on ``Arch``, ``deb`` on ``Debian`` and ``rpm`` on ``RedHat``

- Even for the same distribution, it's often needed to provide N packages for each supported version

- Due to the differences in distributions (notably, system libraries, like ``glibc`` or ``libstdc++``), it's sometimes needed to compile application several times using a different environment

- In addition to the scalability problems mentioned above, not all systems have package managers, like some embedded systems or LFS distributions

- It might be problematic to have a dependency on up-to-date libraries (e.g. CentOS or Debian packages for the latest ``boost`` release might not be always available)

Due to the limitations above, there are other approaches available around.

### Archives

The most simple way to distribute the application is to make an archive (tarball) with:

- application executable itself

- resources used by the application (e.g. images, fonts, etc.)

- libraries used by the application (shared libraries of dependencies like ``boost``, ``OpenCV``, etc.)

the obvious disadvantage is that it might be required to set up some environment variables before the execution, like ``PATH`` or ``LD_LIBRARY_PATH``  to locate dependent libraries, so small launch script has to be provided.

### Makeself.io

[Makeself.io](https://makeself.io) is a very simple tool to create a self-extracting archives (SFX).
The tool first creates an tarball of the application and its resources, then attaches a small script stub,
which extracts the archive into temporary directory, and passes the control to the embedded executable.
Such self-extracting archives are often named ``mysoftware.run`` or ``mysoftware.sh``, and the technique
is widely used by various popular software (e.g. [CMake](https://cmake.org/download/)).

### Portable applications

The next logical step is to create a portable application, which are usually sand-boxed images with virtual file system containing all the files required by the application.

There are several solutions already available, the most popular are:

- [AppImage](https://appimage.org/)

- [Snap](https://snapcraft.io/)

- [Flatpak](https://flatpak.org/)

### Using conan-deploy-tool

Creating tarballs manually might be boring, especially if project has many dependencies.

There is an idea - if [conan](https://conan.io) already knows about all dependencies, why not use information provided by [conan](https://conan.io) to generate deployment artifact?

As [conan](https://conan.io) itself is a package manager, conan developers decided to follow the unix-way, and do only one thing and do it well - package management.

Therefore [conan](https://conan.io) itself doesn't provide any facilities for deployment, concentrating on the package management problem. As a solution, an external tool is provided.

If the [conan](https://conan.io) package manager is in use within the project, then [conan-deploy-tool](https://pypi.org/project/conan-deploy-tool/) might be considered useful and helpful.

It's pretty straightforward to install it:

{% highlight bash %}
$ pip install conan-deploy-tool
{% endhighlight %}

In order to use the tool, the small configuration file is required:

**conan-deploy.conf**
[general]
name = Camera
executable = bin/camera

Very few things are needed to specify - which executable has to be launched, and what's the name of an output artifact.

In order to invoke the tool, the following simple command might be used (specifying ``zip`` generator):

{% highlight bash %}
$ conan-deploy-tool -g zip
{% endhighlight %}

as result, it will produce the ``Camera.zip`` archive. And to use ``AppImage`` it's just needed to write:

{% highlight bash %}
$ conan-deploy-tool -g appimage
{% endhighlight %}

this will automatically download AppImageTool and AppImageRuntime files and create a ``Camera-x86_64.AppImage`` executable.

There are several generators available at the moment:

- ``dir`` to create a directory with all dependencies copied

- archive generators, with several formats supported: ``zip``, ``tgz``, ``tbz``, ``txz``

- ``makeself``

- ``flatpak``

- ``appimage``

it's pretty straightforward to define more generators for additional formats (e.g. cabinet archives, or whatever else needed).

The internal process of creating an artifact is simple:

- invoke [conan](https://conan.io) with [json generator](https://docs.conan.io/en/latest/reference/generators/json.html) in order to collect information about dependencies

- copy files from binary and library directories of all dependencies into the destination directory

- invoke ``conan imports`` to copy other resources, such as images, fonts or whatever is required by the specific application

- copy the executable specified by the configuration file into the destination directory

- generate a startup shell script, which sets required environment variables (mostly ``PATH`` and ``LD_LIBRARY_PATH``) and passes control to the main executable

- generate an image, archive or another artifact from the directory

### Conclusion

The illustrated approach of ``conan-deploy-tool`` is just an example and prototype to show how is it possible to use the information provided by [conan](https://conan.io) in order to make a deployment artifact.

It's not recommended to use it in production or enterprise environment, and instead, it's much better and convenient to use some industry-standard tools, like [chef](https://www.chef.io/), [puppet](https://puppet.com/) or [ansible](https://www.ansible.com/).
