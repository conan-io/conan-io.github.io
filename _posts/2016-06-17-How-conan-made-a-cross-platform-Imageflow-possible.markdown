---
layout: post
comments: true
# other options
---

<h2 class="section-heading">Imageflow: modern, faster and safer image handling for web servers</h2>

[Imageflow](https://www.imageflow.io/) is an exciting new project that can provide speedups
of up to 17x with respect to ImageMagick, while having a fraction of the attack surface area. [The many recent vulnerabilities in 
ImageMagick](https://www.cvedetails.com/vulnerability-list/vendor_id-1749/Imagemagick.html) have shown the high risk involved in using desktop toolkits on the server.

The ubiquitous need for typical web server
operations such as scaling, editing and optimizing images requires a much more focused technology, with
appropiate interfaces (JSON, REST). Imageflow fills these requirements.

[![Imageflow]({{ site.url }}/assets/imageflow.jpg)](https://www.imageflow.io/)

Imageflow is being created by [Nathanael Jones](http://www.nathanaeljones.com/), the author of [ImageResizer](https://imageresizing.net/),
a huge success, so the track record in the field couldn't be better. The open-source project is currently being crowdfunded via a [Kickstarter campaign](https://www.kickstarter.com/projects/njones/imageflow-respect-the-pixels-a-secure-alt-to-image), 
so if you or your company have a web site where image quality and speed plays an important role (like e-commerce), you
might seriously consider supporting it. Nathanael is offering a limited number of on-site consultation and integration support contracts as well (2 remain at the time of this writing).


<h2 class="section-heading">Imageflow dependencies</h2>

<h3 class="section-heading">Main dependencies</h3>

There are many good OSS imaging codecs, so imageflow uses them (and contributes improvements upstream). These include:

- [libpng](http://www.libpng.org). The canonical PNG library, used in Chrome and Firefox.
- [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo). The most popular fork of the libjpeg implementation,
  optimizing for speed with SIMD instructions, also used by Firefox, Chrome, and many linux distributions...
- [giflib](http://giflib.sourceforge.net/). The original reference library for gif format images, although giflib be replaced soon by a Rust implementation.
- [LittleCMS](http://www.littlecms.com/). The standard open source color management engine, with focus on accuracy and performance

We've also set up packaging for Cap'n Proto and Jansson, although usage of these hasn't yet landed in Imageflow's master branch.

<h3 class="section-heading">Test dependencies</h3>

To run automatic tests of the sofware, imageflow is using:

- [Catch](https://github.com/philsquared/Catch). A modern, header only C++ test framework by Phil Nash.
- [libcurl](https://curl.haxx.se/). Widely used library (and tool) to transfer data over the network over multiple protocols.
- [theft](https://github.com/silentbicycle/theft). A proprerty testing framework (think fuzzing), similar to QuickCheck.

<h3 class="section-heading">Transitive dependencies</h3>

The depedencies required above also have their own dependencies, even if not required explicitely by imageflow, they
are required in practice to build and test the project:

- [OpenSSL](https://www.openssl.org) the popular SSL implementation, is required by curl
- [ZLib](http://www.zlib.net) the ubiquos deflating/inflating library, is required by both by libpng and OPenSSL
- [Electric Fence](http://elinux.org/Electric_Fence) Utility (not available in Windows) that allows to detect memory related bugs. 
 

<h2 class="section-heading">Managing dependencies with Conan</h2>

The above are a few dependencies to handle, maybe it doesn't seem a huge number,
but there are many challenges involved:

- **Multiple build systems**. The source code has different build systems. Some of them use CMake,
  other use Makefiles, etc. Even OpenSSL require Perl in Windows to be built! It would be very difficult for
  a package manager based on a single build system to quickly provide all these dependencies.
- Different build systems for **different platforms**. It is not only that Win, Linux and Mac builds are required,
  is that many of those dependencies build differently in different OS. Some use CMake in Windows and Makefiles in
  Linux, for example.
- **Conditional dependencies**. We don't want to pull always all of the dependencies. Some of them are needed only
  for testing, while others, as *electric-fence* are not available (doesn't work) in Windows, for example. 
- Linking and **ABI incompatibilities**. Even in the same OS and using the same build system, the problem of
  incompatibilities is important. A C++ project built with a certain compiler version might not be linked in another
  version of the same compiler. Or maybe Debug builds are incompatible with Release builds (MSVC, I am looking at you).
- Build always **from source is slow**. Building always from source could solve the incompatibility problem, but then the
  builds become terribly slow. As we want to build and test Imageflow as quickly as possible in as many configurations as
  possible, this doesn't seem a solution. It scales very badly.


**Creating package dependencies**

Well, conan addresses all above challenges, and with the help of 1 conan developer, Imageflow was able to have 
in a very short time all its required depencies, already built for a large number of configurations (debug/release, 32/64, shared/static, 
different compilers and versions...):

> **The total number of package binaries for the dependencies used by Imageflow is over 1.000!** This only
> counts the current versions used by Imageflow. Those libraries may have other version packages in conan too.

Those packages were created quickly and easily by a single developer, and they are maintained using 
travis and appveyor continuous integration very easily. New versions of the libraries are converted into
packages sometimes with just a few minutes of work (and yes, maybe a long time build in CI).

A very important thing to note is that to create those packages conan did not require to fork any of the
original sources. It always retrieve from github, sourceforge or the original web site the sources to build
the packages.


**Building and testing the Imageflow project**

The simplest way to consume conan packages is via a ``conanfile.txt`` file. But in Imageflow we needed a bit more power
to express the conditional dependencies we had, so we used its python ``conanfile.py`` counterpart. It turns out that
using it, it also makes easier building and testing the project for many different configurations. Here is the
full ``conanfile.py`` required to build and test Imageflow. Read for example the ``config()`` method. Even if you
don't know conan, you might be able to understand its logic.

{% highlight python %}

from conans import ConanFile, CMake
import os

class ImageFlowConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    requires = "littlecms/2.7@lasote/stable", "libpng/1.6.21@lasote/stable", \
               "libjpeg-turbo/1.4.2@imazen/testing" , "giflib/5.1.3@lasote/stable"
    options = {"build_tests": [True, False], "profiling": [True, False], "coverage": [True, False]}
    generators = "cmake"
    default_options = "build_tests=True", "coverage=False", "profiling=False", "libjpeg-turbo:shared=False", \
                      "libpng:shared=False", "zlib:shared=False", "libcurl:shared=False", \
                      "OpenSSL:shared=True"

    def config(self):
        if self.settings.os != "Windows":  #giflib must be shared on windows?
            self.options["giflib"].shared = False

        if self.options.build_tests or self.options.profiling:
            self.requires("libcurl/7.47.1@lasote/stable")
            if self.settings.os == "Macos":
                self.options["libcurl"].darwin_ssl = False
                self.options["libcurl"].custom_cacert = True

        if self.options.build_tests:
            self.requires("catch/1.3.0@TyRoXx/stable")
            if self.settings.os != "Windows":  # Not supported in windows
                self.requires("theft/0.2.0@lasote/stable")
                self.requires("electric-fence/2.2.0@lasote/stable") ##### SLOWS IT DOWN

    def imports(self):
        self.copy("*.so", dst="bin", src="bin")  # From bin to bin
        self.copy("*.dll", dst="bin", src="bin")  # From bin to bin
        self.copy("*.dylib*", dst="bin", src="lib")  # From lib to bin
        self.copy("*cacert.pem", dst="bin")  # Allows use libcurl with https without problems - except on darwin
        self.copy("*cacert.pem", dst=".")  # Allows use libcurl with https without problems

    def build(self):
        if not os.path.exists("./build"):
            os.mkdir("./build")
        os.chdir("./build")
        cmake = CMake(self.settings)
        cmake_settings = ""
        if self.options.coverage:
            cmake_settings += " -DCOVERAGE=ON"
        if self.options.build_tests:
            cmake_settings += " -DENABLE_TEST=ON"
        if self.options.profiling:
            cmake_settings += " -DSKIP_LIBRARY=ON -DENABLE_TEST=OFF -DENABLE_PROFILING=ON"

        cmake_command = 'cmake "%s" %s %s' % (self.conanfile_directory, cmake.command_line, cmake_settings)
        cmake_build_command = 'cmake --build . %s' % cmake.build_config
        self.output.warn(cmake_command)
        self.run(cmake_command)
        self.output.warn(cmake_build_command)
        self.run(cmake_build_command)
        if self.options.build_tests:
            self.run('ctest -V -C Release')
{% endhighlight %}

Again, with the help of travis and appveyor, Imageflow is built and tested with several different compilers (clang, MSVC, gcc) and compiler versions in
Windows, Linux and Mac. You can check those builds, just go to the [imageflow github repository](https://github.com/imazen/imageflow)
and follow the travis and appveyor badges. Note the low build times, thanks that the build is using compiled binaries from conan.io.

<h2 class="section-heading">Conclusion</h2>

Conan has helped Imageflow to achieve cross-platform convenient builds, testing and CI in Windows, Linux and Mac. Creating a very
large number of package binaries for those dependencies was a relatively easy and fast track, and a single developer can do it
in a short time, and maintain thousands of binary packages without effort. Usage of those packages from Imageflow is also
intuitive and simple.

Conan will continue providing our support to this project:
- We have uploaded a testing package for the [pngquant](https://github.com/pornel/pngquant) library, which will probably be used by imageflow relatively soon.
- Recently, conan has helped providing Rust support for the command line, with conan Rust generator.
  This is an interesting topic, so we will write an specific post about this soon, as Imageflow melds more Rust and C11 code together. 

This will be our modest contribution to the next generation image processor for the web.

Don't forget to check out [Imageflow](https://www.imageflow.io) and [support the Kickstarter!](https://www.kickstarter.com/projects/njones/imageflow-respect-the-pixels-a-secure-alt-to-image)
