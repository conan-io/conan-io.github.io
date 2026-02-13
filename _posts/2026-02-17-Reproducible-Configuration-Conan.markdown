---
layout: post
comments: false
title: "Reproducible and traceable configuration for Conan C and C++ package manager"
description: "Using 'conan config install-pkg' for a systematic, reproducible, traceable and UX friendly configuration"
meta_title: "Reproducible and traceable configuration for Conan C and C++ package manager - Conan Blog"
categories: [cpp, conan, configuration, reproducibility, lockfile]
---

The Conan C and C++ package manager has many powerful customization and extensibility capabilities. It is possible to configure the remote servers that are being used, define custom settings to model different binaries using user-defined logic, use custom profiles, use custom Conan commands for automation, there are hooks for automating different tasks, extensions like plugins to define rules for profile checking or binary compatibility, and many more.

Conan has provided for some time the ``conan config install`` command, that could use a git repository or a zip file in an http server to install all of the above configuration files. This has proven a simple and convenient way to distribute and share the Conan configuration, so all the CI machines and developer machines could use the same configuration. But this approach still had some challenges, things like being able to reproduce the same configuration that was used to build something in the past was complicated.

With the recent introduction of ``conan config install-pkg``, configuration management has effectively turned into a first-class citizen. You can now package all your custom configuration, remotes,  profiles, hooks, custom settings, etc. as standard Conan packages and manage them with the same rigor you apply to your C++ libraries, enjoying all the versioning capabilities like version ranges and lockfiles to get a new level of  extensibility, reproducibility and traceability.

Using the new Conan configuration packages and the ``conan config install-pkg`` has several advantages:


## Improved versioning, easier updates

As Conan packages are versioned, putting the configuration inside a Conan package automatically leverages all the versioning capabilities. For example, to install a specific version from a Conan package:

```bash
$ conan config install-pkg my_conf/1.2
```

Instead of the previous `conan config install`:
```bash
$ conan config install git@github.com/myorg/repo/my_conf.git --args "-b 1.2"
```

Furthermore, it is also possible to use version ranges for installation, and for updating to the latest version within the defined range:

```bash
$ conan config install-pkg "mycompany_conf/[>=1.0 <2]"
```

## Simple to create and maintain

Creating a Conan package for configuration uses a very simple recipe with ``package_type = “configuration”``:

```python
from conan import ConanFile
from conan.tools.files import copy

class Conf(ConanFile):
   name = "myconf"
   version = "1.2"
   package_type = "configuration"

   def package(self):
       copy(self, "*.conf", src=self.build_folder, dst=self.package_folder)
```

And the package can be created and uploaded to the server with the standard commands:

```bash
$ conan export-pkg .
$ conan upload * -r=default -c
```

Then, when this package is installed with 

```bash
$ conan config install-pkg myconf/1.2 
```

the configuration process will copy the contents of the package's internal “package folder” to the current Conan home.


## Can use different configurations per platform

One of the advantages of using Conan packages is that in the same way Conan package binaries will be different based on the current profile (OS, compiler, architecture, etc), it is possible to have different configurations for different platforms. Adding ``settings = “os”`` to the recipe above and conditioning the ``copy()``, we could have it:

```python
import os
from conan import ConanFile
from conan.tools.files import copy

class Conf(ConanFile):
   name = "myconf"
   version = "1.2"
   settings = "os"
   package_type = "configuration"

   def package(self):
       f = "win" if self.settings.os == "Windows" else "nix"
       copy(self, "*.conf", src=os.path.join(self.build_folder, f), dst=self.package_folder)
```

The different configuration packages can be created with:

```bash
$ conan export-pkg . -s os=Windows
$ conan export-pkg . -s os=Linux
$ conan upload * -r=default -c
```

And then, when ``conan config install-pkg myconf/1.2`` is done, it will automatically install the Windows or Linux configuration files based on the current platform.


## Same infrastructure and processes

Another advantage of Conan configuration packages is that it is possible to use the same server-side repositories that store regular Conan packages to store them. Then, it is not necessary to establish or configure new repositories or credentials to access the configuration, as it will be the same one of the regular packages.

