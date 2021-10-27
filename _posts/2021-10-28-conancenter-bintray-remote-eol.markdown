---
layout: post
comments: false
title: "ConanCenter: Old Bintray remote EOL set for November 30th"
meta_title: "ConanCenter: Old Bintray remote EOL set for November 30th"
description: "Old Bintray remote for ConanCenter will be shutdown on November 30th, make sure
you are only using the new remote https://center.conan.io"
meta_description: "Old Bintray remote for ConanCenter will be shutdown on November 30th, make sure
you are only using the new remote https://center.conan.io"
---

Back on September 3rd, we announced the [deprecation of the old Bintray remote](https://blog.conan.io/2021/09/03/conancenter-declare-bintray-obsolete.html)
and today it is time to announce that it's end of life has been set for then 30th of November of 2021.

We have been monitoring the data transfer of the old Bintray remote (`https://conan.bintray.com`) and we can say
that its usage has been significantly decreased. Since the removal of the remote as a default in Conan 1.40.0 (September 6th 2021), the trend on data transfer ramped down and today we are serving less than 10% transfer compared to the default remote (`https://center.conan.io`).

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2021-10-28/conancenter-data-transfer.png" align="center" alt="ConanCenter remotes data transfer"/>
</p>

## conan.bintray.com EOL timeline

Before the shutdown of the remote, we will perform two brownouts (two weeks and one week before the shutdown) to warn
about its EOL to anyone still using it. During those brownouts, the service will be completely offline and Conan clients using the remote (`https://conan.bintray.com`) will fail to contact the remote.

- #### 1st brownout: November 16th

  From 14:00 UTC / 15:00 CET to 20:00 UTC / 21:00 CET (6 hours).

- #### 2nd brownout: November 23rd

  From 14:00 UTC / 15:00 CET to 20:00 UTC / 21:00 CET (6 hours).

- #### Shutdown: November 30th

  At 14:00 UTC / 15:00 CET.

## center.conan.io as the unique remote

With the shutdown of the old Bintray remote, we finish the transition since the Bintray sunset and the unique and official
remote for ConanCenter is `https://center.conan.io`, configured as `conancenter` by default in the Conan client. Note that this
remote will continue to work without issue during the dates specified above.

Anyone affected by this shutdown process should migrate to the official remote `https://center.conan.io` to continue to
install packages from ConanCenter.
