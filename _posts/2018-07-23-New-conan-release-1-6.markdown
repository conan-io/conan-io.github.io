---
layout: post
comments: false
title: "Conan 1.6: New parameters to execute processes in recipes, improved tooling and small additions to commands"
---

New release and some new features! Conan 1.6 comes with many small improvements around tooling and process execution inside recipes as well
as with small additions to the command line.

## New parameters for self.run()

Having a look at many many recipes we realized that setting environment variables such as ``DYLD_LIBRARY_PATH`` to launch packaged apps is a
very recurrent use case. There were already some tools to help with the process but still there was a nasty repeatedly used bunch of code
lines usually in *test_package*:

```
    def test(self):
        with tools.environment_append(RunEnvironment(self).vars):
            bin_path = os.path.join("bin", "example")
            if self.settings.os == "Windows":
                self.run(bin_path)
            elif self.settings.os == "Macos":
                self.run("DYLD_LIBRARY_PATH=%s %s" % (os.environ.get('DYLD_LIBRARY_PATH', ''), bin_path))
            else:
                self.run("LD_LIBRARY_PATH=%s %s" % (os.environ.get('LD_LIBRARY_PATH', ''), bin_path))
```

So we came with [tools.run_environment()](https://docs.conan.io/en/latest/reference/tools.html#tools-run-environment) and injected those
needed variables before the command in the conanfile
[self.run() method](https://docs.conan.io/en/latest/reference/conanfile/other.html#running-commands). Now you can simply use:

```
    def test(self):
        bin_path = os.path.join("bin", "example")
        self.run(bin_path, run_environment=True)
```

## Improved tooling

This release has been very much about improvements to the Conan tools and new additions as mentioned above with ``tools.run_environment()``.

We have new ``tools.unix2dos()``/``dos2unix()`` to convert between LF and CRLF line endings.

There were some improvements in ``tools.get()`` with parameters ``filename``, to download files with a name that cannot be deduced from URL,
and ``keep_permissions``, to propagate the flag to ``tools.unzip()``.

Moreover, in ``tools.unzip()`` we have introduced support for XZ extensions. This would only be available for Python 3 users and starts the
journey towards Python 2 deprecation as there is no support to implement such new features.

Finally we continued improving the ``tools.Git()``, this time to allow capturing the current branch with ``get_branch()`` and current commit
with ``get_commit()``.

Go and check all the new changes in the [tools section](https://docs.conan.io/en/latest/reference/tools.html).

## Small additions to commands

We included new ``--raw`` flag to ``conan remote list`` to display remotes in the same way they are configured in the registry. You can copy
and paste the output into your *remotes.txt* file to use ``conan config install`` feature!

Talking about ``config install``, it has a new ``--type "git"`` flag to indicate installation should be done cloning a git repository from
the URL provided. This is handy for example if you are working with Microsoft Team Foundation Server TFS git repositories.

Finally, ``conan build --test`` was added together with ``should_test`` attribute in the conanfile as a logic step to
[control the test stage](https://docs.conan.io/en/latest/reference/conanfile/attributes.html#should-configure-should-build-should-install-should-test)

## Other highlights

- LLVM toolsets for Visual Studio has been included in *settings.yml*.
- We have improved our pyinstaller to include the Python dependencies and improved the
  [deb installer](https://bintray.com/conan/installers/client_installers/1.6.0#files) for distros such as Debian 9.

Check the full list of features and fixes in the [changelog](https://docs.conan.io/en/latest/changelog.html#july-2018) and don't forget to
[update](https://conan.io/downloads.html)!
