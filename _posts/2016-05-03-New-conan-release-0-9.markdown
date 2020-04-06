---
layout: post
comments: false
# other options
---

Welcome to conan 0.9 release! Here is a short summary of some relevant changes, though the release include
some other improvements and bug fixes, please [upgrade now!](https://www.conan.io/downloads) 


<h2 class="section-heading">Python 3 support</h2>

The whole codebase has been updated to provide Python 2 and 3 compatibility, for those of you running Python 3 installations.
Which, by the way, is becoming the de-facto standard in modern Linux distros, so it is a necessary investment towards a close future. Some things that you should take into account:

- Python 3 support is not so battle-tested as Python 2, so consider it "experimental". We have setup Continuous Integration (travis, appveyor) tests to run the full conan test suite with Python 3 too, so in a few iterations it will become stable too. Please use it and report any problems you might have.
- Package recipes, must be also Python2-3 compatible. If you are creating packages, all standard usage is already compatible. Maybe if you are using plain "print" stataments or "iteritems()" in some dict, could be a minor incompatibility but easily fixable. Package users using Python3 might report problems, please make sure to add the ``url`` field to your package recipes, pointing to your repository, to ease collaboration and sending issues.


<h2 class="section-heading">Create your own custom generators for your build systems and tools</h2>

Conan has some built-in generators, like cmake, xcode, visual_studio... If you are using a different one,
or those are not fine for your needs, you can easily create your own generator, and handle it as a regular
package: upload it (keep it private in your own in-house server if you want), evolve and version it, and
reference it in your projects ``[requires]``, so it is dynamically retrieved and used in your projects.

Generators are created just by extending the ``Generator`` class in a ``conanfile.py``, which is mostly
empty, just used to define the package, name, version and metadata. 

{% highlight python %}

from conans.model import Generator
from conans.paths import BUILD_INFO
from conans import ConanFile, CMake
        
class Premake(Generator):
    @property
    def filename(self):
        return "conanpremake.lua"

    @property
    def content(self):     
        ...
        return "\n".join(sections)
  
class MyCustomGeneratorPackage(ConanFile):
    name = "PremakeGen"
    version = "0.1"
    url = "https://github.com/memsharded/conan-premake"
    license = "MIT"
        
{% endhighlight %}

Using such generator in your project is simple, just add it to your ``conanfile``:

{% highlight text %}

[requires]
Hello/0.1@memsharded/testing
PremakeGen@0.1@memsharded/testing

[generators]
Premake

{% endhighlight %}

There is already a **Premake4** experimental generator using this feature, check [the PremakeGen package](https://www.conan.io/source/PremakeGen/0.1/memsharded/testing) 

If you want to know more about this feature, go to [the documentation](http://docs.conan.io/howtos/dyn_generators.html#dyn-generators)

<h2 class="section-heading">Conan test has been renamed to test_package, and changed layout</h2>

The name ``conan test`` was a bit misleading, as it could be associated to project unit or integration tests.
Those tests can be easily run if you want in your ``build()`` method, but the ``conan test`` was intended to
test the package, i.e. that it is correctly created, the headers are found, it links (the created library name
is the expected one) and execute a test project properly-

So both the command and the default folder have been renamed to ``conan test_package``. Backwards compatibility
is kept, using ``conan test`` and a ``test`` folder instead of a ``test_package`` folder keep working, but might
be eventually deprecated.

The test folder name can be customized with the ``conan test -f`` option

The layout of the temporary ``build`` folder has changed though. It is typicall to have a ``build`` folder in project roots for other purposes, like build scripts, and conan was using that name for temporary tests builds. 
Now ``conan test_package`` command creates the ``build`` folder inside the ``test_package`` folder, so no
conflicts are produced. This might require some changing to your test code, depending on how you are using it.
Automatic checks and warnings have been introduced, but just to summarize: You have to make sure that your test project is location independent (exactly the same as the main package), so both in-source and out-of-source builds are allowed, and the temporary build folder can be located anywhere.

That typically requires the ``conanfile.py`` **of the test project** making use of the ``conanfile_directory`` property.

{% highlight python %}

self.run('cmake %s %s' % (self.conanfile_directory, cmake.command_line))

{% endhighlight %}

And if you are using CMake, also make sure that the generated .cmake file location is in the ``${CMAKE_BINARY_DIR}``.

{% highlight cmake %}

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)

{% endhighlight %}



Once more, thanks a lot to all the community, for all the feedback and support received.  
Keep the good job!
