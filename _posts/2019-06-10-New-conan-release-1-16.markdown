---
layout: post
comments: false
title: "Conan 1.16: Support for GCC 8.3 and 9.1, Cascade build mode & custom templates for conan new command"
---

We got Conan 1.16 release out this time with some features and many fixes. We are also sharing the ongoing the development of the upcoming
enhancements!

## Support for GCC 8.3 and 9.1

Following the [GCC releases](http://gcc.gnu.org/releases.html) we updated the default
[settings.yml](https://docs.conan.io/en/latest/reference/config_files/settings.yml.html) to include the latest versions of the compiler.

Note that Conan by default uses the major versions of GCC only (8, 9...), as the minor is really a patch and those are intended to be fully
binary compatible. The 8.3 and 9.1 minor versions can be explicitly defined though, in profiles and in command line, but they will result in
different binaries than other minor GCC versions as 8.2.

There are cases in which creating binaries with the specific version will be handy, however, following just the major should be fine
regarding binary compatibility.

## Cascade build mode

Coming from a feature request, some people asked how to make the downstream dependencies rebuild if an upstream dependency changes. The
truth is that you can really achieve this behavior modelling you package ID correctly
[in the recipes](https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html) or globally
[changing the package-id mode](https://docs.conan.io/en/latest/creating_packages/define_abi_compatibility.html#changing-the-default-package-id-mode).

However, this is a fine-grained control that will only work when bumping the version of a dependency but not when it is compiled again. To
cover this use case we have introduced the ``--build cascade``.

For example, let's say we have an application that requires ``cppzmq/4.3.0@bincrafters/stable`` and we have the following dependency graph
for our ``app`` project:

<p class="centered">
<img src="{{ site.url }}/assets/post_images/2019-06-10/conan-info-graph.png" width="70%"/>
</p>

Now let's say that for some reason the ``libsodium/1.0.16@bincrafters/stable`` upstream dependency has to be built, because for example, we
fixed a bug in a header, (we are forcing the rebuild with ``--build libsodium``). Now we can install the dependencies using the ``cascade``
mode and Conan will mark it as ``Build`` as well as the downstream dependencies:

```
$ conan install .. --build libsodium --build cascade

libsodium/1.0.16@bincrafters/stable: Forced build from source
zmq/4.2.5@bincrafters/stable: Forced build from source
cppzmq/4.3.0@bincrafters/stable: Forced build from source
conanfile.py (app/0.0.1@None/None): Installing package
Requirements
    cppzmq/4.3.0@bincrafters/stable from 'conan-center' - Cache
    libsodium/1.0.16@bincrafters/stable from 'conan-center' - Cache
    zmq/4.2.5@bincrafters/stable from 'conan-center' - Cache
Packages
    cppzmq/4.3.0@bincrafters/stable:5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9 - Build
    libsodium/1.0.16@bincrafters/stable:6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 - Build
    zmq/4.2.5@bincrafters/stable:92105e8fc16d129eb40755d7d2152c4855f68c46 - Build
```

This might be useful for doing basic CI rebuild operations too. If you want to rebuild when an upstream dependency changes, you can check
the build order and fire a CI job for each dependency like this:

```
$ conan info .. --build libsodium --build cascade --graph=f.html
libsodium/1.0.16@bincrafters/stable: Forced build from source
zmq/4.2.5@bincrafters/stable: Forced build from source
cppzmq/4.3.0@bincrafters/stable: Forced build from source
libsodium/1.0.16@bincrafters/stable, zmq/4.2.5@bincrafters/stable, cppzmq/4.3.0@bincrafters/stable
```

## Conan new with templates

A less advanced feature but still quite useful when creating new recipes is the new ``--template`` flag for the ``conan new`` command.
The template files support jinja syntax and the only variables available at this moment are the ``name`` and the ``version`` of the package.

Conan will look for template files in the folder ``~/.conan/templates`` or will use an absolute path pointing to a template file.

For example, something like this could be used to generate a new Conan recipe:

*template.py*
```
{% raw %}class {{package_name}}Conan(ConanFile):
    name = "{{name}}"
    version = "{{version}}"{% endraw %}
```

Create new packages like this:

```
$ conan new library/1.0.0 --template=template.py
```

Templates placed in the Conan cache will benefit from sharing over ``conan config install`` command. Check the documentation
[here](https://docs.conan.io/en/latest/reference/commands/creator/new.html).

## Minor improvements and fixes

- Any warnings or errors of Conan command execution are now printed to ``stderr``: This is useful to catch specific errors in CI, provide
  a meaningful error output to users or create error logs.
- Conan execution now returns with ``6`` exit code
  ([Invalid Configuration](https://docs.conan.io/en/latest/reference/commands/return_codes.html#invalid-configuration)) for
  [constrained settings in a recipe](https://docs.conan.io/en/latest/mastering/conditional.html?highlight=restricted#constrain-settings-and-options).
- New syntax using a full reference to upload specific packages with ``conan upload <ref>:<package_id>`` (``--package`` argument is now
  deprecated).
- Meson build helper is now able to use [appropriate compiler flags](https://github.com/conan-io/conan/pull/5222).

## Ongoing development

As we did in the previous release post, the Conan team is under heavy development of key features. For this release we have been working on
the lockfiles (a.k.a. Graph locks), the new cross-building model and the ``cpp_info`` components.

You can check the status of those features in the following links:

- Lockfiles: [conan-io/conan#5035](https://github.com/conan-io/conan/pull/5035).
- Cross-building: [conan-io/conan#5202](https://github.com/conan-io/conan/pull/5202).
- ``cpp_info`` components: [conan-io/conan#5242](https://github.com/conan-io/conan/pull/5242).

Note that this work is still a draft of the final features. Any feedback is always welcome.

-----------
<br>

As always, you can check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html).
We are open for [new issues](https://github.com/conan-io/conan/issues) with any bug report or feedback for discussion on GitHub.

Finally, don't forget to [update](https://conan.io/downloads.html) to this 1.16 release! Thanks!
