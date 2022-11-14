---
layout: post
comments: false
title: "Conan 1.54: New conanfile.win_bash_run and tools.microsoft.bash:active config, new upload_policy='skip' to avoid uploading binaries, new Git().included_files() tool to get files not in .gitignore, added distro package to global.conf Jinja rendering."
meta_title: "Version 1.54 of Conan C++ Package Manager is Released" 
meta_description: "Conan 1.54: New conanfile.win_bash_run and tools.microsoft.bash:active config, new upload_policy='skip' to avoid uploading binaries and much more"
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
 "description": "New conanfile.win_bash_run and tools.microsoft.bash:active config for better Windows bash management, new upload_policy='skip' to avoid uploading binaries, new Git().included_files() tool to get files not in .gitignore, added distro to global.conf Jinja rendering.",
 }
</script>

We are pleased to announce that [Conan 1.54 is
out](https://github.com/conan-io/conan/releases/tag/1.54.0) and brings some significant
new features and bug fixes. First, this release comes with a new
``ConanFile.win_bash_run`` attribute and a ``tools.microsoft.bash:active`` configuration
to manage Windows bash more accurately. Also, the new ``ConanFile.upload_policy`` class
method provides a way of skipping uploading binaries for a recipe. We added a new
``Git.included_files()`` method to get the files included in *git* that are not in the
*.gitignore*. Finally, the ``distro`` package is added to the context of the [Jinja
global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html#configuration-file-template)
template on Linux platforms.  

Also, it's worth noting that [Conan
2.0-beta5](https://github.com/conan-io/conan/releases/tag/2.0.0-beta5) was released this
month with several new features and fixes.

## New ConanFile.win_bash_run attribute and tools.microsoft.bash:active

Since Conan 1.55 you can configure how Conan interacts with [Windows
Subsystems](https://docs.conan.io/en/latest/systems_cross_building/windows_subsystems.html#windows-subsystems)
in a more precise way:

- *ConanFile.win_bash_run*. The ``win_bash_run`` attribute is equivalent to the
``win_bash`` one but for the ``run`` scope. That means that if you set
``win_bash_run=True`` all the commands that are invoked via ``self.run(cmd, scope="run")``
will run inside the bash shell. 

- *tools.microsoft.bash:active*. Using
[tools.microsoft.bash:active](https://docs.conan.io/en/latest/systems_cross_building/windows_subsystems.html#running-commands-inside-the-subsystem)
you can define if Conan is already running inside a subsystem (Msys2) terminal. Then, any
command that runs with ``self.run`` (also depending on the value of ``win_bash_run`` and
``win_bash``) will run that command explicitly in the bash if
``tools.microsoft.bash:active`` is set to ``False``.


## New ConanFile.upload_policy

Sometimes, you may want to skip uploading Conan packages to the remote. The most
typical case is packages that download huge binary tools (android-ndk or similar). In
this case, it would not make much sense to repackage those binaries into a ``.tgz`` Conan
package which can take a significant amount of time. For these cases, you can set the
``upload_policy`` class attribute in the ConanFile to the value ``skip``.


```python

...

class AndroidNDKConan(ConanFile):
    name = "android-ndk"
    ...
    upload_policy = 'skip'
    ...

```

Then, if you upload the Conan package to the server, the recipe is uploaded but not any
binaries:


```bash

➜ conan upload android-ndk/r25@ -c --all -r myremote
android-ndk/r25: Skipping upload of binaries, because upload_policy='skip'
...
Uploaded conan recipe 'android-ndk/r25' to 'myremote': https://...

```

## New Git.included_files() method

This [new Git tool
method](https://docs.conan.io/en/latest/reference/conanfile/tools/scm/git.html#included-files)
returns the list of files not in the *.gitignore* list. It can be practical
if, for example, you want to implement an export of just those files:

```python

from conan import ConanFile
from conan.tools.scm import Git

...

class MyPackages(ConanFile):
    ...

    def export_sources(self):
        git = Git(self)
        included = git.included_files()
        for i in included:
            dst =  os.path.join(self.export_sources_folder, i)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(i, dst)    

```

## Add distro package to Jinja context in global.conf

As you may know, you can use the the Jinja2 template engine in the
[global.conf](https://docs.conan.io/en/latest/reference/config_files/global_conf.html).
When Conan loads this file, immediately parses and renders the template, which must result
in a standard tools-configuration text. The Python packages passed to render the template
for all the platforms are ``os`` and ``platform``. Since version 1.55 the ``distro``
package is also passed for Linux. That can be very useful if you have a configuration that
depends on the Linux distribution. You could set the default profiles depending on the
distribution in the *global.conf* file, for example:


```text
...
{% raw %}
core:default_profile={{distro.id()}}
{% endraw %}
...
```

Then, Conan will use a profile named after the distribution name (ubuntu, debian,
centos...) as the default host profile name.

## Conan 2.0-beta5 released

We have just released Conan 2.0 beta5. You can install it using *pip*:

```bash
$ pip install conan --pre
```

This new beta comes with several new features and fixes. Some of those features are:

- Improvements in the remotes management and API.
- Simplifying compress and uncompress of *.tgz* files and also preserving timestamps for
  uncompressed files.
- Improvements in lockfiles: new LockfileAPI and lockfiles generation in conan export.

Please check the [documentation for Conan 2.0](https://docs.conan.io/en/2.0/) if you want
to start trying the new features.

---

<br>

Besides the items listed above, there were some minor bug fixes you may wish to read
about. If so please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#nov-2022) for the complete
list.

We hope you enjoy this release and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