Likewise, it is possible to use the same development and release conventions than other packages, like running promotions between different server repositories to control maturity of the configuration itself, similar to the promotions used in the CI tutorial in https://docs.conan.io/2/ci_tutorial/tutorial.html


## Easy bootstrap with ``conanconfig.yml``

Besides the command line syntax, it is also possible to define a ``conanconfig.yml`` file that can contain one or more configuration packages references like:

```yaml
packages:
   - myconf_a/0.1
   - myconf_b/0.1
```

The ``conanconfig.yml`` file can also define version-ranges and possible URLs of the repositories to download them for the first time, like:

```yaml
packages:
   - myconf_a/[>=1 <2]
urls:
   - https://myserver/url/api/conan/conanrepo
```

That means that if a source repository contains a ``conanconfig.yml`` file, it is enough to do a simple:

```bash
$ conan config install-pkg  # No arguments at all
```

And that will read the ``conanconfig.yml`` in the source repo and install all the configuration from it. 

Together with the usage of the ``.conanrc`` file that can define a ``conan_home`` for the current folder, this is a powerful mechanism to achieve full isolation and reproducibility of configuration for different projects.


## Reproducibility and lockfiles

When you generate a lockfile for your project, Conan can now record exactly which version and revision of the configuration packages was used. If you need to reproduce a bug from a build that happened three months ago, the lockfile ensures you aren't just using the right library versions, but also the exact same configuration, profiles, remotes, custom settings, hooks, etc that were present during the original build.

Lockfiles work well with ``conanconfig.yml`` files too. The files can contain a valid version range ``myconf_a/[>=1 <2]`` while the lockfile can guarantee the reproducibility of a specific version and recipe revision in that range.


## Effect on package_id

The ``core.package_id:config_mode`` configuration entry allows you to include configuration packages in the package ID calculation for every package built or consumed under that configuration. For example, you can define this in global.conf as follows:

```ini
# in your global.conf
core.package_id:config_mode=minor_mode
```

And we install the following configuration package:

```bash
$ conan config install-pkg my_conf/1.2.0
```

Then, all packages binaries ``package_id`` will contain and depend on ``my_conf/1.2.Z``. That means that creating, uploading and ``conan config install-pkg my_conf/1.2.1`` will not require to build new binaries. But if we created and configured ``my_conf/1.3.0`` instead, that will automatically require building new binaries for all packages.

This is a feature to be used cautiously, as in general, the Conan binary model with settings, options and dependencies is good and efficient to avoid unnecessary re-builds. But if there are aspects in the environment that haven’t been possible to model in the settings and options model, using this ``core.package_id:config_mode`` could be a valid approach that provides safer guarantees and better traceability of the configuration that was used to build each individual package binary.


## Easier to manage multiple configurations

Sometimes, there are scenarios where there are different configurations to be used. For example a large company could have some main remote repositories that everyone in the organization should be using, while specific projects or teams could have their own specific configuration for that project.

As we have seen in the above ``conanconfig.yml`` file, it is possible and easier to manage such scenario, as multiple Conan configuration packages can be installed, and Conan can still use the above guarantees, like applying lockfiles to guarantee reproducibility for all of them, to make all of them part of the ``package_id``.


## Conclusions

If you are managing a Conan project that has some user configurations, like defining different remotes, custom profiles, custom settings, custom commands, hooks or plugins extensions, etc, using Conan configuration packages and ``conan config install-pkg`` would make easier to maintain, distribute and manage such a configuration across CI and developer machines. Furthermore, the usage of Conan configuration packages can achieve better reproducibility and traceability, something that is more challenging with the ``conan config install`` command using git repositories, and the ``core.package_id:config_mode`` can improve the modelling of binary compatibility in advanced scenarios.

Check out the official documentation for [config install-pkg](https://docs.conan.io/2/reference/commands/config.html#conan-config-install-pkg) and the [conanconfig.yml](https://docs.conan.io/2/reference/commands/config.html#conanconfig-yml) spec, and if you have any questions or feedback, please let us know in [Github issues](https://github.com/conan-io/conan/issues).  
