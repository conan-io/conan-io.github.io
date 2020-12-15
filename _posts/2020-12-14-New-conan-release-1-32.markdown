---
layout: post 
comments: false 
title: "Conan 1.32: New validate() Method, First configurable Generator (MSBuildDeps), 
Renamed Multiple Toolchains & Generators, 2 New Meson Classes, Improve Lockfile
Support for Private Requirements, Support for build_requires to Affect package_id (Workaround)"
---

Conan 1.32.0 features a new strategy for defining, detecting, and handling
invalid configurations. This includes a new method named `validate()`, and a new
`package_id` mode named `BINARY_INVALID`.  It also includes a big refactor of
our future toolchain and generators strategy, some new capabilities of
generators in general, and 2 new classes for Meson (a Toolchain and a build
helper class). We've also added some subcommands for dealing with recipes and
packages which have no remote associated, and made it possible to deal with
lockfiles which contain the same package multiple times in the graph (possible
via private requirements).  Finally, we're excited to show a proven workaround
which satisfies a long-standing and high-priority request, which is to
optionally include `build_requires` into the `package_id`.  There are some
important side-effects and caveats, to be aware of, so read on to learn about
the details.

## New Strategy for Invalid Configurations

In recent months, there has been growing discussion in the community about some
awkward challenges surrounding the definition, detection, and handling invalid
or impossible configurations. Historically, the general recommendation has been
to handle these cases by raising `ConanInvalidConfiguration` errors during the
`configure()` method, but in practice there are some checks which simply cannot
be run there because of the state of the dependency graph. Also, with the
`compatible_packages` feature, there are cases when a recipe might not be
able to build, but might be configured to provide a compatible package instead.

