---
layout: post
comments: false
title: "Conan 1.39 : backport of "pkg/(alias)" syntax from 2.0 to 1.39, new --require-override CLI argument, new "win_bash" management with better configuration, new conan.tools.microsoft.VCVars generator, improvements in Environment model."
meta_title: "Version 1.39 of Conan C++ Package Manager is Released"
meta_description: "Conan 1.39 : backport of "pkg/(alias)" syntax from 2., new --require-override CLI argument, new "win_bash" management with better configuration, new conan.tools.microsoft.VCVars generator, improvements in Environment model."
---

We are pleased to announce that Conan 1.39 has been already released and that it brings some significant new features and bugfixes. One of the most important ones is the new syntax for aliases that we have ported from 2.0 to 1.39. We have added a new `-require-override` argument to define dependency overrides directly on command line. Also, for the new toolchains and generators you can set the new `win_bash` property in the ConanFile to enable running commands in a bash shell in Windows. We have a new VCVars generator that generates a `conanvcvars.bat` that will activate the Visual Studio Developer Command Prompt. Finally the Environment model comes with several improvements.

## Aliases syntax from 2.0 ported to 1.39

We decided to make alias requirements explicit for Conan 2.0 because the impossibility to know that an alias requirement is actually an alias, until it is fully fetched and resolved has always been very problematic. To make the transition to 2.0 recipes smoother and also to help solving some alias related issues we have decided to port the new syntax to the 1.39 release.

The new syntax adds `()` characters to indicate that we are requiring an alias (in a similar way that the `[]` brackets do for version ranges definition)

```python
class MyPkg(ConanFile):
    # Previous syntax, implicit, nothing in the reference tells it is an alias
    # requires = "boost/latest@mycompany/stable"
    # New experimental syntax, explicit:
    requires = "boost/(latest)@mycompany/stable"
```

If you want to read the original proposal for the new syntax, please [check the pull request](https://github.com/conan-io/tribe/pull/25) in the Conan 2.0 Tribe GitHub repository.

## New --require-override CLI argument

The `conan install` command has a new `--require-override` argument. Setting this argument is equivalent to declaring `overrides=True` [when adding a require](https://docs.conan.io/en/latest/reference/conanfile/methods.html#requirements) but it is recommended to use it just for developement, for production it is better to actually update the conanfiles to explicitly reflect in code which specific versions upstream are being used. 

You can use it like:

```python
self.requires("zlib/1.2.11", override=True)
```

That is equivalent to declare this in the conanfile.py:

```bash
conan install mypkg/1.0@ --require-override=zlib/1.2.11
```

## New self.win_bash mechanism

There's a new `self.win_bash` attribute for the ConanFile that supersedes the "clasic" [self.run(..., win_bash=True)](https://docs.conan.io/en/latest/systems_cross_building/windows_subsystems.html?highlight=win_bash#self-run) to run commands inside a Windows subsystem. Setting `self.win_bash` to `True` will run all the `self.run()` commands inside a bash shell. Also, this will only happen for Windows so there's no need to check the platform in recipes for this anymore.

All the new [Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotools.html), [AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html), [AutotoolsDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolsdeps.html) and [PkgConfigDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html#pkgconfigdeps) will work automatically when self.win_bash is set. 

The new subsystem model is explicit and there's no more auto-detection. To set the path to *bash.exe* and the type of subsystem, please use these new configuration variables:

```
tools.microsoft.bash:subsystem: Values can be msys2, cygwin, msys and wsl.
tools.microsoft.bash:path: Path to the bash.exe
```

## New conan.tools.microsoft.VCVars generator

We have also added a new [VCVars generator](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#vcvars) that generates a file called `conanvcvars.bat` that activate the Visual Studio developer command prompt according to the current settings by wrapping the [vcvarsall](https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-160&viewFallbackFrom=vs-2017) Microsoft bash script.

You can use it in your *conanfile.py*

```python
class MyPkg(ConanFile):
    generators = "VCVars"
```

or *conafile.txt*

```python
[generators]
VCVars
```

Note that by default, adding this generator will also auto-activate it running the generated script. Please [read more about this](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html#creating-launcher-files) in the documentation.

## Several improvements in the new Environment model

Now `Environment` objects implement `remove` and `items` methods. Also, a unique environment launcher named `conanenv.bat/sh` is now generated to aggregate all the environment generators (*VirtualRunEnv*, *VirtualBuildEnv*, *AutotoolsToolchain* and *AutotoolsDeps*) so you can easily activate all of them with just one command.

-----------
<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jul-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues). 
