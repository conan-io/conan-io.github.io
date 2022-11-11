---
layout: post
comments: false
title: "Conan 1.54: New conanfile.win_bash_run and tools.microsoft.bash:active config for better Windows bash management, new upload_policy="skip" to avoid uploading binaries, new Git().included_files() tool to get not gitignored files, added distro to global.conf Jinja rendering."
meta_title: "Version 1.54 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.54: New conanfile.win_bash_run and tools.microsoft.bash:active config for better Windows bash management, new upload_policy="skip" to avoid uploading binaries and much moore"
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.54 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.54 Conan C/C++ package manager version",
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
 "datePublished": "2022-09-22",
 "description": "New conanfile.win_bash_run and tools.microsoft.bash:active config for better Windows bash management, new upload_policy="skip" to avoid uploading binaries, new Git().included_files() tool to get not gitignored files, added distro to global.conf Jinja rendering.",
 }
</script>

New conanfile.win_bash_run and tools.microsoft.bash:active config for better Windows bash management
new upload_policy="skip" to avoid uploading binaries
new Git().included_files() tool to get not gitignored file
added distro to global.conf Jinja rendering.

We are pleased to announce that Conan 1.54 has been released and brings some significant
new features and bug fixes. First, this release comes with a new ``ConanFile.win_bash``
attribute and a ``tools.microsoft.bash:active`` configuration to manage Windows bash more
acurately. Also, the new ``ConanFile.upload_policy`` class method provides a way of
skipping uploading binaries for a recipe. We added a new ``Git.included_files()`` method
to get the files included in **git** that are not in the *.gitignore*. Finally, now the
``distro`` package is passed to render the [Jinja
global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#configuration-file-template)
template in Linux platforms.  

Also, it's worth noting that [Conan
2.0-beta5](https://github.com/conan-io/conan/releases/tag/2.0.0-beta5) was released this
recently with several new features and fixes.

## New ConanFile.win_bash attribute and tools.microsoft.bash:active

## New ConanFile.upload_policy

## New Git.included_files() method

## distro package in global.conf Jinja context


## Conan 2.0-beta5 released

Conan 2.0 beta5 [is already
out](https://github.com/conan-io/conan/releases/tag/2.0.0-beta5). You can install it using
*pip*:

```bash
$ pip install conan --pre
```

Don't forget to check the [documentation for Conan 2.0](https://docs.conan.io/en/2.0/).

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#aug-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
