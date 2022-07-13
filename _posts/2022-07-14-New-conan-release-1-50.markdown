---
layout: post
comments: false
title: "Conan 1.50: New CMakeToolchain.cache_variables, improving XCodeDeps support for components, fixes in CMake, MSBuild, XCode, many backports, minor changes, new tools, towards providing a 2.0 compatible recipe syntax."
meta_title: "Version 1.50 of Conan C++ Package Manager is Released" 
meta_description: "The new version features include new CMakeToolchain.cache_variables, improving XCodeDeps support for components, several fixes and much more"
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.50 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.50 Conan C/C++ package manager version",
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
 "datePublished": "2022-06-16",
 "description": "New CMakeToolchain.cache_variables, improving XCodeDeps support for components, fixes in CMake, MSBuild, XCode, many backports, minor changes, new tools, towards providing a 2.0 compatible recipe syntax.",
 }
</script>

We are pleased to announce that Conan 1.50 has been released and brings some significant
new features and bug fixes. We have added the ``CMakeToolchain.cache_variables`` to
apply them via ``-D`` arguments in the build helper. Also, we have improved the XCodeDeps
support for components. Finally, we continue fixing things and porting tools so that the
recipe syntax is compatible with Conan 2.0.


## Advances in the documentation for Conan 2.0

Before describing the new features in Conan 1.50 we would like to talk a bit about Conan
2.0. As you may know the first Conan 2.0 beta is already out and it can be installed using:

```bash
$ pip install conan --pre
```

We have done an effort lately to complete the [documentation for the new Conan major
version](https://docs.conan.io/en/2.0/). Although the documentation for 2.0 is still in
"draft" state, some sections are practically complete. There are some differences in how
the Conan 1.X and Conan 2.0 documentation is structured. Let's see the most relevant
sections of the documentation for Conan 2.0:

### The tutorial section

For example, there's a new
[tutorial section](https://docs.conan.io/en/2.0/tutorial.html) in the documentation for
2.0 that gives a practical hands-on introduction to the most important Conan
features. The idea is that you learn these features step by step. This section is divided
in three sub-sections:

1. Consuming packages

This section, that is already completed shows how to build your projects using Conan to
manage your dependencies starting from a simple project that uses the Zlib library. In
this section you will learn things like using tool_requires, what Conan settings and
options are, how to consume using a conanfile.py, and how you can cross-compile your
applications with Conan using the dual profile approach. 


2. Creating packages

3. Versioning and Continuous Integration

As we explained, the purpouse of this section is providing a guided path to learn the most important features in Conan gradually. Besides this section, there are two other sections worth mentioning here:

### The tutorial section

### The reference section


---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jun-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
