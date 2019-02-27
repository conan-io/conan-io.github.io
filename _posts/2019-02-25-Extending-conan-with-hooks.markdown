---
layout: post
comments: false
title: "Extending Conan functionalities with hooks"
---

Back in [Conan 1.8 blog post](https://blog.conan.io/2018/10/11/New-conan-release-1-8.html) release we introduced a so called
"Plugin System". Reading some of the feedback from users we soon realized that although it was a very useful feature, it wasn't exactly a
plugin mechanism. Normally such a mechanism is something more general and powerful that replaces or complements the functionality of a tool
in a wider way.

Instead, the feature was designed with the philosophy on having a way of doing pre and post actions between certain Conan events in mind.
This was very similar to [git hooks feature](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), so we decided to rename them after
and will consider developing a real plugin system in the future.

## Status of Hooks

Hooks were released to give users a way to perform additional tasks besides the usual actions in Conan like exporting, building,
uploading... and even to implement additional actions as part of the Conan behavior. This view has not changed and we strongly believe they
make a lot of sense for people using Conan inside a company or organization that want a custom behavior when building all of their packages.

However, companies aren't the only ones that can benefit from the power of custom actions in Conan but also the open source community. Hooks
are very convenient when it comes to linting syntax in recipes, checking for missing attributes like licenses, ensuring proper application
of settings and so on.

In [recent releases](https://docs.conan.io/en/latest/changelog.html) we introduced some minor improvements and fixes for hooks although
usability remained almost the same. Hooks can now be installed in different folders under the *hooks* folder in the configuration, allowing
users to have multiple hooks living together and avoiding naming collision. This structure may come handy when reusing modules in hooks or
storing additional files such as licenses, readmes, requirement files...

You can find more information about how to activate from command line and share hooks in the
[documentation](https://docs.conan.io/en/latest/extending/hooks.html#storage-activation-and-sharing).

## Using Hooks

The Conan hooks are a Python scripts intended to extend the Conan functionalities and let users enhance the client behavior at determined
points. To use them we would need to have the source code of the hook to be executed by Conan and get them activated with some commands.

Let's take a look to how to do this.

### Cloning a Hooks repository

As stated in the documentation, hooks can be shared with ``conan config install``, making them part of the configuration and managing also
its default activation. This mechanism is useful for those sharing the configuration all together but, what if you are developing a hook?,
what if you want to have them versioned in their own repository? The mechanism proposed for this in the documentation is using ``git clone``
directly in the *~/.conan/hooks* directory using a subdirectory for them:

```
$ cd ~/.conan/hooks
$ git clone https://github.com/conan-io/hooks.git conan-io
```

We strongly believe they need a separated repository to grow and get mature, so we have come with the solution on
having the development controlled under ``git`` and this will help us with the versioning in the future.

You might have noticed that we cloned the repository into a ``conan-io`` folder, this is done to avoid name collision of hooks so we can
distinguish them using its path.

### Activating some Hooks

Now that we have hooks cloned it is just a matter of activating the desired ones. There are different possibilities for doing this:

- Editing the *conan.conf* file: You can go to the ``[hooks]`` section and write the path to the hook you want to use relative to the
  *hooks* folder.

  *conan.conf*
  ```
  ...

  [hooks]
  conan-io/hooks/attribute_checker
  conan-io/hooks/binary_linter
  ```

- From command line: Using `conan config set hooks.<hook path>` command (relative path as described above).

  ```
  $ conan config set hooks.conan-io/hooks/attribute_checker
  $ conan config set hooks.conan-io/hooks/binary_linter
  ...
  ```

- Using the environment variable ``CONAN_HOOKS``: This allows using more than one hook separated by commas and path can be either relative
  to *hooks* folder or absolute to any other location. This might be useful for CI environments.

  ```
  $ set CONAN_HOOKS=/home/user/.conan/hooks/conan-io/hooks/attribute_checker,/home/user/.conan/hooks/conan-io/hooks/binary_linter
  ```

## Hooks under development

In the documentation we proposed some ideas and small [examples](https://docs.conan.io/en/latest/extending/hooks.html) about hooks like
attribute checks in the recipe, package signing or source code download immutability. We have already implemented the attribute checker
linter as a hook.

Together with this we created a hooks repository to start developing ourselves useful hooks for the community and we already got some pull
requests and bunch of issues with ideas on how to improve the hooks integration with Conan and discuss things like the configuration,
testing, documentation...

In this post we want to share the hooks created in this repo and how to use them.

### Attribute Checker

This was the first hook created as an example and is now extracted in this repository. It is a small example to learn how to write a first
hook.

```
$ conan export . user/channel
[HOOK - conan-io/hooks/attribute_checker.py] pre_export(): WARN: Conanfile doesn't have 'url'. It is recommended to add it as attribute
[HOOK - conan-io/hooks/attribute_checker.py] pre_export(): WARN: Conanfile doesn't have 'license'. It is recommended to add it as attribute
```

See hook documentation: https://github.com/conan-io/hooks#attribute-checker

### Binary Linter

The binary linter hooks provides some hints about the artifacts that has been built and eventually packaged after the ``package()`` call. It
is very helpful to analyze possible missing dependencies in shared libraries as well as to check that the binaries generated match the
profile used.

Here you can see a brief output of the hook:

```
$ conan create . docopt/0.6.2@user/testing
[HOOK - cona-nio/hooks/binary_linter.py] post_package(): conan binary linter plug-in
[HOOK - conan-io/hooks/binary_linter.py] post_package(): file "~/.conan/data/docopt/0.6.2/user/testing/package/970e773c5651dc2560f86200a4ea56c23f568ff9/conaninfo.txt" is not a executable, skipping...
[HOOK - conan-io/hooks/binary_linter.py] post_package(): checking file "~/.conan/data/docopt/0.6.2/user/testing/package/970e773c5651dc2560f86200a4ea56c23f568ff9/bin/docopt.dll"
[HOOK - conan-io/hooks/binary_linter.py] post_package(): "~/.conan/data/docopt/0.6.2/user/testing/package/970e773c5651dc2560f86200a4ea56c23f568ff9/bin/docopt.dll" doesn't import library "msvcr110.dll"
...
[HOOK - conan-io/hooks/binary_linter.py] post_package(): "~/.conan/data/docopt/0.6.2/user/testing/package/970e773c5651dc2560f86200a4ea56c23f568ff9/bin/docopt.dll" imports library "vcruntime140.dll"
[HOOK - conan-io/hooks/binary_linter.py] post_package(): "~/.conan/data/docopt/0.6.2/user/testing/package/970e773c5651dc2560f86200a4ea56c23f568ff9/bin/docopt.dll" doesn't import library "vcruntime140d.dll"
...
```

See hook documentation: https://github.com/conan-io/hooks#binary-linter

### Bintray Updater

As some of you may know, when uploading packages to Bintray the metadata of the recipe is not process at all. This results in the
information of Bintray being empty. However, with this hook you would get all the information filled.

You will have to provide your Bintray user and API token as environment variables (``BINTRAY_LOGIN_USERNAME`` and ``BINTRAY_PASSWORD``).

With this hook active, the information is collected from the recipe attributes, such as ``name``, ``license``, ``url``, ``homepage`` and
``description``. The maturity level is based on the branch name like `master`, `release` and `stable` are considered ``Stable`` maturity
level. The project logo is not supported by this hook, since the Bintray API does not allow file uploads, and it is updated during the
recipe upload using the Bintray REST API (LINK).

```
$ conan upload docopt/0.6.2@user/testing -r bintray

Uploading docopt/0.6.2@user/testing to remote 'bintray'
...
Uploaded conan recipe 'docopt/0.6.2@user/testing' to 'bintray': https://bintray.com/user/public-conan
[HOOK - conan-io/hooks/bintray_update.py] post_upload_recipe(): Reading package info form Bintray...
[HOOK - conan-io/hooks/bintray_update.py] post_upload_recipe(): Inspecting recipe info ...
[HOOK - conan-io/hooks/bintray_update.py] post_upload_recipe(): Bintray is outdated. Updating Bintray package info: licenses, issue_tracker_url, vcs_url, website_url, desc
```

See hook documentation: https://github.com/conan-io/hooks#bintray-update

### Conan Center Reviewer

Following the inclusion guidelines for third party, we have created a full Conan Center checker with this hook. It is mostly intended for
reviewing packages before submitting an inclusion request to Conan Center.

It is one of the tools used for curating the central repository and although the complete set of checks are only executed during a
``conan create``, you can also use with package development commands such as ``conan source``, ``conan build``...

```
$ conan create . user/channel
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): ERROR: [RECIPE METADATA] Conanfile doesn't have 'url'. It is recommended to add it as attribute
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): ERROR: [RECIPE METADATA] Conanfile doesn't have 'license'. It is recommended to add it as attribute
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): [HEADER ONLY] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): [NO COPY SOURCE] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): [FPIC OPTION] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): [FPIC MANAGEMENT] 'fPIC' option not found
[HOOK - conan-io/hooks/conan-center_reviewer.py] pre_export(): [VERSION RANGES] OK
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
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_build(): [MATCHING CONFIGURATION] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_build(): [SHARED ARTIFACTS] OK
TestPkg/0.0.1@user/channel: Generated conaninfo.txt
TestPkg/0.0.1@user/channel: Generated conanbuildinfo.txt
...
TestPkg/0.0.1@user/channel: Calling package()
TestPkg/0.0.1@user/channel: WARN: This conanfile has no package step
TestPkg/0.0.1@user/channel package(): WARN: No files in this package!
TestPkg/0.0.1@user/channel: Package 'ca33edce272a279b24f87dc0d4cf5bbdcffbc187' created
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_package(): ERROR: [PACKAGE LICENSE] No package licenses found in: ~/.conan/data/TestPkg/0.0.1/user/channel/package/ca33edce272a279b24f87dc0d4cf5bbdcffbc187. Please package the library license to a 'licenses' folder
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_package(): [DEFAULT PACKAGE LAYOUT] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_package(): [MATCHING CONFIGURATION] OK
[HOOK - conan-io/hooks/conan-center_reviewer.py] post_package(): [SHARED ARTIFACTS] OK
```

As you can see, all the checks are non blocking and mostly informative. There are recipe syntax checks and also license and binary format
ones.

See hook documentation: https://github.com/conan-io/hooks#conan-center

### GitHub Updater

This hook is similar to the Bintray updater but with GitHub. It updates the repository information such as description, topics and webpage.
This way all the information is in GitHub and it will help when searching for recipe sources.

![](../assests/post_images/2019-02-27/github_updater.png)

You will need to set a GitHub API token as environment variable and perform an export of the recipe you want to get its information updated.
It will use the URL attribute in the recipe to perform the update.

See hook documentation: https://github.com/conan-io/hooks#github-updater

## Considerations for Hooks development

Keep in mind that hooks are quite versatile and can be use as far as python extends, however, it is not recommended to use hooks for task
that could compromise the binary compatibility interfering with the package ID generation model. Package reproducibility might be also a
concern at some point, but it is up to the user to track the hooks in the Conan configuration.

We have also thought about improvements for Hooks that might come in the future following its adoption by the community, such as:

- Dedicated commands for managing hooks: Installation, activation, update, list...
- A versioning system of hooks and compatibility with versions of Conan client.
- Hooks configuration parameters via configuration file, environment or custom.
- Validation and tests during installation.
- Automatic resolution of external pip requirements used.

## Final notes

All those hooks are under development but we would like to encourage everyone, specially in the OSS community, to use them and provide
feedback.

We are open to contributions improving the current hooks or proposing new ones that could be of interest of the community. If you are
interested, comment in the [hooks issue tracker](https://github.com/conan-io/hooks/issues) and feel free to open a PR with your proposals.

Finally, don't forget to check the [documentation](https://docs.conan.io/en/latest/reference/hooks.html) to learn more!
