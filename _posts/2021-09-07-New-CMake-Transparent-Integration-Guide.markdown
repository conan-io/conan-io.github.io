---
layout: post 
comments: false 
title: "New CMake transparent integration guide"
meta_title: "A Single CMake integration is here"
meta_description: "In the roadmap to Conan 2.0 Conan introduced a new approach to create a Conan package based on CMake"
---


The CMake ecosystem has evolved a lot in the latest years and Conan has evolved together. Today we present 
a new unified way to create Conan packages with CMake. These new generators will be introduced soon in the 
[conan-center-index](https://github.com/conan-io/conan-center-index) too.

## A bit of history...

Back in these days when Conan started, the CMake approach was based on "global variables". The concepts of 
"modern CMake" and "Targets" didn't exist or at least the usage was very uncommon. 

We introduced first the `cmake` generator. The way to consume Conan packages with the 
[cmake](https://docs.conan.io/en/latest/reference/generators/cmake.html) generator was including a 
`conanbuildinfo.cmake` file and calling a `conan_basic_setup()` macro that adjusted the necessary CMake global variables 
to locate the include directories, the libraries to link with, and so on.

Later the [cmake_multi](https://docs.conan.io/en/latest/reference/generators/cmakemulti.html) generator gave support to 
multi-config projects like Visual Studio creating different `conanbuildinfo.cmake` files for `Release` or `Debug`.

The usage of `find_package()` in the CMake community was getting popular and we created the `cmake_find_package` 
generator. Conan generates different "FindXXX.cmake" modules for each dependency, so you 
could call `find_package(XXX)` and a 
[bunch of variables](https://docs.conan.io/en/latest/reference/generators/cmake_find_package.html#variables-in-find-pkg-name-cmake) 
were set, so you could link with your requirements. 

Soon, a new concept called "modern CMake" was raised. The "target approach" assumed that no more global variables should 
be used and all the information about a library or executable should be associated with a "target".  
So the `cmake_find_package_multi` was created based on targets, config files instead of modules, and also supporting 
multi-configuration projects, using 
[generator expressions](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html) to support it.

Finally, to support people packaging modules and config cmake files in the Conan packages we created the `cmake_paths` 
generator to point the `CMAKE_PREFIX_PATH` and `CMAKE_MODULE_PATH` to the packages.

Too many CMake integrations, right? 

## A new approach

We also missed something more. We wanted to have the same user experience and results when building a CMake project, 
no matter if doing a `conan create`, or developing a library calling "cmake" in the command line, or clicking a "build" 
button in the IDE.

We have introduced:

- The [CMakeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html) generator to 
  create a `conan_toolchain.cmake`. This file is saved after a "conan install" based on the settings and options and can 
  be used like any other CMake toolchain:

      {% highlight bash %}
      $ cmake . -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
      {% endhighlight %}

- The [CMakeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html) generator. To manage 
  the requirements and to generate the config and/or module files we created 

## How to migrate the recipes

When Conan 2.0 comes, the only CMake integration will be `CMakeToolchain` + `CMakeDeps`.
These generators are already supported in Conan 1.40 and we will keep improving them in every release. Also, these 
generators will be introduced as soon as possible in the recipes of 
[conan-center-index](https://github.com/conan-io/conan-center-index).

You can check the ["Creating packages getting started"](https://docs.conan.io/en/latest/creating_packages/getting_started.html).

### The "imports" namespace

The imports from the new integrations are in the "conan.tools" namespace, not in the "conan<i>s</i>".
    
{% highlight python %}
from conan.tools.cmake import CMakeToolchain, CMakeDeps
{% endhighlight %}

### The `generate()` method.
One important change in the "Conan 2.0 compatible recipes"  is the `generate()` method. 
This method is responsible for generating all the files needed so the build helpers (at the build() method) can 
almost directly call the build system without any calculation. That enables the user to get the same build results in a 
`conan create` or building in the command line.

{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMakeDeps, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    requires = "foo/1.0", "bar/2.0"

    def generate(self):
        tc = CMakeToolchain(self)
        # This writes the "conan_toolchain.cmake"
        tc.generate()
        
        deps = CMakeDeps(self)
        # This writes all the config files (xxx-config.cmake)
        deps.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    ...
      
{% endhighlight %}

The previous example, as we are not adjusting anything in the *CMakeToolchain* nor in the *CMakeDeps* could be 
simplified to:

{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    requires = "foo/1.0", "bar/2.0"
    generators = "CMakeToolchain", "CMakeDeps"

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    ...
      
{% endhighlight %}


### Customizing the "CMakeToolchain"
 
The most common code to change is the `.definitions` from the old `CMake()` build helper. 
You have to migrate to the toolchain as `.variables`:

From:

{% highlight python %}
from conans import ConanFile, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    options = {"xxx_feature_enabled": [True, False]}
    default_options = {"xxx_feature_enabled": False}
    requires = "foo/1.0", "bar/2.0"
    generators = "cmake_find_package", "cmake_find_package_multi", "cmake" # any of them

    def build(self):
        cmake = CMake(self)
        cmake.definitions["DISABLE_XXX_FEATURE"] = not self.options.xxx_feature_enabled
        cmake.configure()
        cmake.build()

    ...

{% endhighlight %}

To:

{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    options = {"xxx_feature_enabled": [True, False]}
    default_options = {"xxx_feature_enabled": False}
    requires = "foo/1.0", "bar/2.0"
    generators = "CMakeDeps"

    def generate(self):
      toolchain = CMakeToolchain(self)
      toolchain.variables["DISABLE_XXX_FEATURE"] = not self.options.xxx_feature_enabled
      toolchain.generate()

{% endhighlight %}

You can check the [full CMakeToolchain reference](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmaketoolchain.html)
to know all the customization.

### Customizing the "CMakeDeps"

- At the `generate()` method there are some new things you can now adjust, like adding new custom user CMake configurations 
  besides the standard ones (Release, Debug, etc)  with ``cmake.configurations`` and selecting the current configuration 
  with ``cmake.configuration``:

{% highlight python %}

    def generate(self):
        cmake = CMakeDeps(self)
        cmake.configurations.append("ReleaseShared")
        if self.options["hello"].shared:
            cmake.configuration = "ReleaseShared"
        cmake.generate()

{% endhighlight %}

Check the [full CMakeDeps reference](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html).

- At the `package_info()` method, there are several 
  [properties](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmakedeps.html#properties) you can 
  configure to indicate to the generator how to behave when a consumer uses it (having a requirement to your package).
  
  Here is an example:

{% highlight python %}

def package_info(self):
    ...
    # Generate MyFileName-config.cmake
    self.cpp_info.set_property("cmake_file_name", "MyFileName")
    # Foo:: namespace for the targets (Foo::Foo if no components)
    self.cpp_info.set_property("cmake_target_name", "Foo")
    # self.cpp_info.set_property("cmake_target_namespace", "Foo")  # This can be omitted as the value is the same

    # Foo::Var target name for the component "mycomponent"
    self.cpp_info.components["mycomponent"].set_property("cmake_target_name", "Var")
    # Automatically include the lib/mypkg.cmake file when calling find_package()
    self.cpp_info.components["mycomponent"].set_property("cmake_build_modules", [os.path.join("lib", "mypkg.cmake")])

    # Skip this package when generating the files for the whole dependency tree in the consumer
    # note: it will make useless the previous adjustements.
    # self.cpp_info.set_property("cmake_find_mode", "none")

    # Generate both MyFileName-config.cmake and FindMyFileName.cmake
    self.cpp_info.set_property("cmake_find_mode", "both")

{% endhighlight %}

###  The "CMake" build helper

To leverage the new `CMakeToolchain` and `CMakeDeps` you have to import the new 
[CMake](https://docs.conan.io/en/latest/reference/conanfile/tools/cmake/cmake.html) build helper from the new
"conan.tools.cmake" namespace.

This build helper does almost nothing, only calls `cmake` passing the `-DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake`.

As this build helper has no internal state anymore, there is an anti-pattern to avoid, keeping an instance 
of the build helper to use it in the `build()` method and later in the `package()` method. This is considered
an anti-pattern because keeping the state between the methods of the recipe might fail in the conan local methods like
``conan build`` + ``conan export-pkg`` where the execution is isolated:

From:

{% highlight python %}

from conans import ConanFile, CMake, tools

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    _cmake = None

    ...

    def _configure_cmake(self):
        if not hasattr(self, "_cmake"):
            self._cmake = CMake(self)
            self._cmake.definitions["tests"] = False
            self._cmake.configure()
        return self._cmake

    def build(self):
        cmake = self._configure_cmake()
        cmake.build()

    def package(self):
        cmake = self._configure_cmake()
        cmake.install()

    ...

{% endhighlight %}


To:

**conanfile.py**


{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"

    def generate(self):
        toolchain = CMakeToolchain(self)
        toolchain.variables["tests"] = False
        toolchain.generate()

    def build(self):
        cmake = CMake()
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake()
        cmake.install()

{% endhighlight %}



### The layout() method

You can declare a [layout()](https://docs.conan.io/en/latest/developing_packages/package_layout.html) method in the 
recipe to describe the package contents, not only the final package in the 
cache but also the package while developing. As the package will have the same structure in the cache and in our 
local directory, the recipe development becomes easier, even working with editable packages out of the box.

A couple of classic patterns you can avoid using the `layout()` method are the following:

From:

**conandata.yml**

     {% highlight yaml %}
...

patches:
  "0.1":
    - patch_file: "patches/001-fix-curl-define.patch"
      base_path: "source_subfolder"

    {% endhighlight %}

**conanfile.py**

    {% highlight python %}

from conans import ConanFile, CMake, tools

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    exports_sources = ["patches/**"]

    @property
    def _source_subfolder(self):
        return "source_subfolder"

    @property
    def _build_subfolder(self):
        return "build_subfolder"
    
    def source(self):
        tools.get("https://www.foo.bar/sources.tgz")
        extracted_dir = "{}-{}".format(self.name, self.version)
        os.rename(extracted_dir, self._source_subfolder)
        for patch in self.conan_data.get("patches", {}).get(self.version, []):
            tools.patch(**patch)
        
    def build(self):
        cmake = CMake()
        cmake.configure(build_folder=self._build_subfolder, source_folder=self._source_subfolder)
        cmake.build()
    ...

{% endhighlight %}


TO:

**conandata.yml**

     {% highlight yaml %}
...

patches:
  "0.1":
    - patch_file: "patches/001-fix-curl-define.patch"
    {% endhighlight %}

**conanfile.py**


{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake
from conan.tools.layout import cmake_layout
from conan.tools.files import apply_conandata_patches

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain"
    exports_sources = ["patches/**"]

    def layout(self):
        cmake_layout(self)
        self.folders.source = "{}-{}".format(self.name, self.version)

    def source(self):
        tools.get("https://www.foo.bar/sources.tgz")
        apply_conandata_patches(self)

    def build(self):
        cmake = CMake()
        cmake.configure()
        cmake.build()

{% endhighlight %}

In the previous example, we are using a predefined layout, the `cmake_layout`. You can 
[check here](https://docs.conan.io/en/latest/reference/conanfile/tools/layout.html#predefined-layouts) what is it doing and why. 
You can adjust any value after calling it to match your package structure.

Also the new tool 
[apply_conandata_patches](https://docs.conan.io/en/latest/reference/conanfile/tools/files.html#conan-tools-files-apply-conandata-patches) 
already knows where to locate the sources thanks to the ``layout`` so the _base_path_ can be omitted in the ``conandata.yml``.

Check the [layout()](https://docs.conan.io/en/latest/developing_packages/package_layout.html) to know more about it.


### Access to the dependencies

Sometimes, in a recipe, you need to access the dependencies to check something, typically the version and the root package folder.
Previously this could be done by accessing the _deps_cpp_info_ object in almost any method of the recipe. With the new model, 
the access to the dependencies should be done at the ``generate()`` and the ``validate()`` methods, using the 
new ``self.dependencies`` object. 

In the ``generate(self)``:

From:

{% highlight python %}
from conans import ConanFile, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    requires = "foo/1.0"

    def build(self):
        cmake = CMake(self)
        cmake.definitions["FOO_ROOT_DIR"] = self.deps_cpp_info["foo"].rootpath
        cmake.configure()
        cmake.build()

    ...

{% endhighlight %}

To:

{% highlight python %}

from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    requires = "foo/1.0", "bar/2.0"
    generators = "CMakeDeps"

    def generate(self):
        toolchain = CMakeToolchain(self)
        toolchain.variables["FOO_ROOT_DIR"] = self.dependencies["foo"].package_folder
      
        # Other possible dependencies access
        # info = self.dependencies["foo"].cpp_info
        # include_dirs = info.includedirs
        #
        # ref = self.dependencies["foo"].ref
        # version = ref.version

        toolchain.generate()

{% endhighlight %}

In the ``validate(self)`` method:

{% highlight python %}

from conans import ConanFile

class HelloConan(ConanFile):
    name = "hello"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    requires = "foo/1.0"

    def validate(self):
        if self.dependencies["foo"].ref.version == "1.2":
            raise ConanInvalidConfiguration("Foo 1.2 not supported")
        
        if self.dependencies["foo"].options.shared:
            raise ConanInvalidConfiguration("Foo shared not supported")


{% endhighlight %}

Read [here](https://docs.conan.io/en/latest/reference/conanfile/dependencies.html?highlight=dependencies#dependencies) the complete reference of the `self.dependencies`.

### Conclusion

In this blogpost we gave some highlights about the new CMake integration, but take into account that the ``layout()``, 
the ``generate()``, the ``self.dependencies``, the patches etc, are common to other integrations like the 
new [Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu.html), 
[MSBuild](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html) etc. 

With all these new improvements we want to provide syntax compatible recipes with the coming Conan 2.0 to 
help to migrate them before the release. 
We have been evolving and improving this model for some releases and these features should
not suffer important interface changes but please take into account that they are still experimental and subject to breaking changes
as noticed in the documentation.

You can check [here](https://docs.conan.io/en/latest/reference/conanfile/tools.html) the new `conan.tools` namespace to
learn about all the new integrations.
