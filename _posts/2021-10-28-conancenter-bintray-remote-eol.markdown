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
and today it is time to announce that its end of life has been set for the 30th of November of 2021.

We have been monitoring the data transfer of the old Bintray remote (`https://conan.bintray.com`) and we can say
that its usage has been significantly decreased. Since the removal of the remote as default in Conan 1.40.0 (September 6th, 2021), the trend on data transfer ramped down and today it is marginal compared to the current default remote (`https://center.conan.io`).

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2021-10-28/conancenter-data-transfer.png" align="center" alt="ConanCenter remotes data transfer"/>
</p>

## conan.bintray.com EOL timeline

Before the shutdown of the remote, we will perform two brownouts (two weeks and one week before the shutdown) to warn
about its EOL to anyone still using it. During those brownouts, the service will be completely offline and Conan clients using the remote (`https://conan.bintray.com`) will fail to contact the remote.

- #### 1st brownout: November 16th

  From 14:00 UTC / 15:00 CET to 20:00 UTC / 21:00 CET (6 hours).

- #### 2nd brownout: November 23rd and 24th

  From November 23rd 14:00 UTC / 15:00 CET to November 24th 14:00 UTC / 15:00 CET (24 hours).

- #### Shutdown: November 30th

  At 14:00 UTC / 15:00 CET.

## center.conan.io as the only official remote

With the shutdown of the old Bintray remote, we finish the transition since the Bintray sunset and the one and only official
remote for ConanCenter is `https://center.conan.io`, configured as `conancenter` by default in the Conan client. Note that this
remote will continue working without issue during the dates specified above.

This also means that **we will no longer be serving packages with `@<user>/<channel>`** from ConanCenter. Packages **without user and channel** are identified as open source packages contributed by the ConanCenter community to [conan-center-index](https://github.com/conan-io/conan-center-index).

## Migration steps (if needed)

Anyone affected by this shutdown process should migrate to the official remote `https://center.conan.io` to continue
installing packages from ConanCenter.

If you are running Conan 1.40.0 or later or you are already using the new remote, it should appear at the top of
your remote list:

```bash
$ conan remote list
conancenter: https://center.conan.io [Verify SSL: True]
```

Make sure `conan-center: https://conan.bintray.com` is **not listed** in the above output.

However, if are running a Conan version older than 1.40.0, you can upgrade your Conan version or migrate to the new remote with these steps:

- Remove the old remote:

  ```bash
  $ conan remote remove conan-center
  ```

- Add the new remote to your Conan configuration as default remote:

  ```bash
  $ conan remote add conancenter https://center.conan.io --insert 0
  ```

- Check `conan-center` (https://conan.bintray.com) was removed and that new `conancenter` (https://center.conan.io) is listed
  as first remote:

  ```bash
  $ conan remote list
  conancenter: https://center.conan.io [Verify SSL: True]
  ```