The existing workarounds for these cases were unfortunate, so we've now added
some first-class-features around them. The first is to add a [new method to
Conanfile](https://docs.conan.io/en/latest/reference/conanfile/methods.html#validate)
named `validate()` method which executes after the graph has been fully
evaluated solving the previous problems. The second is to add a new `package_id`
mode named `BINARY_INVALID`.  Moving forward, the `configure()` method should
still be used for actually setting configurations, but the `validate()` method
should take over all responsibility for raising `ConanInvalidConfiguration`
errors. In these cases, the `BINARY_INVALID` is now reported as the state in the
output of `conan info` command, as opposed the previous behavior which was for
this command to fail with return code 6. This is a major improvement as some
automation cases (such as ConanCenter) use `conan info` to make decisions about
what to build, and parsing `json` output is more desirable than interpreting
return codes.

Here's an example of `validate()` and the output from it

    def validate(self):
        if self.settings.os == "Windows":
            raise ConanInvalidConfiguration("Windows not supported")


    $ conan create . pkg/0.1@ -s os=Windows
    ...
    Packages
        pkg/0.1:INVALID - Invalid
    ...
    > ERROR: There are invalid packages (packages that cannot exist for this configuration):
    > pkg/0.1: Invalid ID: Windows not supported

## Refactoring Toolchains and Generators (and Namespaces)

It's important to highlight that a lot of experimental classes were moved around
into different namespaces in this release. Please refer to the changelog and
docs for all the specifics, but here's a simple summary.

First, we've now exposed a new top-level namespace called `conan`. Experienced
users will recall that previously, virtually all Conan classes and functions
have been exposed to `conanfile.py` under the namespace `conans`. In summary,
there's no longer a reason for the letter `s` which many people have found
annoying. As we prepare for Conan 2.0, we plan to make all existing classes and
functions available under `conan` namespace, and eventually deprecate `conans`.
In this release, we've started conservatively by simply exposing a few brand new
classes and functions under the `tools` sub-namespace. If things go well, we'll
add aliases to existing classes and functions over time.

So, under `conan.tools`, we've created four sub-namespaces:

* cmake
* gnu
* meson
* microsoft

We'll be adding to this structure in the future, and the decision was that
organizing these tools for integrations by "vendor" was a lot more intuitive
than trying to organize them by "purpose" or "functionality". Such strategies
have proven to be awkward in the past because so many tools and utility
functions are multi-purpose.

We've started using these directories by putting all the respective toolchains
classes into in them.  We've also begun moving forward on a new naming
convention for generators, starting with the experimental `msbuild` generator.
It has been renamed to `MSBuildDeps`, and we'll talk more about why we did this
shortly. We've also created a new generator named `CMakeDeps` in the `cmake`
directory, however, it's really just an alias which redirects to the
`cmake_find_package_multi` generator. We've already been promoting that as the
top recommendation for most use-cases of `CMake` generators, and we'll now be
promoting that people use it from this new import and new name (`CMakeDeps`).
Also, we've added a new toolchain called `MesonToolchain`.

## How Toolchains Helped Generators Evolve

You may have also noticed that the new generator names listed have capital
letters in them. Indeed, this represents the start of a pretty important change
of convention. Historically, generators have had capital letters in the `class`
name, and then had a lowercase `name` field which was an alias used in recipes,
profiles, and the CLI. We're now starting the process of deprecating the use of
lower-case generator aliases, and migrating to the use of the literal `class`
name as the identifier in all places where Generators are referenced. Change
like this can be difficult to adapt to, and this might appear to be purely
cosmetic, so I think this calls for some explanation.

Our work on toolchains has had a major impact on our future plans for
generators. We created the abstraction of the "Toolchain" class and the
corresponding method in `conanfile.py`, to distinguish two separate concerns.
"Generators" are now intended to focus on information "related to dependencies",
and "Toolchains" are intended to focus on build variables which are related to
"everything else" (which means mostly platform, compiler, and linker settings).
As we started to work with the Toolchains as simple classes and function calls
within a dedicated recipe method, it was an obvious thing to give the
constructors and methods of these toolchains parameters. This made the
toolchains flexible and configurable, and allowed us to start doing some cool
stuff with them. We then realized that if we did the same thing with generators
(creating some new ones which took paramters and were configurable), then we
could probably solve a bunch of long-standing generator-related feature
requests, and with relative ease.

This seemed to be a pretty amazing revelation... almost too good to be true.
Rarely do big wins come easy, so we looked back to figure out why this hasn't
occurred to us during the process of trying to resolve some of those feature
requests. Also, how is the current Generators implementation unique, and why
again is it designed the way it is. We found some reasons which I'll now
summarize, but simply put, it's not enough to prevent us with moving forward
with configurable generators. We're still working on proving the basics
internally, and hope to have something significant to share soon.

The primary "magic" of generators in Conan is the way that they are declared in
recipes and implicitly "depended upon", and invoked at the appropriate time. The
benefit really boils down to a super concise declarative syntax. However, this
little bit of magic and convenience actually comes at a major cost.  There are
fundamental internal challenges with it's implementation which cannot be fixed
without breaking changes. In retrospect, the magic probably was not worth the
cost. The approach being explored now doesn't suffer any of those major
consequences, has the promise of providing "configurable generators", and might
not even be any more verbose than what we have today.

The main snag with implementing configurable generators right now is that
generators can be invoked in two contexts: in-recipe and on-demand (with `-g
generator` or in a profile). Most of the "configurability" people have asked for
historically is surrounding the in-recipe use of Generators, and making them
normal python classes with methods seems like it will have all the benefits one
might expect there. However, its difficult to imagine whether or not the
configurable generators will make sense when used on-demand. At this time, we
don't plan to support an extra command-line syntax for passing paramters to the
generators in this context (although we have thought about it already). So,
we'll have to see if the majority of generators are useful in the on-demand
context only using default values. They probably will, and it shouldn't be any
worse than one of the existing generators which has no configuration at all.

## Toolchain-Related Methods Renamed

The revelation process described above also allowed us to step back and
recognize a simplification that could be made.  While Toolchains and Generators
are definitely distinct categories of information from the perspective of the
build, we've decided that they're not substantially different in terms of their
essence in Conan. As such, we've decided to refactor the implementations around
them to treat them in a similar way.  This dramatically reduces internal
complexity and increases consistency in a several ways, but simply put, it's
less to learn.

The overall idea here is that the process for both things is still the
same:

* Analyze the configuration and dependency data Conan has gathered
* Generate files
  
They're just two sub categories of the same thing. So, at that point, it seemed
fairly obvious to rename the still-experimental `def toolchain()` method in
`conanfile.py` to `def generate()`. For the same reasons, we decided that the
"primary interface method" to trigger the generation of files on both Toolchains
and Generators moving forward should just be `generate()` as well. So, for
toolchains, the old method `write_toolchain_files()` has been renamed to
`generate()`.  It's simple, consistent, and descriptive. Here's an example of
using the two together:

    from conans import ConanFile
    from conan.tools.microsoft import MSBuildDeps, MSBuildToolchain

    class Pkg(ConanFile):
        settings = "os", "compiler", "build_type", "arch"
        requires = "boost/1.72.0", "poco/1.9.4"
        
        # The generate method creates files that the build can use
        def generate(self):
            # generates conan_boost.props, conan_poco.props for dependencies
            # and conandeps.props that aggregates them
            deps= MSBuildDeps(self)
            deps.generate()
            # generates conantoolchain.props from current settings
            tc= MSBuildToolchain(self)
            tc.generate()

Furthermore, going back to the topic of deprecating of the lower-case `name`
field/alias of generators, we realized that we did not implement an equivalent
feature in toolchains. This was largely because it really only represented a
layer of abstraction and redirection which was more confusing than it was
valuable. Looking back at Generators, we felt the same way. Sometimes you want
to de-couple `class` name from "usage name" of something, but this no longer
feels like one of those times. But it's not only cosmetic, it created some
awkward design questions when implementing configurable generators which just
went away if we chose to use the `class` name. Simpler was just better in this
case on multiple fronts.

## Including build_requires in package_id (Experimental)

There has been an outstanding feature request for a **long** time which has seemed
virtually un-solvable in the current version of Conan without major breaking
changes. That feature request is to make it possible for `build_requires` to
affect `package_id`.  Users have been wanting this for a very long time, and the
existing workarounds are unacceptible in a number of cases. Sadly, a first-class
fix is still likely only going to happen in Conan 2.0. However we've discovered
a new workaround which may achieve the goal for some use-cases, and which has
actually existed under the radar for a very long time, and is substantially
different from previously known workarounds. Of note, before we create
too much excitement for those affected, there are a few caveats and challanges
with this workaround which might negate it's use.

Nonetheless, here's the strategy. If you have a `build_requires` declared in a
recipe, and you want it to affect the `package_id` of the package, simply add it
as a `python_requires` as well. That's it, that's the strategy. It works because
Conan includes `python_requires` in `package_id` calculations already, and it
doesn't cause any problems because it just discards and does not use the
`conanfile.py` for the `build_requires`. Again, it seems good to be true, so
lets highlight the biggest problem.  If you leverage your `build_requires` via
profiles, this won't work for you at all. It's unfortunate, because that
describes a lot of use-cases for `build_requires`, but not all. In any case, we
think some users will be able to use this strategy, so we wanted to announce the
discover here.  We've also included an example in [the docs](https://docs.conan.io/en/latest/devtools/build_requires.html#making-build-requires-affect-the-consumers-package-id).

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#dec-2020) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
