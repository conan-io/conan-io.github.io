---
layout: post 
comments: false 
title: "Conan 1.27 release: custom templates, configuration improvements and more CMake transparent integration"
---


Even if this release was a short one as a result of delayed 1.26, there are still a few great additions that we are happy to share with you

## More transparent CMake integration

This release continued the work initiated in previous ones with the `components` feature. The `cmake_find_package_multi` generator learned to create and manage CMake components in this release. Now using this generator it will be possible to explicitly link a single component in CMake, while enjoying the benefits of the `multi` generator that can handle more than one configuration (Debug, Release) in multi-config environments like Visual Studio.

This is another step forward to full transparent integration with CMake, and it is very likely that this generator will be the default and recommended one in the future, especially when the new `toolchain()` feature released in last Conan 1.26 matures.

## New extensibility point: custom templates

Conan provides some very popular extension mechanisms: custom settings, python-requires, hooks, etc.

The Conan 1.27 release introduce a new one: the possibility of customizing and providing your [own templates for some commands](https://docs.conan.io/en/latest/extending/template_system.html)

```bash
   $ conan new --template=<folder>
```

This will allow using templates for all the files involved in `conan new`, not only the `conanfile.py`.

```bash
   $ conan search <pkg-ref> --table=file.html
```

The HTML template used to create the final file will be the one (if existing) in `<cache>/templates/output/search_table.html`. 

Likewise, the command:

```bash
   $ conan info <pkg-ref|path> --graph=file.html
```

Will use the HTML template in `<cache>/templates/output/info_graph.html`. With these templates you can customize the output files, brand them with your company logo, visualize things differently, etc.

The templates are a powerful mechanism, and it is possible that we consider in the future further applications, like templatizing generators or other files.


## Conan configuration improvements

Conan 1.27 has added a highly requested feature: the possibility of declaring a required Conan version directly in conan.conf. This allows teams to force all their members and ensure all the machines using Conan upgrade to the desired Conan version. The feature is simple, all is necessary is to add

```
   required_conan_version = >=1.26
```

In the conan.conf file.

The `conan config install` command has also learned 2 new arguments:

```bash
   $ conan config install --list
```


This will list all the installed configurations, the ones that will be installed again if `conan config install` without arguments is called.

As sometimes some of the installed configurations might not be available anymore, or might be broken, it is also possible to remove those configurations from the stored list with:

```bash
   $ conan config install --remove=index
```


`index` being the integer number provided by `conan config install --list`.

These new commands have been a follow up and a detected need after the high interest and early adoption that the scheduled configuration installs based on the `config_install_interval` *conan.conf* utility. We will also be polishing this functionality in next releases, for example to not block when there is no internet connection. 


## Stabilizing SCM and revisions

This is not really a feature, but we are happy to announce that after large adoption of the `scm` feature and `revisions`, they are declared stable and they will not introduce any breaking changes from now on.

The `scm` functionality has stabilized its behavior when using it with the `scm_to_conandata` configuration enabled. With this feature, the `conanfile.py` is never modified, and the result of evaluating the `scm` attribute and capturing the commit and/or url of the repository is stored in the `conandata.yml` file instead, also making sure that passwords are not stored.



-----------
<br>

As usual, we cannot cover everything in the release in this blog post, so visit
the [changelog](https://docs.conan.io/en/latest/changelog.html) for the
complete list.  

We are looking forward to hearing your feedback. Please upgrade and submit your questions to [Github issues](https://github.com/conan-io/conan/issues). Enjoy Conan 1.27!
