---
layout: post
comments: true
# other options
---

We have introduced big improvements in this release, from using isolated conan environments to a much better remote management and update functionality.

We have also addressed some issues with the libstdc++ ABI incompatibilities of the new gcc > 5.1 compilers, that now has two different implementations, the standard and a new C++11 one.

<h2 class="section-heading">C++ Projects</h2>

So when building a C++ library with a modern compiler (gcc>5.1), you can choose which one to use, and this setting has to be consistent with the overall project and build settings. 

So we have introduced this new settings in the defaults, you can check them in ~/.conan/settings.yml

{% highlight yaml %}

os: [Windows, Linux, Macos, Android, iOS]
arch: [x86, x86_64, armv6, armv7, armv7hf, armv8]
compiler:
    gcc:
        version: ["4.4", "4.5", "4.6", "4.7", "4.8", "4.9", "5.1", "5.2", "5.3"]
        libcxx: [libstdc++, libstdc++11]
    Visual Studio:
        runtime: [MD, MT, MTd, MDd]
        version: ["8", "9", "10", "11", "12", "14"]
    clang:
        version: ["3.3", "3.4", "3.5", "3.6", "3.7"]
        libcxx: [libstdc++, libstdc++11, libc++]
    apple-clang:
        version: ["5.0", "5.1", "6.0", "6.1", "7.0"]
        libcxx: [libstdc++, libc++]

build_type: [None, Debug, Release]


{% endhighlight %}

The default auto-detected setting in ~/.conan/conan.conf will be libcxx=libstdc++, irrespective of your compiler, as it is the most compatible one.

If you are building packages with gcc>5.1, you should regenerate your packages to account for this new settings. First, remove your existing ones, both locally and from the remotes:

{% highlight bash %}

$ conan remove MyPackage* -f 
$ conan remove MyPackage* -f -r=conan.io

{% endhighlight %}

Then, rebuild them. If you are using the test command, you could do:

{% highlight bash %}

$ conan test -s compiler=gcc -s compiler.version=5.3 -s compiler.libcxx=libstdc++11

{% endhighlight %}

Please note, that libstdc++ version depends not only on the compiler, but also on your distro. Old distros libstdc++ cannot upgrade without upgrading large part of the system, so it sticks to libstdc++, even if upgrading gcc to 5.2 or 5.3.

On the contrary, modern distros already feature a modern gcc with the latest libstdc++11 as default. These modern systems can opt to use the old libstdc++, so specifying -s compiler.libcxx=libstdc++ works on them, and the resulting package can be consumed easily by users in old distros too. Of course you can build both versions of the package, one with libstdc++11 and other with libstdc++.

The similar reasoning applies to libc++ in Apple Clang.


<h2 class="section-heading">C Projects</h2>


Finally, it is important to note, that pure C projects has nothing to do with this libcxx setting, so the correct approach for C projects is to specify that they do not depend on this settings, which can be done in their conanfile.py as:

{% highlight python %}

def config(self):
    del self.settings.compiler.libcxx

{% endhighlight %}

<h2 class="section-heading">Management of remotes</h2>

Remotes were previously defined in the ``conan.conf`` file, but now with the new remote command, they are stored in another file in your ``~/.conan/registry.txt`` that stores information both about remotes urls and packages. By default it is initialized to two remotes, the test local one (pointing to localhost, to test the conan_server), and the conan.io remote. If you have your own remote, you can just edit that file or better try the new ``conan remote`` command:

{% highlight bash %}

$ conan remote list
$ conan remote remove local 
$ conan remote add myremote http://myremote.url
$ conan remote list

{% endhighlight %}

<h2 class="section-heading">Automated package creation</h2>

Finally, if you are creating packages, you might be interested in checking out latest version of [conan-package-tools](https://github.com/conan-io/conan-package-tools), some utilities for building many configurations in Win, Linux, OSX in travis-ci, appveyor Continuous Integration systems. We use them to create hundreds of packages for many libraries by just pushing to github.


