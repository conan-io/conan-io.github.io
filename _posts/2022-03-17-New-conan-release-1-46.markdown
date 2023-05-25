---
layout: post
comments: false
title: "Conan 1.46: New XcodeToolchain and XcodeBuild tools, improved conf system, new helpers for Git."
description: "The new version features include new XcodeToolchain and XcodeBuild, improved conf system, new helpers for Git and much more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.46 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.46 Conan C/C++ package manager version",
 "image": "https://docs.conan.io/en/latest/_images/frogarian.png",
 "author": "Conan Team", 
 "genre": "C/C++", 
 "keywords": "c c++ package manager conan release", 
 "publisher": {
    "@type": "Organization",
    "name": "Conan.io",
    "logo": {
      "@type": "ImageObject",
      "url": "https://media.jfrog.com/wp-content/uploads/2017/07/20134853/conan-logo-text.svg"
    }
},
 "datePublished": "2022-03-17",
 "description": "New XcodeToolchain and XcodeBuild tools, improved conf system, new helpers for Git."
 }
</script>


We are pleased to announce that Conan 1.46 has been released and brings some significant
new features and bug fixes. We have improved Xcode support by adding a new
[XcodeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodetoolchain)
generator and a
[XcodeBuild](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodebuild)
build helper tool that complement the
[XcodeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodedeps)
generator introduced in [Conan
1.42](https://blog.conan.io/2021/11/10/New-conan-release-1-42.html). Also, the Conan
[configuration
system](https://docs.conan.io/en/latest/reference/config_files/global_conf.html) has been
significantly improved, allowing a more powerful manipulation of the Conan "conf" in
profiles and recipes and adding *jinja2* template syntax support. Also, we added new
helpers for Git, for direct use in the `export()` method to capture git URL and commit,
and in the `source()` method to clone and checkout a git repository.

## New XcodeBuild and XcodeToolchain tools

Now you can use **XcodeToolchain** and **XcodeBuild** new helpers, along with
**XcodeDeps**, to build your Xcode projects in Conan recipes. Let’s see how to create
a package that uses the Xcode build system. Imagine you have generated a simple "hello
world" library project in Xcode that you want to package with Conan and it has this
structure:

```
├── HelloLibrary.xcodeproj
└── src
    ├── hello.cpp
    └── hello.hpp
```

You could easily create a Conan package for this library using a `conanfile.py` like this
one that uses **XcodeBuild** for building the library and **XcodeToolchain** to pass
information from the Conan settings to the Xcode build system:

```python

import os
from conan import ConanFile
from conan.tools.apple import XcodeBuild
from conan.tools.files import copy

class HelloLib(ConanFile):
    name = "hello"
    version = "1.0"
    settings = "os", "compiler", "build_type", "arch"
    generators = "XcodeToolchain"
    exports_sources = "HelloLibrary.xcodeproj/*", "src/*"

    def build(self):
        xcode = XcodeBuild(self)
        xcode.build("HelloLibrary.xcodeproj")

    def package(self):
        copy(self, "*/libhello.a", src=self.build_folder, 
             dst=os.path.join(self.package_folder, "lib"), 
             keep_path=False)
        copy(self, "src/hello.hpp", src=self.build_folder, 
             dst=os.path.join(self.package_folder, "lib"), 
             keep_path=False)

    def package_info(self):
        self.cpp_info.libs = ["hello"]
```

Before creating the package, you have to add the Conan generated **.xcconfig** files to
the Xcode project. Let's generate them for **Release** and **Debug** configurations:

```bash
$ conan install . -s build_type=Release
$ conan install . -s build_type=Debug
```

Add the generated **.xcconfig** files to the Xcode project, and in the Info/Configurations
section, choose **conan_config** for both configurations

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2022-03-17/conan_config_xcode.png" align="center" alt="Set configuration files for Debug and Release"/>
</p>

Now, you can create the library for both **Debug** and **Release** configurations:

```bash
$ conan create . -s build_type=Debug
$ conan create . -s build_type=Release
```

When Conan executes the ``build()`` method, the **XcodeBuild** helper invokes the Xcode
build system to build the library. Please check the documentation for the full reference
of
[XcodeToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodetoolchain),
[XcodeBuild](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodebuild)
and
[XcodeDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/apple.html#xcodedeps).

## Improved "conf" system

There are a couple of things that have been improved in the Conan configuration system:

* **Support for *jinja2* templates** in the `global.conf` configuration file. This can be
  useful for example to set the parallel build jobs number to a value defined by the
  system configuration:

        {% raw %}
        ...
        # Using all the cores automatically
        tools.build:jobs={{os.cpu_count()}}
        ...
        {% endraw %}


Python `os` and `system` modules are available in the template context.

* **Support for different data types** in the configuration. Now you can use Python data types
  when setting configuration values. Conan will interpret those using the Python built-in
  `eval()` function. You can use strings, booleans, integers, lists and dictionaries. For example:

```bash
# String
tools.microsoft.msbuild:verbosity=Diagnostic
# Boolean
tools.system.package_manager:sudo=True
# Integer
tools.microsoft.msbuild:max_cpu_count=2
# List of values
user.myconf.build:listvalue=["value1", "value2"]
# Dictionary
tools.microsoft.msbuildtoolchain:compile_options={"ExceptionHandling": "Async"}
```

* **New operators for configuration values in profiles**. You can use those to prepend (`=+`), append (`+=`)
  or reset (`=!`) configuration values inside the `[conf]` section of your profiles.

```
[settings]
...

[conf]
# Define the value => ["value1"]
user.myconf.build:listvalue=["value1"]

# Append the value ["value2"] => ["value1", "value2"]
user.myconf.build:listvalue+=["value2"]

# Prepend the value ["value0"] => ["value0", "value1", "value2"]
user.myconf.build:listvalue=+["value0"]

# Unset the value
user.myconf.build:listvalue=!
```

* **New methods available in the ``conf_info``** object to manipulate configuration values in
  **recipes**. You can use different methods to get, define or manipulate configuration
  values:

```python
import os
from conans import ConanFile

class Pkg(ConanFile):
    name = "pkg"

    def package_info(self):
        # Setting values
        self.conf_info.define("tools.microsoft.msbuild:verbosity", "Diagnostic")
        # Getting values
        self.conf_info.get("tools.microsoft.msbuild:verbosity")  # == "Diagnostic"
        # Modifying configuration list-like values
        self.conf_info.append("user.myconf.build:listvalue", "value1")
```

For the full reference of available methods, please [check the Conan documentation](https://docs.conan.io/en/latest/reference/config_files/global_conf.html).


## New conan.tools.scm.Git tool

There is a [new tool
available](https://docs.conan.io/en/latest/reference/conanfile/tools/scm/git.html) in
Conan to manage git repositories in the `conan.tools.scm module`. With this tool, recipes
can add the same functionality that the [scm
feature](https://docs.conan.io/en/latest/creating_packages/package_repo.html#scm-feature)
provided but more flexibly and explicitly (note that the scm feature will be
removed in Conan 2.0).

Let's see an example of how to use the new helper. We can take the previous recipe we used
to define our Xcode package that had this structure:

```
├── conanfile.py
├── HelloLibrary.xcodeproj
└── src
    ├── hello.cpp
    └── hello.hpp
```

We will change the recipe to get the sources from a git repository. The
new recipe could look like this:

```python

import os
from conan import ConanFile
from conan.tools.apple import XcodeBuild
from conan.tools.files import copy
from conan.tools.scm import Git
from conan.tools.files import update_conandata


class HelloLib(ConanFile):

    ...

    def layout(self):
        self.folders.source = "."

    def export(self):
        git = Git(self, self.recipe_folder)
        scm_url, scm_commit = git.get_url_and_commit()
        # we store the current URL and commit in conandata.yml
        update_conandata(self, {"sources": {"commit": scm_commit, "url": scm_url}})

    def source(self):
        # we recover the saved URL and commit from conandata.yml
        git = Git(self)
        sources = self.conan_data["sources"]
        # get the sources from the URL and commit
        git.clone(url=sources["url"], target=".")
        git.checkout(commit=sources["commit"])

    def build(self):
        xcode = XcodeBuild(self)
        xcode.build("HelloLibrary.xcodeproj")

    ...
```

The most important parts are defined in the `export()` and `source()` methods of the conanfile:

* In the `exports()` method we use the `get_url_and_commit()` to get the current *commit*
  and *URL* for the git repository. Then the `update_conandata()` helper is used to save
  this information inside the `conandata.yml` file in the cache along with the recipe.

* In the `source()` method we retrieve the information we stored in the
  `conandata.yml`file to clone the repository *URL* and checkout the *commit*.

As you can see this way of interacting with git repositories in Conan recipes is very
flexible and explicit. If you want to check the complete set of methods available for the
Git tool, please [check the Conan
documentation](https://docs.conan.io/en/latest/reference/conanfile/tools/scm/git.html).

---

<br>

Besides the items listed above,
there were some minor bug fixes you may wish to
read about. If so
please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#mar-2022) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
