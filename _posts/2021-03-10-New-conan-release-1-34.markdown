---
layout: post
comments: false
title: "Conan 1.34 : New lockfile feature \"bundles\", Resource shift to Conan
V2.0, Merged Tribe Proposals"
meta_title: "Version 1.34 of Conan Package Manager is Released"
meta_description: "Conan 1.34 brings a few feature additions and a handful of
bug fixes. New lockfile feature \"bundles\", Resource shift to Conan V2.0,
Merged Tribe Proposals"
---

Conan 1.34 brings a few feature additions and a handful of bug fixes. The short
list of features is not for lack of effort or time, but instead reflects a
milestone in the Conan team. This was the first release cycle where the majority
of developer time and effort was spent working on major changes in Conan 2.0,
many of which have been planned for multiple years. So, this post will focus on
highlighting some of the major roadmap items under construction right now. Also
of note, this includes one major piece of feedback from the [Conan 2.0
Tribe](https://conan.io/tribe.html) which we will discuss.

## conan lock bundle

Before talking about Conan 2.0, let's briefly summarize the one major feature
addition in this release, that is the concept of a "lockfile bundle". Lockfile
bundles are intended to help CI/build engineers handle collections of lockfiles
in a more safe and efficient way. The related commands can be found by running:

- [`conan lock
bundle --help`](https://docs.conan.io/en/latest/versioning/lockfiles/bundle.html)

**Note**: Lockfile bundles and related commands are all __experimental__.

Here's an example of the syntax for creating a bundle:

```bash
    conan lock bundle create app1_windows.lock app1_linux.lock app2_windows.lock
    app2_linux.lock --bundle-out=lock.bundle
```

Here is a diagram to illustrate the data structure that gets created inside the
file "lock.bundle"

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-10/conan_lock_bundle.png"
     align="center" alt="Conan Lock Bundle"/>
</p>

The concept of a lock bundle aims to address two problems we've discovered in
the management of lockfiles at scale in enterprise codebases.  

First, it enables a single "build" with Conan to update multiple lockfiles when
those lockfiles share a common dependency and `package_id` for that dependency.
For example, in the diagram above, `app1_windows.lock` and `app2_windows.lock`
depend upon the same `package_id` for `pkga/0.1`. The new lock `bundle` makes it
possible to create CI workflows which rebuilds the `pkga/0.1` for that
`package_id` once, and updates all lockfiles which feature it when complete.

Here's an example of the syntax to rebuild `pkga` once and update both lockfiles
using the bundle:

```bash
    conan install pkga/1.0 --build pkga \
        --lockfile app1_windows.lock \
        --lockfile-out app1_windows.lock
        
    conan lock bundle update lock.bundle
```

The motivation for this is that it is extremely common to have multiple
lockfiles which share packages with identical `package_id`. Ever since lockfiles
were released, the typical approach to using them in CI was to run
1-build-per-lockfile. But, when rebuilding "per-lockfile" in such cases,
redundant rebuilds would virtually always occur, causing a number of different
scalability issues. With "bundles", CI engineers can now configure jobs to build
"per-package-id", and get the same exact benefit, while avoiding these issues.

Second, "lock bundles" enable the calculation of a `build-order.json` file for a
collection of lockfiles. This was important for CI workflows, because CI jobs
generally rebuild multiple configurations using multiple lockfiles in a single
"run". At the end of such CI jobs, the ideal last step is to use Conan to
produce a `build-order.json` file to determine the next "packages" which need to
be rebuilt, and map those to the CI jobs that need to be triggered.  However,
`build-order.json` was previously only produced on a "per-lockfile" basis, and
build-orders for different lockfiles often yield different "next steps". So,
with this feature, we can now produce a "build-order" which takes into account
all the lockfiles in the bundle. The big payoff here is that it enables maximum
parallelization of CI jobs, and lets the Conan dependency tree drive the CI
workflow process.

## Resource Shift to Conan V2

Within the last month, the Conan team has now officially turned the majority of
its focus on development time toward V2. With that said, it's probably also a
good opportunity to set some expectations. Keep in mind that most of the major
changes and refactors that have been planned for V2 are currently still "just
plans". They must now be fully developed and tested in conjunction with all the
other changes. Furthermore, many of them will need to be backported to Conan
1.x so that there is a safe migration path between Conan 1.x and 2.x.  That is
to say, it's not just a matter of writing the code to add features.  It includes
new requirements, new concepts, new abstractions, and LOTS of trial and error.
Nonetheless, we plan to stay aggressive and focused until it's done.

## Conan 2.0 Tracking

If you want to follow along with the progress, or even contribute, this is
perhaps the best link to track Conan 2.0 progress in general:

<https://github.com/conan-io/conan/pulls?q=is%3Apr+milestone%3A2.0+>

Here are some highlights which map to some of the most active work being done
right now:

{:class="table table-bordered small"}
| Project                              | Pull Requests                                                                               |
|--------------------------------------|---------------------------------------------------------------------------------------------|
| __Multiple Revisions in Local Cache__| <https://github.com/conan-io/conan/pull/8510>                                               |
| __Layouts and Editable Packages__    | <https://github.com/conan-io/conan/pull/8554><br><https://github.com/conan-io/conan/pull/8286> |
| __Logging handler support__          | <https://github.com/conan-io/conan/pull/8141>                                               |
| __New local development flow__       | <https://github.com/conan-io/conan/pull/8589>                                               |
| __Environment propagation re-write__ | <https://github.com/conan-io/conan/pull/8534>                                               |
| __Upload command re-write__          | <https://github.com/conan-io/conan/pull/8535>                                               |
{:.table-striped}

The "New local development flow" is unique in this list. It represents a
significant change to Conan which was first described in a formal document, and
sent to the [Conan 2.0 Tribe](https://conan.io/tribe.html) for feedback. The
feedback was generally supportive, but included a fairly unanimous suggestion
for a major change to one of the details, which was accepted into the final
design plan. This was a highly successful exercise of the Tribe, and the exact
reason it was formed.

Again, the list of work for Conan 2.0 above is just a few of the items which are
actively being worked on right now. There's a pretty significant number of
pull-requests which have already been merged, and a lot more to come. We'll
almost certainly be focusing future blog posts on increasing awareness of new
pull-requests as they come about in a draft status, so be sure to stay tuned!

Remember, there is no better time to share any valuable insight or use cases you
might have with the Conan team than yesterday.  However, today is a close
second, so please do consider reaching out and providing feedback on these new
features and changes if you have not already.

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#march-2021) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
