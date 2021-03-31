---
layout: post
comments: false
title: "Bintray Sunset - Timeline for Conan Users"
meta_title: "Bintray Sunset Timeline Summary for Conan Users"
meta_description: "A summary of dates and times for key milestones of the Sunset
of JFrog Bintray which are relevant to users of Conan Package Manager"
---

On February 3rd, [JFrog officially announced the planned sunset of
Bintray](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/),
the popular binary hosting service. Many users of Conan have been using Bintray
to host their own Conan repositories, and many Conan packages in ConanCenter are
still hosted on Bintray.  We discussed the impact of the sunset for Conan users
in [a previous blog post]({{ site.baseurl
}}/2021/02/05/JFrog-announces-sunset-bintray.html), and gave some
recommendations for impacted users. However, this post intends to provide
additional details about the migration plan and related timelines to help ensure
that those affected have the best information possible.

## May 1, 2021 - Critical Date - All Conan Repositories Deleted from Bintray

For Conan users storing their own custom packages on Bintray today, the most
important date to be aware of is May 1, 2021. After this date, there will be no
way to recover Conan repositories or their contents from Bintray. All desired
packages must be migrated to another location prior to this date or they will be
lost.

## Bintray Repository Migration Plan for ConanCenter

All packages which are physically hosted on Bintray, and which are "included"
(aka "linked with") ConanCenter will be migrated to a new Conan repository on
the dedicated Artifactory server for ConanCenter. According to the timeline
specified below, a redirection process will transparently redirect traffic away
from Bintray, and to the new repository.

## Timeline Updates

In the coming days and weeks, this post will be updated whenever time planned
dates are changed. If you are a Bintray user and are planning your own
activities related to these dates, please refer back to this blog for such
updates.

## Key Dates

### April 7-8, 2021 - Maintenance - Conan Center Affected

We will have some backend maintenance related to the migration.  On these dates,
users should expect ConanCenter to be effectively unavailable.

### April 11, 2021 -  Maintenance - Packages Linked to ConanCenter Frozen

Updates to packages made after this date in public Conan repositories which are
linked to ConanCenter may not be migrated to the new ConanCenter repository on
Artifactory.

### April 12, 2021 -  Maintenance - All Conan Repositories Affected

We will have some short service brown-outs to remind users about the services
that are going away on May 1st. (Specific hours will be advertised in the
[Bintray status page](https://status.bintray.com/).)

### April 26, 2021 - Maintenance - All Conan Repositories Affected

We will have some short service brown-outs to remind users about the services
that are going away on May 1st. (Specific hours will be advertised in the
[Bintray status page](https://status.bintray.com/).)

### May 1, 2021 - Bintray Sunset - All Conan Repositories Affected

After this date, the Bintray service will be taken offline. For Conan users,
there will be no way to recover Conan repositories or the packages within them
from Bintray. All desired packages must be migrated to another location prior to
this date or they will be lost.

## Next Steps

To reiterate the most important takeaway from this blog post, all Bintray users
are advised to download all packages they need and store them in their own
infrastructure before that date.  After that date, they will not be available,
and cannot be restored.

If you have any questions, please feel free to reach out to the Conan team
directly by creating a [github issue](https://github.com/conan-io/conan/issues).
