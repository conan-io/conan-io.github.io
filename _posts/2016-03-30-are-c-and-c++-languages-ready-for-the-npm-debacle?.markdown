---
layout: post
comments: true
# other options
---


["I’ve just liberated my modules”](https://news.ycombinator.com/item?id=11340510) has created great concerns in the node/javascript community, and with reason.

Are the C and C++ languages communities ready for such problem? The short answer is yes. The problem is that we are ready because we don’t have such a dependency on a central repository hosting 99% of the existing OSS libraries we depend on. So we are not there yet.

Some might argue that this is not a problem, but it is. I have largely used Maven for java and NPM for javascript, and it is extremely convenient. Handling dependencies in those languages is order of magnitudes simpler than in C and C++. I don’t want to enter in polemics about system package managers (they are not the solution, but that is a different post :). 

Conan is there to try to fill this gap. I think this is a good opportunity to explain some of the design decisions about it, and what security and other reasons have affected conan current design:

<h2>Allowing removal of packages</h2>

Some people argue that packages should not be allowed to be removed, even by the authors. This is only half part of the story, they are concerned only about they role as package consumers but not as creators. This approach might work if you are already Maven Central, but guess what, it doesn’t work for a young project. We already experienced that: package developers want to be able to totally remove their contributions, and they will be very upset if not allowed. And if there are not package creators contributing, there are not packages, and the platform has little value. So, it is absolutely necessary to allow it, otherwise the platform will never bootstrap enough. But this is not a problem per se, if it can be effectively managed.

<h2>Using namespaces.</h2> 

Yes, we (in C++) love namespaces. They are necessary, vital. Why in heaven should someone just install “string1.0” from a package manager? So packages in conan are referenced by the name and version of the package, but also the author and the channel, something like Boost/1.60@boostorg/stable. So when you depend on it, you are certain about the creator of the package. If the author of the package decides to remove the package, it cannot be replaced by anyone else.


**conanfile.txt**

{% highlight conf %}

[requires]
zlib/1.2.8@lasote/stable

[generators]
cmake

{% endhighlight %}

<h2>Forking/copying dependencies</h2> 

With conan there are two ways to create packages from others:

- If they have a repository with the package recipe, just clone it and export it under your user name. You can generate your own binaries locally or in CI, and upload your own recipe and packages. They are a full copy, it will not be influenced by removal of the original source


{% highlight bash %}

git clone https://github.com/lasote/conan-zlib.git
cd conan-zlib
conan export anotheruser/mychannel

{% endhighlight %}

- It is also possible to just copy/rename existing packages, including binaries, with the command “conan copy”


{% highlight bash %}

conan copy zlib/1.2.8@lasote/stable anotheruser/mychannel

{% endhighlight %}


- Then, just change the namespace:


**conanfile.txt**

{% highlight conf %}

[requires]
zlib/1.2.8@anotheruser/mychannel

[generators]
cmake

{% endhighlight %}


<h2>Distributed approach</h2> 

Conan is designed to be distributed, so if the origin or availability of packages from external sources is a concern, setting up your own conan server is very simple. Read your dependencies from other origins (as conan.io), then upload them to your own conan server, and you are independent from the outside world. 


<h2>Package recipes and binaries manifests</h2>

Yes, artifacts must have a signature. Now, we generate manifests (a file list with each file SHA) inside each package recipe and each package binary. We use those manifests to resume failed uploads, or to check for upstream updates. As the generators provide the paths for your project dependencies, matching the retrieved manifests against predefined ones shouldn’t be difficult.

**conanmanifest.txt of a ZMQ example package**

{% highlight txt %}

1458596605
lib/libzmq-mt-s-4_1_1.lib: 1852cee65e1676e1d93ccdfc501788b0
FindZeroMQ.cmake: 5054e9b947b5243b7ebc0c2fa652f7dd
include/zmq.h: 2330e48f210fc4771ea5d45c66905be3
conaninfo.txt: 7637eaae9c8bce1d5c3e053fd8c24dfb
include/zmq_utils.h: 2a2d13497628f0e24ab63cbe48d49aa4

{% endhighlight %}


We think that with these measures, conan is quite prepared to avoid such possible problem in the future. This is not a post to claim that we are good, smart, or whatever, just sharing some of our design ideas. Do you have any other ideas? Contributions, suggestions? Please tell us, or even better, enjoy our community of contributors with some pull requests :D

