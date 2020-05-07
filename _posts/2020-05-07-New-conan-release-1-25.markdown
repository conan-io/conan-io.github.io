---
layout: post 
comments: false 
title: "Conan 1.25: New Cross-Build Variables, Additional Package Component Modeling, Automatic Config Install, Resumable Downloads, New Search Table"
---

Conan 1.25 follows up the previous release with another wave of progress related
to the new cross-build modeling. There are also some brand new features we are
excited about. Conan has learned to update it's configurations and profiles 
automatically by enabling the ability to schedule the 
`conan config install` command. We've also dramatically improved the output of
 `conan search` when the `--table` flag is passed. We've added support for 
 GCC 9.3, GCC 10, and Intel 9.1 compilers, and a substantial list of bug fixes. 

## Cross-Build Modeling + Context Modeling

In the previous release, we introduced the new abstraction of ["contexts"](https://docs.conan.io/en/latest/devtools/build_requires.html#build-and-host-contexts)
along with some core functionality surrounding them. However, the implementation 
was still not complete enough for recipes which need this functionality
to be refactored to use the new model.  In this release, we fill the gaps so 
that recipes can now start to take advantage of the new model.  
1.25 features two additional variables on the conanfile class which can be
accessed and evaluated by recipes:
- `settings_build`
- `settings_target`

These are in addition to the existing `settings` variable which still exists. 
The documentation goes into detail as to when these variables will exist and
how they are different. In summary, `settings` will represent the `host` 
settings during the builds of recipes in the `host` context. Otherwise it will
represent the `build` context. Also, it's not uncommon for cross-building 
cases when you're in one context and need to access the `settings` from the 
other context. For these cases, `settings_build` and `settings_target` enable 
access to both contexts under all circumstances.

Here is a graphic to help illustrate the variables and what their values
would be in different contexts:

<p class="centered">
    <a href="https://docs.conan.io/en/latest/devtools/build_requires.html#build-and-host-contexts"><img src="{{ site.url }}/assets/post_images/2020-05-07/cross-build-variables.png" align="center" alt="context example diagram"/></a>
</p>


## Additional Package Component Modeling

In this release, we make another large stride in the journey to provide
robust modeling of "components" within packages.  The modeling is declared
within the `cpp_info` object during the `package_info()` method.  

The CMake build system was the main driver for this new abstraction. Conan
has many generators which have continually tried to feed information into 
CMake in such a way that existing CMake files and user environments don't 
need to change.  This has been exceptionally hard, and one of the reasons
was CMake's unique concept of `Target::Component`.  Another reason was the 
mismatch of naming convention. CMake targets for open-source libraries 
typically had straighforward names (eg. `OpenSSL`), while Conan generators 
produce targets with a `CONAN_PKG` prefix to avoid conflict 
(eg. `CONAN_PKG::OpenSSL`).  

It turns out that a collision is desirable in many scenarios in order to 
achieve transparent integration for existing `CMakeLists.txt`.

So, with Conan 1.25, Conan packages for open-source libraries can be 
refactored to produce their targets with their well-known names, and those
targets can be further defined with their well-known components. This will
take place in the coming weeks. Meanwhile, we will be refactoring the existing
CMake generators to evaluate this new `cpp_info` members and generate 
files based on the new modeling. This should be a big step forward toward the
goal of more transparent integration with existing `CMakeLists.txt`.

Here are some example `package_info()` methods which demonstrate the new core 
features: 

**An alternate target name**
```
    def package_info(self):
        self.cpp_info.name = "OpenSSL"
```
**A target with two named components**
```
    def package_info(self):
        self.cpp_info.components["crypto"].name = "Crypto"
        self.cpp_info.components["crypto"].defines = ["DEFINE_CRYPTO=1"]
        self.cpp_info.components["crypto"].libs = ["libcrypto"]
        self.cpp_info.components["ssl"].name = "SSL"
        self.cpp_info.components["ssl"].includedirs = ["include/headers_ssl"]
        self.cpp_info.components["ssl"].libs = ["libssl"]
```
**A dependency from one component to another component in the same package**
```
    def package_info(self):
        self.cpp_info.components["crypto"].name = "Crypto"
        self.cpp_info.components["ssl"].name = "SSL"
        self.cpp_info.components["ssl"].requires = ["crypto"]
```
**A dependency from a component to different package**
```
    def package_info(self):
        self.cpp_info.components["crypto"].name = "Crypto"
        self.cpp_info.components["crypto"].requires = ["zlib::zlib"] 
```
**A dependency from a component to a single component in different package**
```
    def package_info(self):
        self.cpp_info.components["crypto"].name = "Crypto"
        self.cpp_info.components["crypto"].requires = ["zlib::single_component"] 
```

There is even more to this new model, including generator-specific attributes, 
so please refer to the documentation if you want to understand all the new
capabilities. 

## Automatic Config Install and Update  

A common request among enterprise teams was for developers to have a less
tedious way to keep the profiles and settings on their local machines in-sync 
with the latest ones maintained in a configuration repository.  In Conan 1.25, 
a new conan configuration parameter has been added: 

`config_install_interval`

Per the documentation, it accepts portions of time (e.g. 1m, 2h, 5d). Once 
configured, each time you run any Conan command, Conan checks the last time a 
`conan config install` was performed. If the configured time interval has 
passed, `conan config install` will be run again automatically.

## Resumable Downloads 

Downloading files is a frequent activity for the Conan client. For a 
variety of reasons, downloads can fail. Previously, when a download would fail,
it would immediately restart from scratch. This can be frustrating for any user,   
but for those users working with very large binaries, repeated failures
of downloads of such binaries can become a blocker very easily.  This impact
can be felt within local developer workflows as well as in CI builds.  

In this release, Conan learned the ability to resume downloads which have 
failed. Because Conan already had [logic to retry failed transfers](https://docs.conan.io/en/latest/reference/config_files/conan.conf.html?highlight=retry), 
this new resumption logic will engage automatically, and should work very well 
to mitigate any impact coming from network connectivity issues.

## New Search Table

Finally, Conan has received a cosmetic upgrade in the form of a new search table
output for the Conan Search command. This is part of an ongoing effort to 
improve overall UX surrounding searching with Conan. Here is a preview of the 
new table: 

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2020-05-07/new-conan-search-table.png" align="center" alt="New Conan Search HTML Table Output"/>
</p>

The new HTML table is a vast improvement over the previous version.  It provides
the most common features one might expect for browsing a datatable with a
long list of fields.  For example...  sort and filter!  It also provides 
configurable pagination and grouping of sub-settings under a parent column.


## Additional Features and Fixes  

As usual, we cannot cover everything in the release in this blog post, so visit 
the [changelog](https://docs.conan.io/en/latest/changelog.html#may-2020) for 
the complete list. 


-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your feedback](https://github.com/conan-io/conan/issues). 
