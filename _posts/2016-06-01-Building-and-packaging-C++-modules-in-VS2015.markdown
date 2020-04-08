---
layout: post
comments: false
# other options
---

This post makes a brief introduction to the C++ modules (we wished C++17, but we will have to
wait). Modules have already been experimentally available in an early implementation in CLang, and now Microsoft is also
providing them in Visual Studio 2015. We will see their syntax and how to build them, as introduced in the 
[Visual Studio Blog](https://blogs.msdn.microsoft.com/vcblog/2015/12/03/c-modules-in-vs-2015-update-1/), and at the same time, we will show how to create
and consumes packages with C++ modules with conan C/C++ package manager. 


<h2 class="section-heading">A math C++ module library and package</h2>

First we will create a very simple math library with addition and multiplication functions,
which will be implemented in a module, called ``MyMath`` in a filename **mymath.ixx**. This extension
will be the one used to indicate C++ modules syntax:

{% highlight bash %}

module MyMath;
export double addition(double a, double b){
    return a + b;
}
export double multiplication(double y, int z){
    return y * z;
} 

{% endhighlight %}


Currently, building it requires command line invocation of the MSVC compiler **cl.exe**. This should be done
in the Visual Studio Prompt, or with the Visual Studio environment variables loaded. I usually work
in the *cmder* console in windows, so I prefer to load the environment variables:


{% highlight bash %}

$ call "%vs140comntools%../../VC/vcvarsall.bat"
$ cl /c /experimental:module mymath.ixx

{% endhighlight %}

When building this file, the compiler will generate the typical object code, and also an *IFC* file,
called "MyMath.ifc", which is the module interface description metadata. If we want to build an actual
static library, we can also do it in the command line:

{% highlight bash %}

$ lib mymath.obj -OUT:mymath.lib

{% endhighlight %}


From the user point of view, the *.ifc files can be handled and linked as if they were another libraries,
so all we have to do to create a conan package recipe for this code, just besides the *mymath.ixx* file: 

{% highlight python %}

from conans import ConanFile, CMake, tools
import os

class VSModulesConan(ConanFile):
    name = "MyMath"
    version = "0.1"
    license = "MIT"
    settings = "os", "compiler", "build_type", "arch"
    exports = "mymath.ixx"

    def build(self):
        param = "x86" if self.settings.arch == "x86" else "amd64"
        # Missing handling of build_type, but lets keep it simple
        vcvars = 'call "%%vs140comntools%%../../VC/vcvarsall.bat" %s' % param
        self.run('%s && cl /c /experimental:module mymath.ixx' % vcvars)
        self.run('%s && lib mymath.obj -OUT:mymath.lib' % vcvars)

    def package(self):
        self.copy("*.lib", "lib") 
        self.copy("*.ifc", "lib") 

    def package_info(self):
        self.cpp_info.libs = ["MyMath.ifc", "mymath.lib"]

{% endhighlight %}

We can now export the package to the conan local storage, so we can consume it from there:

{% highlight bash %}

$ conan export memsharded/testing

{% endhighlight %}

<h2 class="section-heading">Consuming the C++ module library</h2>

Now, in a different folder, we can create the consuming project, that will link against the library:

{% highlight cpp %}

#include <iostream>
import MyMath;

int main(){
    std::cout<<"MyModules\n";
    std::cout<<addition(5.1, 3.2)<<"\n";
    std::cout<<multiplication(2.0, 3)<<"\n";
    return 0;
} 
{% endhighlight %}

Building an executable from this code, the following commands would be required:

{% highlight bash %}

$ cl /EHsc /experimental:module /module:reference <libpath>/MyMath.ifc <libpath>/mymath.lib  main.cpp 

{% endhighlight %}

We need the library path, if we built the library manually, it would be the path when we generated it.
For conan packages, using a recipe to declare the dependency to the library package, and automating the 
build is very convenient, even if we are not creating a package for the consumer project. Remember, 
conan recipes are basically convenient python scripts:

{% highlight python %}
from conans import ConanFile, CMake, tools
import os

class VSModulesTestConan(ConanFile):
    license = "MIT"
    settings = "os", "compiler", "build_type", "arch"
    requires = "MyMath/0.1@memsharded/testing"

    def build(self):
        param = "x86" if self.settings.arch == "x86" else "amd64"
        vcvars = 'call "%%vs140comntools%%../../VC/vcvarsall.bat" %s' % param
        lib_path = self.deps_cpp_info.lib_paths[0]
        libs = " ".join("%s/%s" % (lib_path, lib) for lib in self.deps_cpp_info.libs)
        command = ('%s && cl /EHsc /experimental:module /module:reference %s %s/main.cpp '
                     % (vcvars, libs, self.conanfile_directory, ))
        self.run(command)
        
    def test(self):
        self.run("main")

{% endhighlight %}

With this recipe, installing the required dependencies (in our case, building the library with
the *MyMath* C++ module) is simple:

{% highlight bash %}

$ conan install --build

{% endhighlight %}

And then, building and executing the application:

{% highlight bash %}

$ conan build
$ main
MyModules
8.3
6

{% endhighlight %}


<h2 class="section-heading">Conclusion</h2>

If you want to test this quickly you might just:

{% highlight bash %}

$ git clone https://github.com/memsharded/vs_modules
$ cd vs_modules
$ conan export memsharded/testing
$ conan test_package 

{% endhighlight %}

We have always considered Windows as a first class citizen (as well as Linux and OSX) in conan, and we design, implement, test and
deploy with Windows users in mind (we also develop in Windows about 50% of our time).


We hope that this post proves it, as despite the early stage of the Visual Studio C++ modules build infrastructure (just the command line), conan package manager is able to both create and consume packages quite easily and in an intuitive way. This can be further simplified by improving the existing "Visual Studio" or "CMake" generators, once C++ modules have full support in the IDE and build system.

We are also very excited to be able to test this amazing feature in Visual Studio, undoubtly Microsoft is doing an amazing work on C++ lately,
and really looking forward to seeing C++ modules becoming mainstream.
