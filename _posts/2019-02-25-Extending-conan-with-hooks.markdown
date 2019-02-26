---
layout: post
comments: false
title: "Extending Conan functionalities with hooks"
---

Back in [Conan 1.8 blog post]https://blog.conan.io/2018/10/11/New-conan-release-1-8.html() release we introduced a so called
"Plugin System". Reading some of the feedback from users we soon realized that although it was a very useful feature, it wasn't exactly a
plugin mechanism. Normally such a mechanism is something more general and powerful that replaces or complements the functionality of a tool in a wider way.

Instead, the feature was designed with the philosophy on having a way of doing pre and post actions between certain Conan events in mind. This was very
similar to [git hooks feature](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), so we decided to rename them after and consider
developing a real plugin system in the future.

## Status of Hooks

As you may know, hooks were released to give users a way perform additional tasks besides the usual actions in Conan like exporting,
building, uploading... and even to customize part of the Conan behavior. This view has not changed and we strongly believe they make a lot of
sense for people using Conan inside a company or organization that want a custom behavior when building all of their packages.

However, companies aren't the only ones that can benefit from the power of custom actions in Conan but also the open source community. Hooks
are very convenient when it comes to linting syntax in recipes, checking for missing attributes like licenses, ensuring proper application
of settings and so on.

