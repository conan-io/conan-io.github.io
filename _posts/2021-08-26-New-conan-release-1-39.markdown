---
layout: post
comments: false
title: "Conan 1.39 : backporting alias 2.0 syntax to 1.39, new --require-override CLI argument, new win_bash attribute in conanfiles to better manage Windows subsystems, new VCVars generator, several improvements in the new Environment model."
meta_title: "Version 1.39 of Conan C++ Package Manager is Released"
meta_description: "The new version features include backporting alias 2.0 syntax to 1.39, new --require-override CLI argument, new win_bash attribute in conanfiles and more..."
---

<script type="application/ld+json">
{ "@context": "https://schema.org", 
 "@type": "TechArticle",
 "headline": "Version 1.39 of Conan C++ Package Manager is Released",
 "alternativeHeadline": "Learn all about the new 1.39 Conan C/C++ package manager version",
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
 "datePublished": "2021-09-05",
 "description": "Porting alias 2.0 syntax to 1.39, new --require-override CLI argument, new win_bash attribute in conanfiles to better manage Windows subsystems, new VCVars generator, several improvements in the new Environment model.",
 }
</script>

We are pleased to announce that Conan 1.39 has been released and brings some
significant new features and bug fixes. One of the most important features is the new syntax for aliases
that we have backported from _2.0_ to _1.39_. We have added a new `-require-override` argument to define
dependency overrides directly on the command line. Also, for the new toolchains and generators, you can
set the new `win_bash` property in the ConanFile to enable running commands in a bash shell in
Windows. We have a new _VCVars_ generator that creates a batch script that will activate the
Visual Studio Developer Command Prompt. Finally, the new `Environment` model comes with several
improvements.

## Aliases syntax from 2.0 backported to 1.39

Current alias syntax is problematic as they are impossible to distinguish from any other requirement.
Because of this, we have introduced a new explicit syntax for Conan 2.0 that we are now backporting to
1.39. Porting this syntax to the current Conan version will also make the transition of recipes smoother.

The new syntax adds `()` characters (in a similar way that the `[]` brackets do for version ranges
definition) to indicate that we are requiring an alias:

```python
class MyPkg(ConanFile):
    # With the previous syntax youn can't know if it's an alias upfront:
    # requires = "boost/latest@mycompany/stable"

    # New experimental syntax is explicit:
    requires = "boost/(latest)@mycompany/stable"
```

If you want to read the original proposal for the new aliases syntax, please [check the pull
request](https://github.com/conan-io/tribe/pull/25) in the Conan 2.0 Tribe GitHub repository.

## New --require-override CLI argument

The `conan install` command has a new `--require-override` argument. Setting this argument is
equivalent to declaring `overrides=True` [when adding a
require](https://docs.conan.io/en/latest/reference/conanfile/methods.html#requirements). This can be
very convenient to test things during development, but for production it is better to update the
conanfiles to explicitly reflect in code which specific versions upstream are used.

You can use it like:

```bash
conan install mypkg/1.0@ --require-override=zlib/1.2.11

```

That is equivalent to declare this in the conanfile.py:

```python
self.requires("zlib/1.2.11", override=True)
```

## New self.win_bash mechanism

There's a new `self.win_bash` attribute for the ConanFile that supersedes the "classic"
[self.run(...,
win_bash=True)](https://docs.conan.io/en/latest/systems_cross_building/windows_subsystems.html#self-run)
to run commands inside a Windows subsystem. Setting `self.win_bash` to `True` will run all the
`self.run()` commands in the ConanFile inside a bash shell. Also, this will only happen for Windows
so there's no need to check the platform in recipes.

All the new
[Autotools](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotools.html),
[AutotoolsToolchain](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolstoolchain.html),
[AutotoolsDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/autotoolsdeps.html), and
[PkgConfigDeps](https://docs.conan.io/en/latest/reference/conanfile/tools/gnu/pkgconfigdeps.html#pkgconfigdeps)
will work automatically when `self.win_bash=True` is set.

The new subsystem model is explicit and there's no more auto-detection. To set the path to _bash.exe_
and the type of subsystem, please use these new configuration variables:

```txt
tools.microsoft.bash:subsystem: msys2, cygwin, msys or wsl.
tools.microsoft.bash:path: C:/Path/To/Bash.exe
```

## New conan.tools.microsoft.VCVars generator

We have also added a new [VCVars
generator](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#vcvars) that
generates a file called _conanvcvars.bat_ that activates the Visual Studio developer command prompt
according to the current settings by wrapping the
[vcvarsall](https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-160&viewFallbackFrom=vs-2017)
Microsoft bash script.

You can use it in your _conanfile.py_

```python
class MyPkg(ConanFile):
    generators = "VCVars"
```

or _conafile.txt_

```python
[generators]
VCVars
```

Note that this generator runs the _conanvcvars.bat_ script by default. This can be controlled setting the
`auto_activate` argument in the `generate` method. Please [read more about
this](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#generate) in the
documentation.

## Several improvements in the new Environment model

Now `Environment` objects implement `remove` and `items`
[methods](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html#variable-declaration).
Also, a [unique environment
launcher](https://docs.conan.io/en/latest/reference/conanfile/tools/env/environment.html#creating-launcher-files)
named _conanenv.bat/sh_ is now generated to aggregate all the environment generators
(_VirtualRunEnv_, _VirtualBuildEnv_, _AutotoolsToolchain_, and _AutotoolsDeps_) so you can easily
activate all of them with just one command.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to
read about. If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#jul-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
