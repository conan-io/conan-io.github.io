---
layout: post 
comments: false 
title: "Upload Performance Improvements, New IOS and Android Toolchains, New
MsBuildCmd helper, Filter Search Results by Profile"
---

Conan 1.31.0 features a few more significant steps toward our new toolchain
strategy, coupled with a lengthy list of quality-of-life features and fixes.

## Upload Performance Improvements

This release includes a long-overdue change, which represents an optimization
which is so impactful that it effectively amounts to a bug fix for some
use cases. The change is such that the Conan client will now keep the
`conan_export.tgz` and `conan_source.tgz` in the local cache after it is done
extracting the contents. Previously, these files were deleted once extracted.

How is this an optimization? Well buckle up because this is a long and sordid
story. It turns out that its rather common for numerous workflows (including
continuous integration) to perform the command `conan upload *` as a final step.
When using this command in previous releases, every single package would go
through the process of having all of it's `exports` and `sources` compressed
prior to being uploaded. If that included packages with many sources such as
open-source packages like `boost`, `qt`, `opencv`, `ffmpeg`, or private packages
in large codebases, this compression time actually adds up to become a
significant percentage of overall job time. This problem is amplified by the
knowledge that Conan can easily verify that none of the contents have changed,
so these compression and upload steps are known to be completely un-necessary,
making them even more difficult to accept once you understand what's happening.

But wait, it was even worse than that! Many people will already know that for
each Conan package in a repository, there is only ever one `conan_export.tgz`
and `conan_source.tgz` at a time. That is to say, all builds of all
configurations on all platforms use the same sources. However, it also turns out
that the `.tgz` compression results on all operating systems are not equal. The
compressions of identical files can (and often will) result in `.tgz` files with
different checksums on different operating systems! Thus, orgnanizations which
build on multiple operating systems in parallel would have the unfortunate
situation where the `conan upload` commands from different operating systems
would try to upload, and then see that the remote has the sources already, but
with a different checksum than it wants to upload. So, subsequent uploads from
different operating systems would fail. The net result of this was that
virtually everyone in this situation added `--force` to their upload to bypass
the errors. But then, the net result of that was that build servers would
repeatedly take turns re-uploading the "same" `.tgz` files over and over due to
checksum mismatch. This also means that if you had two operating systems
uploading to a remote, which one uploads the "last" `.tgz` that remains on the
remote after the job is effectively random . So, the next time any user or CI
job with the other operating system(s) installs the package, the re-compression
step before a re-upload would always result in a new checksum. So, lots of
workflows ended up using `--force` when it should not have been necessary.

The good news is that this is now largely fixed moving forward. Now that Conan
will keep the `.tgz` files in the cache, the re-compressions and re-uploads will
be effectively skipped as explained before. Also, while the Conan team was
unable to fix the fundamental problem that different operating systems will
create `.tgz` files with different checksums, there is a workaround to solve the
remaining problem. That is, the problem where parallel build servers on
different operating systems take turns re-uploading and overwrite the `.tgz` on
the server. Now, these CI jobs can be reconfigured to start with a single
"stage" which performs `conan export` and `conan upload`, putting a single pair
of `conan_export.tgz` and `conan_source.tgz` on the remote. This stage can then
be followed by any number of parallel build stages which do `conan install` with
the `--build` flag (or equivalent). Those stages will then download and share
those `.tgz` files. Then, crucially, when they all reach the `conan upload`
command, they will all have identical `.tgz` files, so the redundant uploads
will all be skipped.

## New iOS and Android Toolchains

Just like our past several releases, this release continues to make progress on
our Toolchain initiative. This time, we've made two big additions with POC's
for both iOS and Android. For both of these toolchains, we've based the POC's on
the use of CMake, but plan to explore the alternatives in the future after we
have some feedback on these preliminary implementations. Cross-building for
these mobile platforms is one of the major use-cases for Conan, so we believe
this step is pretty significant in maturing the toolchain abstraction.

## New MsBuildCmd Helper

In the previous release, we've included a POC of the new `MsBuildToolchain`.
This was part of the effort to restructure the way we interact with `MsBuild`.
This release contains another part of that effort which is the new `MsBuildCmd`
helper, intended to work alongside the `MsBuildToolchain`. The predecessor to
the `MsBuildCmd` helper is the `MsBuild` helper. Let's talk about that briefly
before we explain the differences with `MsBuildCmd`.

The original `MsBuild` helper was focused on providing maximum convenience with
minimum ceremony in the form of a single python class with many member
functions. It handled three distinct responsibilities:

  1. Handle the complex task of finding and executing the Microsoft tools,
     including the `vcvars` and `vsdevcmd` scripts, `vswhere.exe`,
     `msbuild.exe`, and choosing of the appropriate version passed to Conan in
     the `compiler.version` setting.

  2. Ensure that the following primary `settings` are passed to Conan via the
     command-line arguments:

     * `/p:Configuration` (Mapped from `build_type` in Conan)
     * `/p:Platform` (Mapped from `arch` setting in Conan)
  
  3. Ensure that the following secondary `settings` are passed to Conan via a
     `.props` file:

     * Visual Studio runtime (Mapped from `compiler.runtime` in Conan)
     * Visual Studio platform toolset (Mapped from `compiler.toolset` in Conan)
     * C++ standard (Mapped from `cppstd` setting in Conan)
  
