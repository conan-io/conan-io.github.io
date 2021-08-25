---
layout: post
comments: false
title: "Conan 1.39 : backport of "pkg/(alias)" syntax from 2.0, new --require-override CLI argument, new "win_bash" management with better configuration, new conan.tools.microsoft.VCVars generator, improvements in Environment model."
meta_title: "Version 1.39 of Conan C++ Package Manager is Released"
meta_description: "Conan 1.39 : backport of "pkg/(alias)" syntax from 2., new --require-override CLI argument, new "win_bash" management with better configuration, new conan.tools.microsoft.VCVars generator, improvements in Environment model."
---

We are pleased to announce that Conan 1.39 has been already released and that it brings some significant new features and bugfixes. One of the most important ones is the new syntax for aliases that we have ported from 2.0 to 1.39. We have added a new `-require-override` argument to define dependency overrides directly on command line. Also, for the new toolchains and generators you can set the new `win_bash` property in the ConanFile to enable running commands in a bash shell in Windows. We have a new VCVars generator that generates a `conanvcvars.bat` that will activate the Visual Studio Developer Command Prompt. Finally the Environment model comes with several improvements.

## Aliases syntax from 2.0 ported to 1.39

We decided to make alias requirements explicit for Conan 2.0 because the impossibility to know that an alias requirement is actually an alias, until it is fully fetched and resolved has always been very problematic. To make the transition to 2.0 recipes smoother and also to help solving some alias related issues we have decided to port the new syntax to the 1.39 release.

The new syntax adds ``()`` characters to indicate that we are requiring an alias (in a similar way that the ``[]`` brackets do for version ranges definition)

```python
class MyPkg(ConanFile):
    # Previous syntax, implicit, nothing in the reference tells it is an alias
    # requires = "boost/latest@mycompany/stable"
    # New experimental syntax, explicit:
    requires = "boost/(latest)@mycompany/stable"

```

If you want to read the original proposal for the new syntax, please [check the pull request](https://github.com/conan-io/tribe/pull/25) in the Conan 2.0 Tribe GitHub repository.


## 



-----------
<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jul-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues). 
