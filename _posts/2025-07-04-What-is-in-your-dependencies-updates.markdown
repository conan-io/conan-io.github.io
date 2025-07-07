---
layout: post
comments: false
title: "What's new in your dependencies? Advanced Recipe and Source Diffing in Conan"
description: "Meet the new conan report diff command. And learn how to easily compare your sources and more-"
meta_title: "What is in your dependencies updates?"
categories: [cpp, diff, report, conan]
---

## What has changed in my package?

In modern software development, **understanding what has changed** between different versions of 
your dependencies is crucial. However, many real-world workflows often raise questions that 
are not easy to answer:

* What differences exist between the recipe in my **local** cache and the one published on a **shared remote**?
* What has changed in the packaged sources between **two versions** of a package?

In the daily work of development teams, CI/CD pipelines, and repository maintainers, these 
questions typically arise in scenarios such as:

* **Compliance reviews**: when it’s necessary to verify what changes have been introduced in a specific 
package and their impact.
* **Debugging issues**: when investigating why a binary behaves differently between different versions.

## Why existing solutions fall short

Until now, addressing these problems has usually meant relying on **manual, time-consuming** processes: 
if you’re lucky and your sources are hosted in a version control repository that provides a **change 
viewer**, that might help. But what if the library you’re using does not have one? Or worse – what if 
there are so many changes between versions that the tool provided by your version control system can’t 
even load all of them?

Just as critical, though often overlooked, is the need to inspect **changes in the recipes** themselves. 
Yet, up until now there’s been no easy way to view changes in both the packaged sources and the 
packaging code side by side. No existing tools offer a unified diff that spans both areas.

Moreover, there’s the challenge of knowing exactly what changes exist in the version you have on 
your remote. Sometimes **versions get retagged**, and in those cases, you lose the ability to see 
those changes reliably. Or, if you want to compare the exact differences between two specific 
revisions of your recipes, none of those tools can help you do it accurately.

This can get even more complicated when **patches** have been applied to our code, introducing an entirely 
new dimension that also needs to be tracked and verified.

The process we usually end up following is downloading packages, extracting recipes, sources, and 
patches, applying these patches, and finally using external tools (such as diff or git diff) to 
compare them. This approach not only requires time but also leaves room for **human errors** and makes 
automation more challenging.

## A new command to compare recipes and sources

To solve this problem, we’ve created a new Conan command, the **conan report diff** that acts 
like a *git diff wrapper*, but for packages and recipes stored in remotes or local caches. 
With this command, you can **compare two recipes with their sources** (including patches) and see 
exactly what has changed, not only between tagged versions, but even between revisions.

It’s very simple to use. For example, if we want to check the differences between “zlib/1.3” and
“zlib/1.3.1” and see if there are any changes to the recipe, and the difference between their sources,
we can use the command like this:

{% highlight bash %}
$ conan report diff --old-reference=zlib/1.3 --new-reference=zlib/1.3.1
{% endhighlight %}

This command will take the latest revision of each version. If Conan finds the package in the cache, 
it will take that; if not, it will search in all available remotes, or the ones passed using the 
*--remote* argument

If you prefer a fine-grained search, **specifying the revision**, you can simply add it to the reference 
like this:

{% highlight bash %}
$ conan report diff --old-reference=zlib/1.3 --new-reference=zlib/1.3.1#b8bc2603263cf7eccbd6e17e66b0ed76
{% endhighlight %}

Another typical case is when we have a new version that we are testing locally, and we need to compare 
these changes. In this case, we can add the path to the new recipe to the command. Here’s an example:

{% highlight bash %}
$ conan report diff --old-reference=zlib/1.3 --new-reference=zlib/1.3.1 --new-path=path/to/new/recipe
{% endhighlight %}

This can also be done for the old reference if you need to specify its location directly too with the 
*--old-path* argument.

## Output Formats

The new command provides three formats for the output, which can be selected using the *--format* attribute.

{% endhighlight %}

The first one, **"html"** format, generates a self-contained **static website**. In this 
web output, **functionality takes priority**: it includes a small index listing the changed files, 
a search bar to look for files, and another to exclude files from view.

<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-07-04/conan-report-diff-web.png"
       alt="conan report diff web interface"/>
</div>
<br>

Next, we have the **"text"** format, it is the default format, and it displays the differences in the classic 
**git diff format**. You can use this to pipe its **output to any diff tool** of your liking. Here’s an example:

{% highlight bash %}
$ conan report diff --old-reference=zlib/1.3 --new-reference=zlib/1.3.1

...

