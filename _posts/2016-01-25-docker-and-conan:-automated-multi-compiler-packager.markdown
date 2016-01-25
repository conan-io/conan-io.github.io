---
layout: post
comments: true
# other options
---

Conan can automate the package creation with any compiler that you have installed.
In **Windows**, it is very common to have two or more **Visual Studio** versions, tools like CMake will just use the Visual Studio specified by the user.

In Linux having **several versions of gcc** installed could be tricky, of course it's possible, but it's not as easy as Visual Studio versions in Windows.
In addition to this, our development machine usually has a lot of installed libraries that other developers may not have and may hide our real requirements.

So **Docker will help** us to create clean build environments with different compilers.

If you read the [Automatically creating and testing packages](http://docs.conan.io/en/latest/packaging/testing.html) you saw that you can test your conan package with the **conan test command** and a simple script like this:

**build.py**

{% highlight python %}
       ...
       system('conan test -s arch="x86" -s build_type="Release" -o mylib:shared=True')
       system('conan test -s arch="x86_64" -s build_type="Release" -o mylib:shared=True')
       system('conan test -s arch="x86" -s build_type="Debug" -o mylib:shared=True')
       system('conan test -s arch="x86_64" -s build_type="Debug" -o mylib:shared=True')
       system('conan test -s arch="x86" -s build_type="Release" -o mylib:shared=False')
       system('conan test -s arch="x86_64" -s build_type="Release" -o mylib:shared=False')
       system('conan test -s arch="x86" -s build_type="Debug" -o mylib:shared=False')
       system('conan test -s arch="x86_64" -s build_type="Debug" -o mylib:shared=False')
       ...
{% endhighlight %}

I thought that it would be great if I could execute the builds above for each gcc version that I want.

I prepared some [Dockerfiles](https://github.com/lasote/conan-docker-tools/blob/master/gcc_5.3/Dockerfile) for the different gcc version. I used official Ubuntu distributions.

 image            | gcc
------------------|----
 ubuntu:precise   | 4.6
 ubuntu:trusty    | 4.8
 ubuntu:vivid     | 4.9
 ubuntu:wily      | 5.2
 ubuntu:xenial    | 5.3

Then I uploaded the images to my [Dockerhub account](https://hub.docker.com/u/lasote/).

Remember from the [Automatically creating and testing packages](http://docs.conan.io/en/latest/packaging/testing.html) docs that your conan's package layout could be:


{% highlight python%}

+-- test
|   +-- conanfile.py
|   +-- test.cpp
|   +-- CMakeLists.txt
+-- conanfile.py
+-- build.py

{% endhighlight %}

This script will run a docker container for each gcc version and run the **build.py** script inside the container


{% highlight python %}
import os
import platform
import sys

if __name__ == "__main__":

    for gcc_version in ["4.6", "4.8", "4.9", "5.2", "5.3"]:
        image_name = "lasote/conangcc%s" % gcc_version.replace(".", "")
        os.system("sudo docker pull %s" % image_name)
        curdir = os.path.abspath(os.path.curdir)
        command = 'sudo docker run --rm  -v %s:/home/conan/project -v '\
                  '~/.conan/data:/home/conan/.conan/data -it %s /bin/sh -c '\
                  '"cd project && python build.py"' % (curdir, image_name)
        os.system(command)


{% endhighlight %}

In each container conan will detect the right compiler and compiler version. Your host computer conan local storage directory *~/.conan/data* is shared, so the containers will write the result in the same place.

When it finishes I can upload the generated packages to **conan.io** and make them available to the community:


{% highlight python %}
	conan upload mypackage/myversion@lasote/stable --all
{% endhighlight %}

This docker integration can also handle other compilers (such as clang) and other versions easily.

Currently this script is managed by a new tool, [**conan package tools**](https://github.com/conan-io/conan-package-tools) that provides CI (travis & appveyor) easy integration for remote and automated package generation (even with docker in travis ci), pagination, Visual Studio environment configuration and other features.

This tool could be very useful to library authors that wants to distribute the library binaries automatically. Authors can "push to master" to trigger the CI system and the upload the packages to "stable" channel automatically.

I will write new posts about this new tool ASAP.
