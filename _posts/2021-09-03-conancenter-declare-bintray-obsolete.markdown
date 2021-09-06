---
layout: post
comments: false
title: "ConanCenter: Old Bintray remote is over. Check you are using the right one!"
meta_title: "ConanCenter: Old Bintray remote is over. Check you are using the right one!"
description: "Old Bintray remote for ConanCenter will be deprecated on November, make sure
you are only using the new remote https://center.conan.io"
meta_description: "Old Bintray remote for ConanCenter will be deprecated on November, make sure
you are only using the new remote https://center.conan.io"
---

It's been some months (May 1st) since we released a new remote for ConanCenter with a more
resilient and scalable architecture. We announced those changes on April and we've been 
following the steps announced [here](https://blog.conan.io/2021/04/23/New-Conan-Center-url.html) 
and [here](https://blog.conan.io/2021/03/31/Bintray-sunset-timeline.html). So far the transition 
went smoothly and we are happily serving many thousands of requests every day from this remote.

On June we [announced](https://blog.conan.io/2021/06/10/New-conan-release-1-37.html) that the 
new URL (`https://center.conan.io`) becomes the new default, and on July 1st we stopped uploading 
new packages to the old remote (`https://conan.bintray.com`), and encouraged users to migrate and 
use only the new remote (`https://center.conan.io`). During the last week, around 90% of the 
traffic is using only the new remote.

Old Bintray remote is still running just to avoid breaking users while they migrate to the new 
remote and away from legacy packages (those with `@user/channel`). These packages are already 
considered deprecated and they are not maintained anymore; their corresponding repositories 
have been archived and they won't get new improvements. All of them should be already contributed 
to [`conan-io/conan-center-index` repository](https://github.com/conan-io/conan-center-index) and 
available (without `@user/channel`) in the new default remote.

In September (v1.40), the Conan client will not include the old remote as default anymore and 
only `https://center.conan.io` will come configured by default. If you want to keep using the old 
one, you will need to add it explicitly.

## Call To Action - Stop using legacy remote

Things are moving forward and this blogpost is one more explicit reminder: old remote is frozen 
and new packages are only available via the _new_ `https://center.conan.io` URL. Please, check 
the remotes you are using (`conan remote list`) and check your build removing the legacy URL. 
Only the new remote (and your personal/company repositories) should be used.

Check this change in your CI builds as well, specially if you are using an older Conan client 
or you are retrieving your configuration from a shared repository. We really encourage you to 
change this configuration and adapt your CI processes as soon as possible.
