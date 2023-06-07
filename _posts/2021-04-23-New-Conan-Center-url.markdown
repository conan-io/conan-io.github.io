---
layout: post 
comments: false 
title: "New ConanCenter Remote URL - Online for BETA Testing" 
description: "ConanCenter has now received a new URL which is now available
for beta testing from ConanCenter users."
---

ConanCenter has received a new URL for use by the Conan client as a remote from
which to resolve packages. It is now available for **BETA** testing by
ConanCenter users. The new URL is here:

* [https://center.conan.io](https://center.conan.io)

To start testing, you can use add a new remote with this url using the following command:

    conan remote add cci-beta https://center.conan.io

The URL for the ConanCenter website has **NOT** changed, it is still here:

* [https://conan.io/center/](https://conan.io/center/)

## BETA Status

While this URL is active and believed to be working and stable, we consider it
to be **BETA** status. That is, we do not recommend that users migrate their
production systems which run Conan to use this URL at this time. Another blog
post will be created when the Conan team considers it stable and removes it from
**BETA** status. This URL should only be used by those developers who intend to
assist the Conan team by experimenting with such things, and providing feedback.

## Limitations

It's important to note that this URL will not be functionally equivalent to the
existing URL of [https://conan.bintray.com](https://conan.bintray.com).
Crucially, the new URL will only resolve "modern packages" and will not resolve
"legacy packages". Simply put, "modern packages" are those packages which were
created from the
[ConanCenterIndex](https://github.com/conan-io/conan-center-index) repository on
Github. By contrast, "legacy packages" refers to everything else. For example,
any packages which were included in ConanCenter via the old Bintray "include in
ConanCenter" button. Another way to describe the difference is to say that, any
package which has any "user/channel" in the package reference is a "legacy
package", and will not be available at this URL.

## Next Steps

If you wish to help the Conan team verify and troubleshoot the new URL in
preparation for the Bintray sunset date, please feel free to add this to your
list of remotes and begin experimentation. Of note, the Bintray sunset will
occur in the very near future, so the sooner you are able to perform tests and
provide feedback, the better. For any issues you encounter, please open a
[github issue](https://github.com/conan-io/conan/issues).
