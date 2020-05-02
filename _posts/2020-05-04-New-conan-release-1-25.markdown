---
layout: post 
comments: false 
title: "Conan 1.25: New cross-build variables, automatic config install, Resumable downloads, New HTML Table"
---

Conan 1.25 follows up the previous release with another wave of progress related
to the new cross-build modeling. There are also some brand new features we are
excited about. Conan has learned to update it's configurations and profiles 
automatically by enabling the ability to schedule the 
`conan config install command`. We've also dramatically improved the output of
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
variety of reasons, downloads can fail. This can be frustrating for any user,   
but for those users working with very large binaries, repeated failures
of downloads of such binaries can become a blocker very easily.  This impact
can be felt within local developer workflows as well as in CI builds.  

In this release, Conan learned the ability to resume downloads which have 
failed. Because Conan already had [logic to retry failed transfers]
(https://docs.conan.io/en/latest/reference/config_files/conan.conf.html?highlight=retry), 
this new resumption logic will engage automatically, and should work very well 
to mitigate any impact coming from network connectivity issues.

## New HTML Table

Finally, Conan has received a cosmetic upgrade in the form of a new HTML table
output for the Conan Search command. This is part of an ongoing effort to 
improve overall UX surrounding searching with Conan. Here is a preview of the 
new table: 

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2020-05-04/new-conan-search-table.png" align="center" alt="New Conan Search HTML Table Output"/>
</p>

The new HTML table is a vast improvement over the previous.  It provides
the most common features one might expect for browsing a datatable with a
long list of fields.  For example...  sort and filter!  It also provides 
configurable pagination and grouping of sub-settings under a parent column.


## Additional Features and Fixes  

As usual, we cannot cover everything in the release in this blog post, so visit 
the [changelog]( https://docs.conan.io/en/latest/changelog.html#may-2020) for 
the complete list. 


-----------
<br>

As usual, we hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues). 
