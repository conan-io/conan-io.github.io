---
layout: post
comments: false
title: "OpenCV Conan package making off and future challenges"
description: "Hands-on packaging OpenCV (the proper way)"
---

### What is OpenCV?

If you're not familiar with OpenCV yet, check out our previous blog-post about [OpenCV 4.0.0](https://blog.conan.io/2018/12/19/New-OpenCV-release-4-0.html).
Given the fact OpenCV is a huge library with lots of features for various use-case, it's a good example to demonstrate some typical package challenges (and probably few more specific as well).

### OpenCV's Conan packages

Recently, we have finally accepted OpenCV recipe into [conan-center](https://bintray.com/conan-community/conan/opencv%3Aconan).
We support all major releases, so we have the following version available on Bintray:

* 4.x - [opencv/4.0.1@conan/stable](https://bintray.com/conan-community/conan/opencv%3Aconan/4.0.1%3Astable).
* 3.x - [opencv/3.4.5@conan/stable](https://bintray.com/conan-community/conan/opencv%3Aconan/3.4.5%3Astable).
* 2.x - [opencv/2.4.13.5@conan/stable](https://bintray.com/conan-community/conan/opencv%3Aconan/2.4.13.5%3Astable).

Installation with Conan should be pretty straightforward, e.g. you may use the following [conanfile.txt](https://docs.conan.io/en/latest/reference/conanfile_txt.html) to consume OpenCV 4.0.0:

{% highlight conf %}

[requires]
opencv/4.0.1@conan/stable

[generators]
cmake

{% endhighlight %}

As usual, pre-built packages are available for major platforms (Windows/Linux/MacOS) and compilers (Visual Studio/GCC/Clang).

### Building OpenCV

OpenCV uses [CMake](https://cmake.org/), therefore our [recipe](https://github.com/conan-community/conan-opencv/blob/release/4.0.1/conanfile.py) uses [CMake build helper](https://docs.conan.io/en/latest/reference/build_helpers/cmake.html#cmake-reference). The process to build a CMake-based project is typical for many recipes, and OpenCV is not an exception here.

The first step is to configure CMake:

{% highlight python %}

    def _configure_cmake(self):
        cmake = CMake(self)
        # configure various OpenCV options via cmake.definitions
        cmake.configure(build_folder=self._build_subfolder)
        return cmake

{% endhighlight %}

There is really nothing special, besides there are lots of options to manage, that's why code takes so many lines. *cmake.configure(...)* detects compiler and its features, then generates platform-specific build files.

Here we also disable a bunch of stuff we would like to avoid:

{% highlight python %}

        cmake.definitions['BUILD_EXAMPLES'] = False
        cmake.definitions['BUILD_DOCS'] = False
        cmake.definitions['BUILD_TESTS'] = False
        cmake.definitions['BUILD_PERF_TEST'] = False
        cmake.definitions['WITH_IPP'] = False
        cmake.definitions['BUILD_opencv_apps'] = False
        cmake.definitions['BUILD_opencv_java'] = False

{% endhighlight %}

*cmake.definitions* is a dictionary which is translated into command line arguments passed to the cmake, for instance, *cmake.definitions['BUILD_EXAMPLES'] = False* maps into *-DBUILD_EXAMPLES=OFF*.

Some explanation for the specific variables:

* *BUILD_EXAMPLES* - do not build OpenCV examples, as they are not needed to use OpenCV, but increase build times and package sizes.
* *BUILD_DOCS* - skip documentation for the same reason as examples, we usually keep only things needed to link with the package, and also build of documentation may require additional tools (such as [doxygen](http://www.doxygen.nl/)).
* *BUILD_TESTS* - same story, as we're not going to run these tests, skip them from build.
* *BUILD_PERF_TEST* - another set of tests to skip.
* *BUILD_opencv_apps* - skip some demonstration and utility applications supplied with OpenCV.
* *BUILD_opencv_java* - as we're building packages for C++, disable Java bindings as well. also, installation of them requires [JDK](https://www.oracle.com/technetwork/java/javase/downloads/index.html), [Apache ANT](https://ant.apache.org/), etc. and may fail, if they are not found.

Once CMake configuration is done, we may build the project:

{% highlight python %}

    def build(self):
        # intentionally skipped code to patch OpenEXR here
        cmake = self._configure_cmake()
        cmake.build()

{% endhighlight %}

*cmake.build()* executes build tool depending on CMake [generator](https://cmake.org/cmake/help/v3.13/manual/cmake-generators.7.html), it might be [MSBuild](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild?view=vs-2017), [GNU Make](https://www.gnu.org/software/make/), [Ninja](https://ninja-build.org/), etc. This is really nice, as we don't have to deal with platform-specific details on how to build a project. As a counterexample, many projects still use different build systems to compile for various platforms, like Visual Studio solutions are used on Windows, and makefiles otherwise - for such projects recipes need to have several implementations of the [build](https://docs.conan.io/en/latest/reference/conanfile/methods.html#build) method, with the handling of all options, of course.

Moreover, [package](https://docs.conan.io/en/latest/reference/conanfile/methods.html#package) method of our recipe is also very simple:

{% highlight python %}

    def package(self):
        cmake = self._configure_cmake()
        cmake.install()
        cmake.patch_config_paths()

{% endhighlight %}

It doesn't have typical code to copy platform-specific files, like .dll, .so, .dylib, etc. Instead, it uses CMake [install](https://cmake.org/cmake/help/v3.13/command/install.html) feature. CMake may generate special target called *INSTALL*, which copies project's header, libraries, CMake [configuration](https://cmake.org/cmake/help/v3.13/manual/cmake-packages.7.html) files, [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/) files, other data files, like [Haar Cascades](https://docs.opencv.org/4.0.1/d7/d8b/tutorial_py_face_detection.html) in case of OpenCV. So, if the project itself knows which files to distribute and how to properly layout them, then it doesn't make much sense to replicate this logic in conanfile, right? Also, *CMake.install* method automatically points [CMAKE_INSTALL_PREFIX](https://cmake.org/cmake/help/v3.13/variable/CMAKE_INSTALL_PREFIX.html) to the [package folder](https://docs.conan.io/en/latest/reference/conanfile/attributes.html?highlight=package_folder#folders-attributes-reference).

But what is *cmake.patch_config_paths()* and why do we need it? Well, CMake-generated config files may contain absolute paths, which something we would like to avoid, because such paths are specific to the machine where the recipe was built, and consumers usually won't have dependencies installed in the same paths. For instance, on Windows Conan directory usually located within [USERPROFILE](https://msdn.microsoft.com/en-us/library/windows/desktop/bb776892(v=vs.85).aspx) directory, which contains user name (e.g. *AppVeyor*). Given that fact, usage of generated CMake config files may result in the inability to build the project, so there is a workaround for this problem in Conan.

### dependencies

OpenCV is a very complex library and has lots of various dependencies. Current Conan recipe has the following:

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2019-01-21/opencv-deps.png"  align="center"
    width="800"  alt="dependencies of OpenCV 4.0.0 package"/>
</p>

A graph was generated by the [conan info](https://docs.conan.io/en/latest/reference/commands/consumer/info.html) command:

{% highlight bash %}

$ conan info opencv/4.0.0@conan/stable --graph opencv

{% endhighlight %}

As you can see, currently it mostly depends on image libraries, such as [libjpeg](http://libjpeg.sourceforge.net/), [libtiff](http://www.libtiff.org/), [libpng](http://www.libpng.org/pub/png/libpng.html), [libwepb](https://developers.google.com/speed/webp/), [jasper](http://www.ece.uvic.ca/~frodo/jasper/) and [OpenEXR](http://www.openexr.com/).

All these libraries are available as Conan packages in [conan-center](https://bintray.com/conan-community/conan/opencv%3Aconan) as well. Thanks to [bincrafters](https://github.com/bincrafters/community) for packaging them all.

These libraries are mainly needed by OpenCV [imgcodecs](https://docs.opencv.org/4.0.1/d4/da8/group__imgcodecs.html), to support reading and writing of various image formats.

All mentioned libraries might be enabled or disabled using options (They are currently enabled by default). For instance, to disable [OpenEXR](http://www.openexr.com/) support, use the following:

{% highlight conf %}

[requires]
opencv/4.0.1@conan/stable

[options]
opencv:openexr=False

[generators]
cmake

{% endhighlight %}

#### declaring dependencies

In order to declare dynamic dependencies on other 3rd-party libraries, OpenCV [recipe](https://github.com/conan-community/conan-opencv/blob/release/4.0.1/conanfile.py) uses [requirements](https://docs.conan.io/en/latest/reference/conanfile/methods.html#requirements) method:

{% highlight python %}

    def requirements(self):
        self.requires.add('zlib/1.2.11@conan/stable')
        if self.options.jpeg:
            self.requires.add('libjpeg/9c@bincrafters/stable')
        if self.options.tiff:
            self.requires.add('libtiff/4.0.9@bincrafters/stable')
        if self.options.webp:
            self.requires.add('libwebp/1.0.0@bincrafters/stable')
        if self.options.png:
            self.requires.add('libpng/1.6.34@bincrafters/stable')
        if self.options.jasper:
            self.requires.add('jasper/2.0.14@conan/stable')
        if self.options.openexr:
            self.requires.add('openexr/2.3.0@conan/stable')

{% endhighlight %}

The code above adds conditional requirements based on options recipe declares:

{% highlight python %}

    options = {"shared": [True, False],
               "fPIC": [True, False],
               "contrib": [True, False],
               "jpeg": [True, False],
               "tiff": [True, False],
               "webp": [True, False],
               "png": [True, False],
               "jasper": [True, False],
               "openexr": [True, False],
               "gtk": [None, 2, 3]}
    default_options = {"shared": False,
                       "fPIC": True,
                       "contrib": False,
                       "jpeg": True,
                       "tiff": True,
                       "webp": True,
                       "png": True,
                       "jasper": True,
                       "openexr": True,
                       "gtk": 3}

{% endhighlight %}

The technique mentioned is documented in the article [Mastering Conan: Conditional settings, options, and requirements](https://docs.conan.io/en/latest/mastering/conditional.html).

As we're now using 3rd-party libraries from Conan, there is no point to keep the *3rdparty* directory of OpenCV sources, so we remove within [source](https://docs.conan.io/en/latest/reference/conanfile/methods.html#source) method:

{% highlight python %}

    shutil.rmtree(os.path.join(self._source_subfolder, '3rdparty'))

{% endhighlight %}

Why is it important? There are a few advantages:

* Consumers have better control over dependencies, e.g. they may easily upgrade or downgrade 3rd-party dependencies of OpenCV, like libpng, just by editing their *conanfile.txt*.
* It saves build times, as you don't need to build rebuild these dependencies if you change some OpenCV options.
* It reduces the size of packages.
* It helps to avoid linking or runtime errors, because if two libraries contain libpng sources (e.g. OpenCV and [wxWidgets](https://www.wxwidgets.org/)), and you link both into your projects, you may run into issues extremely hard to debug.

Finally, these options are passed to the build system (CMake in case of OpenCV):

{% highlight python %}

        cmake.definitions['WITH_JPEG'] = self.options.jpeg
        cmake.definitions['WITH_TIFF'] = self.options.tiff
        cmake.definitions['WITH_WEBP'] = self.options.webp
        cmake.definitions['WITH_PNG'] = self.options.png
        cmake.definitions['WITH_JASPER'] = self.options.jasper
        cmake.definitions['WITH_OPENEXR'] = self.options.openexr

{% endhighlight %}

We also always disable 3rd-party libraries to be built:

{% highlight python %}

        # disable builds for all 3rd-party components, use libraries from conan only
        cmake.definitions['BUILD_ZLIB'] = False
        cmake.definitions['BUILD_TIFF'] = False
        cmake.definitions['BUILD_JASPER'] = False
        cmake.definitions['BUILD_JPEG'] = False
        cmake.definitions['BUILD_PNG'] = False
        cmake.definitions['BUILD_OPENEXR'] = False
        cmake.definitions['BUILD_WEBP'] = False
        cmake.definitions['BUILD_TBB'] = False
        cmake.definitions['BUILD_IPP_IW'] = False
        cmake.definitions['BUILD_ITT'] = False
        cmake.definitions['BUILD_JPEG_TURBO_DISABLE'] = True

{% endhighlight %}

As they are used from Conan packages, there is no point to build them from the source in the context of OpenCV.

### patching for OpenEXR

CMake uses so-called [find-modules](https://cmake.org/cmake/help/v3.8/manual/cmake-modules.7.html) to locate various libraries. There are plenty of them for most popular libraries, however, many are still missing, and OpenEXR is one of them.

OpenCV has a [collection](https://github.com/opencv/opencv/tree/master/cmake) of its own find-modules, and there is one for OpenEXR - [OpenCVFindOpenEXR](https://github.com/opencv/opencv/blob/master/cmake/OpenCVFindOpenEXR.cmake).

However, OpenCV's module for OpenEXR suffers from several issues:

* It hard-codes *OPENEXR_ROOT* variable to *C:\deploy* on Windows, so it's unable to find OpenEXR in unusual locations, such as Conan cache directory.
* It always prefers looking for libraries in system locations (e.g. */usr/lib*), and *OPENEXR_ROOT* has very least priority.
* It doesn't consider all possible names for OpenEXR libraries. For instance, it always looks for the *IlmImf*, while library might be named *IlmImf-2_3_s*.

This is unfortunate. But in reality, very often Conan recipes need to workaround various limitations of build scripts. The sad truth is that many libraries were designed without package management use-case in mind, hard-coding paths, library names, versions, and other important things. This makes the life of packager a bit harder, but as the popularity of package management in C++ world grows, we hope such things happen less frequently.

Anyway, currently there is a code in the recipe to remove hard-coded things:

{% highlight python %}

        # allow to find conan-supplied OpenEXR
        if self.options.openexr:
            find_openexr = os.path.join(self._source_subfolder, 'cmake', 'OpenCVFindOpenEXR.cmake')
            tools.replace_in_file(find_openexr,
                                  r'SET(OPENEXR_ROOT "C:/Deploy" CACHE STRING "Path to the OpenEXR \"Deploy\" folder")',
                                  '')
            tools.replace_in_file(find_openexr, r'set(OPENEXR_ROOT "")', '')
            tools.replace_in_file(find_openexr, 'SET(OPENEXR_LIBSEARCH_SUFFIXES x64/Release x64 x64/Debug)', '')
            tools.replace_in_file(find_openexr, 'SET(OPENEXR_LIBSEARCH_SUFFIXES Win32/Release Win32 Win32/Debug)',
                                  '')

{% endhighlight %}

We use [tools.replace_in_file](https://docs.conan.io/en/latest/reference/tools.html?highlight=replace_in_file#tools-replace-in-file) here to remove several lines of CMake code. In more complex cases, [tools.patch](https://docs.conan.io/en/latest/reference/tools.html?highlight=patch#tools-patch) helper might be used instead.

For our luck, OpenEXR is the only case which requires modifications, other libraries (libpng, libjpeg, etc.) are using standard CMake find-modules, and they don't have limitations described above.

### OpenCV contrib

In addition to the built-in features, OpenCV has a collection of extra modules, called [OpenCV contrib](https://github.com/opencv/opencv_contrib). Currently, it has about 100 additional modules! Just to name a few:

* [Face Analysis](https://docs.opencv.org/4.0.1/db/d7c/group__face.html).
* [Optical Flow](https://docs.opencv.org/4.0.1/d2/d84/group__optflow.html).
* [Image Registration](https://docs.opencv.org/4.0.1/db/d61/group__reg.html).

By default, our package doesn't have OpenCV contrib modules enabled. But you may easily have them available by passing *opencv:contrib* option:

{% highlight conf %}

[requires]
opencv/4.0.1@conan/stable

[options]
opencv:contrib=True

[generators]
cmake

{% endhighlight %}

From the recipe point of view, contrib adds additional source tarball:

{% highlight python %}

    tools.get("https://github.com/opencv/opencv_contrib/archive/%s.zip" % self.version)
    os.rename('opencv_contrib-%s' % self.version, 'contrib')

{% endhighlight %}

And the option to toggle contrib is passed to the build system (CMake):

{% highlight python %}

        if self.options.contrib:
            cmake.definitions['OPENCV_EXTRA_MODULES_PATH'] = os.path.join(self.build_folder, 'contrib', 'modules')

{% endhighlight %}

[OPENCV_EXTRA_MODULES_PATH](https://github.com/opencv/opencv_contrib) is a CMake variable to specify additional OpenCV modules to be built, and we pass the path to the contrib in this case.

### System Requirements

Sometimes recipe may need to depend on libraries provided by the system package manager, such as [apt](https://packages.qa.debian.org/a/apt.html), [yum](http://yum.baseurl.org/) or [pacman](https://www.archlinux.org/pacman/), instead of libraries provided by Conan. It's usually needed for some low-level things, like [VDPAU](https://www.freedesktop.org/wiki/Software/VDPAU/) or [VAAPI](https://freedesktop.org/wiki/Software/vaapi/), but in case of OpenCV, it may depend on [GTK](https://www.gtk.org/).

Unfortunately, System Requirements are something extremely hard to maintain, so our recommendation is to avoid them, if possible. System Requirements have the following limitations, which makes them hard to scale:

* Recipe has to use its own branch for each package manager, e.g. *yum* and *apt* will have different names for same libraries/packages (*gtk2-devel* vs *libgtk2.0-dev*).
* Sometimes package names differ for various Linux distributions, even if they use the same package manager (e.g. [Fedora](https://getfedora.org/) and [CentOS](https://www.centos.org/) both use *yum*, but have different package name for [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/)).
* Package names may differ even for minor versions for the same Linux distro! (e.g. [Ubuntu 16.04](http://releases.ubuntu.com/16.04/) vs [Ubuntu 12.04](http://releases.ubuntu.com/12.04/)).
* Names of architectures for packages also differ, e.g. *yum* uses *i686* and *x86_64* suffixes, while *apt* uses *i386* and *amd64*.

For instance, we're currently using the following code in order to just specify GTK dependency:

{% highlight python %}

    def system_requirements(self):
        if self.settings.os == 'Linux' and tools.os_info.is_linux:
            if tools.os_info.with_apt:
                installer = tools.SystemPackageTool()
                arch_suffix = ''
                if self.settings.arch == 'x86':
                    arch_suffix = ':i386'
                elif self.settings.arch == 'x86_64':
                    arch_suffix = ':amd64'
                packages = []
                if self.options.gtk == 2:
                    packages.append('libgtk2.0-dev%s' % arch_suffix)
                elif self.options.gtk == 3:
                    packages.append('libgtk-3-dev%s' % arch_suffix)
                for package in packages:
                    installer.install(package)
            elif tools.os_info.with_yum:
                installer = tools.SystemPackageTool()
                arch_suffix = ''
                if self.settings.arch == 'x86':
                    arch_suffix = '.i686'
                elif self.settings.arch == 'x86_64':
                    arch_suffix = '.x86_64'
                packages = []
                if self.options.gtk == 2:
                    packages.append('gtk2-devel%s' % arch_suffix)
                elif self.options.gtk == 3:
                    packages.append('gtk3-devel%s' % arch_suffix)
                for package in packages:
                    installer.install(package)

{% endhighlight %}

This appears very excessive, isn't it? But if we decide to add support for more Linux distributions or more architectures, the amount of code will grow extremely fast.

As you can see, Conan uses [system_requirements](https://docs.conan.io/en/latest/reference/conanfile/methods.html?highlight=system_requirements#system-requirements) method in order to specify system-specific requirements, and there is also [SystemPackageTool](https://docs.conan.io/en/latest/reference/tools.html?highlight=systempackagetool#tools-osinfo-and-tools-systempackagetool) helper which automates the installation of packages. Under the hood, it invokes commands specific to the given package manager, like *apt-get install -y libgtk2.0-dev:i386*.

### Package info

There are some platform-specific system libraries, which have to be explicitly specified in the [package_info](https://docs.conan.io/en/latest/reference/conanfile/methods.html?highlight=package_info#package-info) method of conanfile:

* [pthread](http://man7.org/linux/man-pages/man7/pthreads.7.html), or POSIX Threads, provide multi-threading support for POSIX-compatible systems.
* [libm](https://www.gnu.org/software/libc/manual/html_node/Mathematics.html), C mathematical functions.
* [libdl](http://refspecs.linuxfoundation.org/LSB_2.0.1/LSB-Core/LSB-Core/app-libdl.html), for dynamic linking support.
* [Vfw32](https://docs.microsoft.com/en-us/windows/desktop/api/_multimedia/), or [Video for Windows](https://docs.microsoft.com/en-us/windows/desktop/multimedia/video-for-windows), and ancient technology from Windows 95 timeline for video playback, which is still in use.

Also, especially for Apple macOS, there are a bunch of frameworks in use. In order to specify frameworks, we use the following code:

{% highlight python %}

            for framework in ['OpenCL',
                              'Accelerate',
                              'CoreMedia',
                              'CoreVideo',
                              'CoreGraphics',
                              'AVFoundation',
                              'QuartzCore',
                              'Cocoa']:
                self.cpp_info.exelinkflags.append('-framework %s' % framework)
            self.cpp_info.sharedlinkflags = self.cpp_info.exelinkflags

{% endhighlight %}

as they are linked differently from libraries. Mostly, these frameworks are for multimedia-related technologies available on Apple platforms.

### Future: other options and dependencies

As stated previously, OpenCV is a very large and complex library, and it really has tons of options. And currently, our Conan package doesn't support them all. You may check the list of available options on their [GitHub repository](https://github.com/opencv/opencv/blob/4.0.1/CMakeLists.txt#L208). It literally takes almost 300 lines of CMake code just to declare all these options! This is something that actually hard to model in one shot. Moreover, most of the options depend on other 3rd-party libraries.

Just a few examples:

* [Google Protocol Buffers](https://developers.google.com/protocol-buffers/) might be used to read data from [Caffe](http://caffe.berkeleyvision.org/) networks.
* [OpenCL](https://www.khronos.org/opencl/) and [CUDA](https://developer.nvidia.com/cuda-zone) might be used to accelerate OpenCV algorithms on [heterogeneous systems](https://en.wikipedia.org/wiki/Heterogeneous_System_Architecture).
* [FFMPEG](https://github.com/bincrafters/conan-ffmpeg) and [GStreamer](https://gstreamer.freedesktop.org/) might be used to read and write video files.

#### Google Protocol Buffers (Protobuf)

OpenCV module [DNN](https://docs.opencv.org/4.0.1/d6/d0f/group__dnn.html) (Deep Neural Network) may be compiled with [Google Protobuf](https://developers.google.com/protocol-buffers/) support.

We're currently actively working on adding Google Protobuf [recipe](https://github.com/bincrafters/conan-protobuf) accepted into [conan-center](https://bintray.com/conan-community/conan/opencv%3Aconan). The library is itself challenging, especially for the cross-compilation use case. As soon as it's accepted, we are going to enable our OpenCV package to use Protocol Buffers by default.

#### OpenCL

OpenCV may also be configured to use [OpenCL](https://www.khronos.org/opencl/), however, its support is very different across various platforms, for instance:

* MacOS has built-in OpenCL support by providing *OpenCL.framework*.
* Linux needs installation of development packages (e.g. [ocl-icd-opencl-dev](https://packages.debian.org/stretch/ocl-icd-opencl-dev) on Debian systems).
* Windows needs SDK package provided by one of the vendors (e.g. from [Intel](https://software.intel.com/en-us/intel-opencl-support) or from [nVidia](https://developer.nvidia.com/cuda-toolkit)).
* Android also needs SDK package from vendors (e.g. [Mali](https://developer.arm.com/products/software/mali-sdks)).

Therefore, in order to provide OpenCL support for OpenCV package, we need to develop a way how to model such kind of dependency. Probably, we may decide to add a new feature to support so-called [virtual packages](https://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics.en.html#s-virtual).

#### CUDA

Similar story to OpenCL, however, there is only one vendor, obviously - the building of the [CUDA](https://developer.nvidia.com/cuda-zone) applications requires [nVidia CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit). The toolkit is pretty large, and contains CUDA compiler, in addition to libraries and headers. We either have to require the user to have CUDA installed on the machine during the build, or provide a package for the toolkit.

#### FFMPEG

It's common to use OpenCV not just for image processing, but for video processing as well, for example for watermarking, green screen replacement, etc. In order to enable OpenCV to read or write video files, [ffmpeg](https://www.ffmpeg.org/) library might be used by OpenCV [Video I/O](https://docs.opencv.org/4.0.1/d0/da7/videoio_overview.html) module. However, FFmpeg itself is probably equally complex to OpenCV (its [configure script](https://github.com/FFmpeg/FFmpeg/blob/master/configure#L65) has about 400 lines just to declare options available!), so its packaging is challenging as well. Hopefully, it will be available in [conan-center](https://bintray.com/conan-community/conan/opencv%3Aconan) in the near future, so OpenCV users will be able to capture and write video streams.

For instance, current [recipe](https://github.com/bincrafters/conan-ffmpeg) supports various encoding libraries (conan-packaged as well): [libx264](https://www.videolan.org/developers/x264.html), [libx265](http://x265.org/), [libvpx](https://www.webmproject.org/vp9/), [libopenh264](https://www.openh264.org/), etc. And we hope list will grow significantly, adding modern formats like [libaom](https://aomedia.googlesource.com/aom/) (also knowns as AV1).

Also, FFmpeg may use CUDA and OpenCL to accelerate video encoding and filtering as well, so it will also benefit from addressing CUDA and OpenCL support by Conan.

#### GStreamer

We're currently working on packaging [GStramer](https://gstreamer.freedesktop.org/) libraries. Similarly to FFMPEG and Google Protobuf, GStreamer itself is pretty large and requires few other libraries to be packaged first, such as [libffi](https://sourceware.org/libffi/) and [GLib](https://developer.gnome.org/glib/stable/). Along with FFMPEG, the GStreamer is one of the top-requested libraries to be packaged in Conan, and it's obviously on our radar.

### Lessons & advises

As the packaging of OpenCV was a huge task which consumed lots of time, we have learned some lessons we want to share for packages:

* Use dynamic [requirements](https://docs.conan.io/en/latest/reference/conanfile/methods.html#requirements) for optional dependencies.
* Use [build helpers](https://docs.conan.io/en/latest/reference/build_helpers.html), if possible, they automate many things and allow to keep recipe code short and clean.
* [patch_config_paths](https://docs.conan.io/en/latest/reference/build_helpers/cmake.html?highlight=patch_config_paths) might be required for CMake libraries.
* Use exelinkflags/sharedlinkflags to specify [Apple frameworks](https://docs.conan.io/en/latest/howtos/link_apple_framework.html).
* Avoid System Requirements, if possible, package libraries with Conan instead.

### Conclusion

Although OpenCV packages are available in [conan-center](https://bintray.com/conan-community/conan/opencv%3Aconan), they aren't complete in term of supported options and dependencies, and we are looking into adding more in small iterations, in order to satisfy more use-cases and support more features.

But we still encourage users to try our OpenCV packages, and report any issues and feature requests to our [GitHub](https://github.com/conan-community/community/issues). We will be adding missing pieces prioritizing them according to the feedback.

In general, Conan is already flexible and mature enough to handle packaging of very complex libraries, such as OpenCV, and conanfile may handle all requirements, options, patching, etc. Besides that, Conan provides some tools and helpers that make life of packages much easier, saving time.

Conan also clearly separates logic within conanfile, making it much easier to read and write recipe code, and Conan allows to debug recipe step by step, invoking its steps individuall, one by one: [source](https://docs.conan.io/en/latest/reference/commands/development/source.html) -> [build](https://docs.conan.io/en/latest/reference/commands/development/build.html) -> [package](https://docs.conan.io/en/latest/reference/commands/development/package.html) -> [test](https://docs.conan.io/en/latest/reference/commands/creator/test.html).