In [recent releases](https://docs.conan.io/en/latest/changelog.html) we introduced some minor improvements and fixes for hooks although
usability remained almost the same. Hooks can now be installed in different folders under the *hooks* folder in the configuration, allowing
users to have multiple hooks living together and avoiding naming collision. This structure may come handy when reusing modules in modules or
storing additional files such as licenses, readmes, requirement files...

Therefore, activation of hooks can now be done with a path to the hook interface:

*conan.conf*
```
...

[hooks]
conanio/hooks/attribute_checker
conanio/hooks/conan-center
conanio/hooks/binary-linter
```

You can find more information about how to activate from command line and share hooks in the
[documentation](https://docs.conan.io/en/latest/extending/hooks.html#storage-activation-and-sharing).

## Hooks under development

In the documentation we proposed some ideas and small examples (https://docs.conan.io/en/latest/extending/hooks.html) about hooks like
attribute checks in the recipe, package signing or source code download immutability. We have already implemented the attribute checker
linter as a hook.

Together with this we created a hooks repository to start developing ourselves useful hooks for the community and we already got some pull
requests and bunch of issues with ideas on how to improve the hooks integration with Conan and discuss things like the configuration,
testing, documentation...

Here we want to share the hooks created in this repo and how to use them.

### Cloning the hooks repository

As stated in the documentation, hooks can be shared with ``conan config install``, making them part of the configuration and managing also
its default activation. This mechanism is useful for those sharing the configuration all together but, what do you do when want to try
hooks developed here and there? The mechanism proposed for this in the documentation is using ``git clone`` directly in the *~/.conan/hooks*
directory using a subdirectory for them:

```
$ git clone https://github.com/conan-io/hooks.git conan-io
```

This gives users the power of having hooks under a VCS and updating to new versions very simple.

Now it is just a matter of activating the desired hooks:

```
$ conan config set hooks.conanio/hooks/attribute_checker
$ conan config set hooks.conanio/hooks/binary-linter
...
```

### Attribute checker

This was the first hook created as an example and is now extracted in this repository. It is a small example to learn how to write a first
hook.

```
$ conan export . user/channel
[HOOK - conanio/hooks/attribute_checker.py] pre_export(): WARN: Conanfile doesn't have 'url'. It is recommended to add it as attribute
[HOOK - conanio/hooks/attribute_checker.py] pre_export(): WARN: Conanfile doesn't have 'license'. It is recommended to add it as attribute
```

See hook documentation: https://github.com/conan-io/hooks#attribute-checker

### Binary Linter

The binary linter hooks provides some hints about the artifacts that has been built and eventually packaged after the ``package()`` call. It
is very helpful to analyze possible missing dependencies in shared libraries as well as to check that the binaries generated match the
profile used.

Here you can see a brief output of the hook:

```
$ conan create . docopt/0.6.2@user/testing
[HOOK - conanio/hooks/binary-linter.py] post_package(): conan binary linter plug-in
[HOOK - conanio/hooks/binary-linter.py] post_package(): file "C:\Users\danimtb\.conan\data\docopt\0.6.2\danitmb\testing\package\970e773c5651dc2560f86200a4ea56c23f568ff9\conaninfo.txt" is not a executable, skipping...
[HOOK - conanio/hooks/binary-linter.py] post_package(): checking file "C:\Users\danimtb\.conan\data\docopt\0.6.2\danitmb\testing\package\970e773c5651dc2560f86200a4ea56c23f568ff9\bin\docopt.dll"
[HOOK - conanio/hooks/binary-linter.py] post_package(): "C:\Users\danimtb\.conan\data\docopt\0.6.2\danitmb\testing\package\970e773c5651dc2560f86200a4ea56c23f568ff9\bin\docopt.dll" doesn't import library "msvcr110.dll"
...
[HOOK - conanio/hooks/binary-linter.py] post_package(): "C:\Users\danimtb\.conan\data\docopt\0.6.2\danitmb\testing\package\970e773c5651dc2560f86200a4ea56c23f568ff9\bin\docopt.dll" imports library "vcruntime140.dll"
[HOOK - conanio/hooks/binary-linter.py] post_package(): "C:\Users\danimtb\.conan\data\docopt\0.6.2\danitmb\testing\package\970e773c5651dc2560f86200a4ea56c23f568ff9\bin\docopt.dll" doesn't import library "vcruntime140d.dll"
...
```

See hook documentation: https://github.com/conan-io/hooks#binary-linter

### Bintray Updater

As some of you may know, when uploading packages to Bintray the metadata of the recipe is not process at all. This results in the
information of Bintray being empty. However, with this hook you would get all the information filled.

You will have to provide your Bintray user and API token as environment variables (``BINTRAY_LOGIN_USERNAME`` & ``BINTRAY_PASSWORD``).

With this hook active the information of the conanfile will be extracted during the recipe upload and updated using the Bintray REST API.

```
$ conan upload docopt/0.6.2@user/testing -r bintray

Uploading docopt/0.6.2@danitmb/testing to remote 'bintray'
...
Uploaded conan recipe 'docopt/0.6.2@user/testing' to 'bintray': https://bintray.com/user/public-conan
[HOOK - conanio/hooks/bintray_update.py] post_upload_recipe(): Reading package info form Bintray...
[HOOK - conanio/hooks/bintray_update.py] post_upload_recipe(): Inspecting recipe info ...
[HOOK - conanio/hooks/bintray_update.py] post_upload_recipe(): Bintray is outdated. Updating Bintray package info: licenses, issue_tracker_url, vcs_url, website_url, desc
```

See hook documentation: https://github.com/conan-io/hooks#bintray-update

### Conan Center

Following the inclusion guidelines for third party, we have created a full Conan Center checker with this hook. It is mostly intended for
reviewing packages before submitting an inclusion request to Conan Center.

It is one of the tools used for curating the central repository and although the complete set of checks are only executed during a
``conan create``, you can also use with package development commands such as ``conan source``, ``conan build``...

```
$ conan create . user/channel
[HOOK - conanio/hooks/conan-center.py] pre_export(): ERROR: [RECIPE METADATA] Conanfile doesn't have 'url'. It is recommended to add it as attribute
[HOOK - conanio/hooks/conan-center.py] pre_export(): ERROR: [RECIPE METADATA] Conanfile doesn't have 'license'. It is recommended to add it as attribute
[HOOK - conanio/hooks/conan-center.py] pre_export(): [HEADER ONLY] OK
[HOOK - conanio/hooks/conan-center.py] pre_export(): [NO COPY SOURCE] OK
[HOOK - conanio/hooks/conan-center.py] pre_export(): [FPIC OPTION] OK
[HOOK - conanio/hooks/conan-center.py] pre_export(): [FPIC MANAGEMENT] 'fPIC' option not found
[HOOK - conanio/hooks/conan-center.py] pre_export(): [VERSION RANGES] OK
Exporting package recipe
Installing package: TestPkg/0.0.1@user/channel
Requirements
    TestPkg/0.0.1@user/channel from local cache - Cache
Packages
    TestPkg/0.0.1@user/channel:ca33edce272a279b24f87dc0d4cf5bbdcffbc187 - Build
...
TestPkg/0.0.1@user/channel: Copying sources to build folder
TestPkg/0.0.1@user/channel: Generator cmake_paths created conan_paths.cmake
TestPkg/0.0.1@user/channel: Calling build()
TestPkg/0.0.1@user/channel: WARN: This conanfile has no build step
TestPkg/0.0.1@user/channel: Package 'ca33edce272a279b24f87dc0d4cf5bbdcffbc187' built
[HOOK - conanio/hooks/conan-center.py] post_build(): [MATCHING CONFIGURATION] OK
[HOOK - conanio/hooks/conan-center.py] post_build(): [SHARED ARTIFACTS] OK
TestPkg/0.0.1@user/channel: Generated conaninfo.txt
TestPkg/0.0.1@user/channel: Generated conanbuildinfo.txt
...
TestPkg/0.0.1@user/channel: Calling package()
TestPkg/0.0.1@user/channel: WARN: This conanfile has no package step
TestPkg/0.0.1@user/channel package(): WARN: No files in this package!
TestPkg/0.0.1@user/channel: Package 'ca33edce272a279b24f87dc0d4cf5bbdcffbc187' created
[HOOK - conanio/hooks/conan-center.py] post_package(): ERROR: [PACKAGE LICENSE] No package licenses found in: ~/.conan/data/TestPkg/0.0.1/user/channel/package/ca33edce272a279b24f87dc0d4cf5bbdcffbc187. Please package the library license to a 'licenses' folder
[HOOK - conanio/hooks/conan-center.py] post_package(): [DEFAULT PACKAGE LAYOUT] OK
[HOOK - conanio/hooks/conan-center.py] post_package(): [MATCHING CONFIGURATION] OK
[HOOK - conanio/hooks/conan-center.py] post_package(): [SHARED ARTIFACTS] OK
```

As you can see, all the checks are non blocking and mostly informative. There are recipe syntax checks and also license and binary format
ones.

See hook documentation: https://github.com/conan-io/hooks#conan-center

### GitHub Updater

This hook is similar to the Bintray updater but with GitHub. It updates the repository information such as description, topics and webpage.
This way all the information is in GitHub and it will help when searching for recipe sources.

You will need to set a GitHub API token as environment variable and perform an export of the recipe you want to get its information updated.
It will use the URL attribute in the recipe to perform the update.

See hook documentation: https://github.com/conan-io/hooks#github-update

## Considerations

All those hooks are under development but we would like to encourage everyone, specially in the OSS community, to use them and provide
feedback.

Keep in mind that hooks are quite versatile and can be use as far as python extends, however, it is not recommended to use hooks for task
that could compromise the binary compatibility interfering with the package ID generation model. Package reproducibility might be also a
concern at some point, but it is up to the user to track the hooks in the Conan configuration.

We have also thought about improvements for Hooks that might come in the future following its adoption by the community, such as:

- Dedicated commands for managing hooks: Installation, activation, update, list...
- A versioning system of hooks and compatibility with versions of Conan client.
- Hooks configuration parameters via configuration file, environment or custom.
- Validation and tests during installation.
- Automatic resolution of external pip requirements used.


Don't forget to check the [documentation](https://docs.conan.io/en/latest/reference/hooks.html) to learn more about Hooks and if find a bug
or want to start a new discussion, do not hesitate to open a new issue [here](https://github.com/conan-io/hooks/issues).
