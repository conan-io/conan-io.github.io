---
layout: post
comments: true
title: "New security measures for conan package manager"
---

In a previous post [“Are C and C++ languages ready for the NPM debacle”](https://blog.conan.io/2016/03/30/are-c-and-c++-languages-ready-for-the-npm-debacle.html), we described the approach of Conan package manager to security, which stands on:

- Namespaces. Packages are created on user accounts namespace, so, even if they are removed by the author (like happened in NPM), they cannot be replaced by other user under the same namespace.
- Easy fork/copy of packages. Packages can be forked or copied, just like git repos, and put under your own account namespace, so you don’t depend on others and possible changes on their packages do not affect your dependencies.
- Distributed nature of conan. Actually, most of conan users that are using it in production are running their own conan servers, and copying packages for OSS libraries from conan.io remote if necessary, even just generating the binary packages from package recipes obtained from github.
- Manifests: Every package recipe and package binary has a manifest of files and checksums, and some integrity checks were optionally possible.


Capturing and verifying manifests
------------------------------------

Even if conan had the manifests already in place, there were still practically not used. From conan 0.13 a new requested functionality has been added to implement security checks over the dependencies of a project, machine or user account. It has been implemented as an option, as some users that are running against their own server already have their own security measures and do not need it.

The first step is to capture the manifests of all recipes and package binaries for the dependencies of a project:


{% highlight bash %}
$ conan install . --manifests
{% endhighlight %}

This will capture the dependencies of the current folder ``conanfile`` into a folder called by default ``.conan_manifests``

This folder can (and probably should) added to version control, for later checks, irrespective of the machine that it runs. Different package binaries can be added to the ``conan_manifests`` folder, capturing manifests for different OS, architectures, and compilers, in the same project. Under version control, it can be known which developers checked and pulled the different dependencies (and manifests) for different settings.

Also, a specific folder can be used, both with a relative and absolute path:

{% highlight bash %}
$ conan install . --manifests=/path/to/myfolder
{% endhighlight %}

This would be a good solution to run checks machine-wide instead of project-wide, in a CI server, or on a developer machine that wants to check all projects in a single manifest storage.

Afterwards, a manifest capture can be checked against the installed dependencies very easily:


{% highlight bash %}
$ conan install . --verify
{% endhighlight %}

This will check the current ``conanfile`` full dependency tree against the stored manifests. If a recipe or a package binary manifest has changed with respect to the stored manifest, it will show the error and abort the installation.

As above, a specific folder can be given as the manifests storage:

{% highlight bash %}
$ conan install . --verify=/path/to/myfolder
{% endhighlight %}

Resistance of implemented approach
----------------------------------------------------------------

While implementing a security measure, it is necessary to analyze other possible attack vectors, and how such security measure can deal with them.

After some iterations in which manifests checks were done in different points of the stack, like while downloading packages, we decided to put it in the latest place of the stack. In this way, the user is protected against any tampering, hacking, replacement and even user mistakes installing untrusted packages in the local cache. All the manifests are checked from the local cache, irrespective of their sources, local or remote. In the verification, also current disk files contents are checked against the manifests to ensure that their checksums match.

Conan current manifests are based on MD5 checksums. Some users might be concerned, saying that MD5 is broken. It is not. It is known that its “collision resistance” is broken, and two different contents can be generated with the same hash. However, its **second pre-image resistance**, i.e. given a content with a computed hash, obtain a new, different content with the same hash, is still completely secure. In our case, the potential attacker not only has to find another, random content with the same hash, but they would have to find a very similar content, with their malware injected, with the same hash. This is totally impossible, so conan is completely safe with MD5 checksums in their manifests.



Conclusion
----------------------------------------------------------------

This has been just one of the recent conan 0.13 release improvements. Other important things have been released, like doing all the upload and download transfers streaming from and to disk, instead of memory, which will use less memory resources than previous conan versions. Read the [changelog](http://docs.conan.io/en/latest/changelog.html) for a full list of changes in conan 0.13.

We take the security of conan very seriously. This is the main reason it was decided to do a fully distributed approach, in which users, especially companies, could run their own in-house conan servers, and fully control their infrastructure and security. Now, with the check of conan manifests, it is also very secure to use other remotes trusted sources without being exposed to hacks, hijacks and other issues on such remote servers. It is also very useful for self-protection, especially for very large teams and complex projects, to ensure absolute guarantees of reproducibility of the dependencies. 

Do you have any further suggestions how to improve the security of conan? Please contribute it in [github](https://github.com/conan-io/conan)