diff --git emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conandata.yml emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conandata.yml
index 1531782fc4..aee6ff7660 100644
--- emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conandata.yml
+++ emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conandata.yml
@@ -1,12 +1,11 @@
 patches:
-  '1.3':
-  - patch_description: separate static/shared builds, disable debug suffix, disable
-      building examples
-    patch_file: patches/1.3/0001-fix-cmake.patch
+  1.3.1:
+  - patch_description: separate static/shared builds, disable debug suffix
+    patch_file: patches/1.3.1/0001-fix-cmake.patch
     patch_type: conan
 sources:
-  '1.3':
-    sha256: ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e
+  1.3.1:
+    sha256: 9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
     url:
-    - https://zlib.net/fossils/zlib-1.3.tar.gz
-    - https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.gz
+    - https://zlib.net/fossils/zlib-1.3.1.tar.gz
+    - https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
diff --git emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conanmanifest.txt emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conanmanifest.txt
index 1698be4430..98bd55b280 100644
--- emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conanmanifest.txt
+++ emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conanmanifest.txt
@@ -1,4 +1,4 @@
 1733936230
-conandata.yml: f273879c230e45f27a54d0a4676fda02
+conandata.yml: 7388d3b9c983326938e00bcdaadb8533
 conanfile.py: 01438040394b477d740d8c84f58cf682
-export_source/patches/1.3/0001-fix-cmake.patch: 133be1fe5e1ccd96b8da0f43ef0314f3
+export_source/patches/1.3.1/0001-fix-cmake.patch: 258ad7382f40ea5933cd48a5501f843d

...

{% endhighlight %}

Finally, we have the **"json"** format, which returns the diff in a **simple structured representation**, 
so that it can be consumed by other scripts. This is perfect if you want to extract the specific diff 
of a file and feed it into some kind of pipeline.

{% highlight bash %}
$ conan report diff --old-reference=zlib/1.3 --new-reference=zlib/1.3.1 --format=json

{
...
"/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conandata.yml": [
    "diff --git emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conandata.yml emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conandata.yml",
    "index 1531782fc4..aee6ff7660 100644",
    "--- emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conandata.yml",
    "+++ emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conandata.yml",
    "@@ -1,12 +1,11 @@",
    " patches:",
    "-  '1.3':",
    "-  - patch_description: separate static/shared builds, disable debug suffix, disable",
    "-      building examples",
    "-    patch_file: patches/1.3/0001-fix-cmake.patch",
    "+  1.3.1:",
    "+  - patch_description: separate static/shared builds, disable debug suffix",
    "+    patch_file: patches/1.3.1/0001-fix-cmake.patch",
    "     patch_type: conan",
    " sources:",
    "-  '1.3':",
    "-    sha256: ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e",
    "+  1.3.1:",
    "+    sha256: 9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
    "     url:",
    "-    - https://zlib.net/fossils/zlib-1.3.tar.gz",
    "-    - https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.gz",
    "+    - https://zlib.net/fossils/zlib-1.3.1.tar.gz",
    "+    - https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"
  ],
  "/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conanmanifest.txt": [
    "diff --git emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conanmanifest.txt emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conanmanifest.txt",
    "index 1698be4430..98bd55b280 100644",
    "--- emxpYi8xLjMuMSNiOGJjMjYwMzI2M2NmN2VjY2JkNmUxN2U2NmIwZWQ3Ng==/Users/ernesto/.conan2/p/zlib7a26308608ec9/e/conanmanifest.txt",
    "+++ emxpYi8xLjMjYjNiNzFiZmU4ZGQwN2FiYzdiODJmZjJiZDBlYWMwMjE=/Users/ernesto/.conan2/p/zlib204752602052d/e/conanmanifest.txt",
    "@@ -1,4 +1,4 @@",
    " 1733936230",
    "-conandata.yml: f273879c230e45f27a54d0a4676fda02",
    "+conandata.yml: 7388d3b9c983326938e00bcdaadb8533",
    " conanfile.py: 01438040394b477d740d8c84f58cf682",
    "-export_source/patches/1.3/0001-fix-cmake.patch: 133be1fe5e1ccd96b8da0f43ef0314f3",
    "+export_source/patches/1.3.1/0001-fix-cmake.patch: 258ad7382f40ea5933cd48a5501f843d"
  ],
...
}


## What’s next

We’re excited to share this new feature with the community, but this is just the beginning! We’d love to hear 
how you use **conan report diff** in your workflows. Your feedback, ideas, and suggestions are key to improving
and shaping the future of this tool. 

You can always [submit feedback here.](https://github.com/conan-io/conan/issues)