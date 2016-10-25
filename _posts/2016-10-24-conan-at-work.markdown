---
layout: post
comments: true
title: "Conan at work"
---


This is a guest post by Nils Brinkmann from the German company Rheinmetall Defence Electronics. You can reach him via [LinkedIn](https://de.linkedin.com/in/nils-brinkmann-93183677) if there are any questions regarding the article.

# Conan at work
A few months ago we took the chance and reinvented our development environment around Conan. The concept and ideas of Conan work nicely in the open source world, but there was not much information on how this could be integrated into a closed source environment. In this post I would like to outline what we did and why we did it.

Rheinmetall Defence Electronics employs more than a thousand developers in the defense sector. I work in a team of 5 developers on integrating 3D engines into simulators. Our projects range from a few hundred man-hours to multi-million dollar projects spanning multiple years. We currently are using Conan only within our team, but the plan is to roll it out at least department wide to more than 150 developers.

## Component structure
Our codebase contains more than 200 small components, each with its designated job. They're sometimes under 100 lines of code, most of them averaging around 1000 LOCs. All these components are depending on each other. This is where Conan helped us the most: Instead of having self-coded mechanisms to resolve the dependency tree we can now use Conan to automatically build everything needed in the right order.

![Diagram: Component dependency diagram](http://yuml.me/fa9949a9)

We set up each component in its own repository: Besides Sourcecode there's a simple `CMakeFile.txt` and a `conanfile.py`. Being able to use a Python-based build-mechanism also helps conquering another big problem: As cool as CMake is, you do not want to do scripting in it. Instead of having to rely on CMake magic we're able to do more complex tasks like code generation directly in the Conanfile now.

## Templates
Besides a few outliers most of our components are structured very simple. 90% of our Conanfiles would look the same, so we figured it would be good to have some kind of template. Conan allows this by using inheritance:

![Diagram: Inheritance diagram](http://yuml.me/16e489b4)

Doing this leaves most of the logic like `build()`, `export()` or `package_info()` in the template, while the component Conanfiles only contain specific info like dependencies or version number. This is also very easy to maintain: If we want to add something to our build-mechanism we just need to modify a single file. Here's an example of how the components Conanfile looks like:

```python
from conans import ConanFile, CMake
import ConanTemplate

class SpecificConanfile(ConanTemplate):
    name = "Bing"
    version = "1.0.12.56d8f23a"
    author = "John Doe"

    def requirements(self):
        self.requires("Foo/1.0.1.d5ee9fad@rde/release")
        self.requires("Baz/1.0.0.ad681ab5@rde/release")
        self.requires("Frob/1.0.8.be290a40@rde/release")
```

## Release strategy
In our old environment we simply had everything in one big repository. This was very monolithic, but also easy to maintain in terms of dependencies: We just needed to make sure that everything in the repo works with each other before committing new code changes. The unflexible nature however limited our ability to scale. Now Conan makes possible what previously would've been a tedious task: To manage everything in small, modular repositories while maintining the dependencies of the components.

To keep everything together we introduced the following release strategy:

- Every component needs to be compatible with the HEAD version of other components
- Every component needs to depend on a specific release version of other components
- Every component should use the newest releases of its dependencies.

This results in our components being in two Conan channels:

- `component/HEAD@rde/CI`: This channel is used for the latest version of each component. As soon as the CI was able to build a new commit, it uploads the component to that channel.
- `component/major.minor.patch.commit@rde/release`: This is the release channel where only released versions of our components are put into. The CI mechanism behind this is probably complex enough to make its own blog post - Essentially only components that are compatible to all their dependencies and their dependers are getting released, making sure that only compatible components are released.

```
> conan search *

Foo/1.0.1.26e92cb8@rde/release
Bar/2.1.15.84145ecb@rde/release
Baz/1.5.0.00cf1aa4@rde/release

Foo/HEAD@rde/CI
Bar/HEAD@rde/CI
Baz/HEAD@rde/CI

Boost/1.59.0@rde/thirdparty
ZMQ/4.1.1@rde/thirdparty
Protobuf/2.6.1@rde/thirdparty
```

## Thirdparty
Modern software is built on the shoulders of giants like Boost, ZeroMQ and Protobuf - Our software is not an exception to this. The difference to the open source world in this case is that a company does not want to depend on external sources like Github or Sourceforge. This results in thirdparty software being hosted internally to always have the sources available when needed. Of course we're trying to help out as much as possible, providing input, feedback and patches whenever we can. In some cases we modified the Conan recipes to use an internal version of a specific component, in other cases we created what we needed ourself.

# What's next?
The described system is in use for a few weeks now, and we're very happy how it turned out. We are no longer working with an inflexible monolithic repository but have a flexible collection of single purpose components that work with each other. However we're far from being finished, I can guarantee that having it in practical use will lead to a lot of optimization. Here are some topics I would like to address in the future:

## Infrastructure
This is a part where we haven't done a lot yet. Currently we're good with just a simple Conan server for everything. Thanks to the decentralized structure of Conan we easily could extend this by adding more servers. We already thought about backup servers, servers for deprecated components or local developer servers for cases where there is no connection to the company network.

## Deployment
We're currently discussing how deployment of our components could be done using Conan. Getting our software onto production systems in a reproducible way is a major struggle. Doing this automated would improve the life for developers, testers and in the end, our customers. Perhaps this is a good topic for a future blog post.

## Making our stuff obsolete
Conan is very young and gets improved every day. We had to create a few custom scripts that in the future hopefully aren't needed anymore. We're trying to open up feature requests and give feedback whenever we can.

## Spread the word
Conan already has gained some momentum, but the more the better. Looking at Nuget or Pip gives an idea of what could be possible. Having everything just one `conan install` away would be a dream come true for any C++ developer.
