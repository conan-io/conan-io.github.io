---
layout: post
comments: false
title: "Extending Conan functionalities with hooks"
---

Back in Conan 1.8 blog post release (LINK) we introduced a so called "Plugin System". Reading some of the feedback from users we soon
realized that although it was a very useful feature, it wasn't exactly a plugin mechanism. Normally a is something more general and powerful
that replaces or complements the functionality of a tool in a wider way.

Instead, the feature was design in the philosophy on having a way of doing pre and post actions between certain Conan events. This was very
similar to [git hooks feature](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), so we decided to rename them after and consider
developing a real plugin system in the future.

## Status of Hooks

As you may know, hooks were release to give users a way perform additional tasks besides the usual actions in Conan like exporting,
building, uploading... and even to customize part of the Conan behavior. This view has not change and we strongly believe they make a lot of
sense for people using Conan inside a company or organization that want a custom behavior when building all of their packages.

However, companies aren't the only ones that can benefit from the power of custom actions in Conan but also the open source community. Hooks
are very convenient when it comes to linting syntax in recipes, checking for missing attributes like licenses, ensuring proper application
of settings and so on.

In recent releases (https://docs.conan.io/en/latest/changelog.html) we have introduced some minor improvements and fixes for hooks although
usability remains almost the same. Hooks can now be installed in different folders under the *hooks* folder in the configuration, allowing
users to have multiple hooks living together and avoiding naming collision. This structure may come handy when reusing modules in modules or
storing additional files such as licenses, readmes, requirement files...

Therefore, activation of hooks can now be done with a path to the hook interface (LINK TO DOCS):

*conan.conf*
```
...

[hooks]
conanio/hooks/attribute_checker
conanio/hooks/conan-center
conanio/hooks/binary-linter
```

You can find more information about how to activate from command line and share hooks in the documentation (https://docs.conan.io/en/latest/extending/hooks.html#storage-activation-and-sharing).

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
its default activation. This mechanism is useful form people sharing the configuration all together but what do you do when want to try
hooks developed here and there? The mechanism proposed for this in the documentation is using ``git clone`` directly in the *~/.conan/hooks*
directory using a subdirectory for them:

```
$ git clone https://github.com/conan-io/hooks.git conan-io
```

This give users the power of having hooks under a VCS and updating to new versions very simple.

Now it is just a matter of activating the desired hooks:

```
$ conan config set hooks.conanio/hooks/attribute_checker
```

### Attribute checker

This was the first hook created as an example and is now extracted in this repository. It is a small example to learn how to write a first
hook.

See hook documentation: https://github.com/conan-io/hooks#attribute-checker

### Binary Linter

See hook documentation: https://github.com/conan-io/hooks#binary-linter

### Bintray Updater

See hook documentation: https://github.com/conan-io/hooks#bintray-update

### Conan Center

See hook documentation: https://github.com/conan-io/hooks#conan-center

### GitHub Updater

See hook documentation: https://github.com/conan-io/hooks#github-update


## Considerations

- Dedicated command for hooks
- Versioning system of hooks
- configuration possibilities (conf, environment, custom config)
- Checks during installation
- requirements


If you want to know more about the changes in this release, check the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html) (it includes links to the related Pull Request) and don't forget to
[update](https://conan.io/downloads.html)!

Finally, if you find a bug or want to start a new discussion, please do not hesitate to open a new issue
[here](https://github.com/conan-io/conan/issues).