While slightly oversimplified, this perspective on the `MsBuild` helper makes
it very easy easy to explain how the new `MsBuildCmd` helper is distinct, and
how the `MsBuildToolchain` factors into the equation. Simply put, `MsBuildCmd`
is completely focused on numbers 1 and 2 above. `MsBuildToolchain` is completely
focused on number 3 above.

*Note:* The configuration item "Visual Studio platform toolset" has been removed
from the toolchain in this release and will no longer be set by Conan at all.

This separation of responsibilities might not seem
that significant, but internally it allows us to address and resolve a wide
variety of actual bugs as well as serious UX issues which have been raised over
the past three years.  

## Filter Search Results by Profile

One of the most common errors which comes up regularly for packagers and users
is the following error:

```log
ERROR: Missing prebuilt package for 'package/version@user/channel'
Try to build it from sources with "--build package"
Or read "http://docs.conan.io/en/latest/faq/troubleshooting.html#error-missing-prebuilt-package"
```

Technically speaking, this error means precisely what it says. A prebuilt binary
was requested but not found in the local cache, nor any of the configured
remotes. However, from a user-experience perspective, this error typically
indicates one of two scenarios, which typically indicate one of two next-steps:

  1. The user is building a unique configuration for which they know that
     binaries will not be found. In this case, they have forgotten to include
     the necessary `--build` flag, and the suggestion in the error message is
     relevant, correct, and extremely helpful.

  2. The user is building a common configuration for which they expected
     binaries to be found. In this case, it is typically implied that they
     expected those binaries to be built and uploaded to a remote repository by
     a continuous integration (CI) service. Here, the suggestion in the error
     message would allow them to work around the problem, but indicates some
     other problem or prior failure in the CI service. The problem might be that
     the CI job failed. More often however, the problem is that the CI job built
     the package with an incorrect or incomplete list of build configurations
     (conan profiles).

There have been many github issues and conversations in slack created by users,
mostly surrounding the improvement of the user-experience for this second case.
The reason it needs improvement is that when this extremely common error is
encountered, the next-steps available to the user to resolve it are
time-consuming and rather unpleasant. The user must perform a great deal of
reasoning, investigation, and manual trial-and-error to identify exactly where
the problem lies. The list of questions the user must consider includes:

  1. Did the CI server build an incorrect or incomplete list of profiles?
  2. Did it build all the right profiles but partially fail?
  3. Is my local profile incorrect, or out of date?
  4. If some profiles were built, what is the difference between mine and those?

This last question is very often the first that a user should (and does) ask.
This is because the safest assumption in most cases is that there is something
different or wrong in the local profile being used (otherwise other users could
possibly have been affected, reported the issue, and resolved it). Thus, one of
the most comman tasks in the existing process of diagnosing this error was to
perform repeated calls to the `conan search` command with the `--query`
parameter, changing options and settings until the user could answer the last
question listed above. This release provides an alternative way to perform this
task.

In order to use the new feature, the user manually performs a search of the
available binaries for the package that has produced the error, but this time,
without the `--query`. This is similar to the old process, but now the user adds
add `--html` flag to produce the HTML output. Then, the user can open the
generated HTML output in a web browser. Finally, the user can leverage the new
feature, by copying the "effective profile" from the failed `conan install` or
`conan create` log and pasting it into a new dialog box on the search results
web page. At first, this will show empty results, because we're pasting in the
profile for a binary which we already know does not exist. However, now the user
can perform their trial-and-error by adding and removing profile lines in the
dialog box and analyzing the HTML GUI instead of repeated calls to the `conan
search` command and looking at the results in the terminal. We hope that many
users find this workflow preferrable.

Here is a screenshot of the new input box in the search results page.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-11-05/search-filter-by-profile.png"
        align="center" width="100%" height="100%" alt="Filter by profile"/>
</p>

## Other Notable Features

This release also featured several other significant features:

* `conanfile` has been added as an argument to `pre_download_package` and
  `post_download_package` hooks.

* The `conan info` command learned how to output some new fields. This includes
  the relatively new `provides` and `deprecated` attributes from the
  `conanfile.py`. It also learned how to render package revisions when the
  revisions feature is enabled.

* The `CONAN_LOGIN_ENCRYPTION_KEY` has been added to provide an obfuscation
  mechanism intended for continuous integration server logs. In several places
  (including this blog), we emphasize that this does not constitue a secure
  encryption mechanism, and is intended for a very narrow and specific purpose
  which is explained in the documentation.

* `conan config install` can now install a single file.

-----------
<br>

Besides the items listed above, there was a long list of fairly impactful bug
fixes you may wish to read about.  If so, please refer to the
[changelog](https://docs.conan.io/en/latest/changelog.html#oct-2020) for the
complete list.

We hope you enjoy this release, and look forward to [your
feedback](https://github.com/conan-io/conan/issues).
