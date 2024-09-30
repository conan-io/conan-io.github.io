---
layout: post
comments: false
title: "Conan Center will stop receiving updates for Conan 1.x packages soon"
meta_title: "Conan Center will stop receiving updates for Conan 1.x packages soon"
description: "Conan Center will soon stop providing updates for Conan 1.x packages as the platform shifts focus to supporting Conan 2.x."
keywords: "conan, conan2, conan center"
---


Conan 2.0 was released in February 2022 after years in development. Since then, thousands of users and teams have 
adopted Conan 2.0, and the Conan Center Index repository has continued to see significant growth. In 2023, we received 
close to 6000 Pull Requests for recipes. 

Since the Conan 2.0 release, and to facilitate the upgrade path for our users, we adopted the decision to make recipes 
in Conan Center compatible with both Conan 1.x and Conan 2.0.

Porting all recipes to be Conan 2.0 compatible has been a significant effort - aided by community contributors to which 
we are very grateful. This has placed additional pressure on all resources, including our CI compute capabilities. This 
has also given the team valuable insights into how to improve and streamline the CI and review processes.

On Conan 2 release day - we had published binaries for the top 120 most used recipes. Today, nearly 97% of all recipes 
in Conan Center are compatible with Conan 2.

As time has progressed, today the majority of requests to the Conan Center remote originate from Conan 2 users.

**Today we are announcing that before the end of the year, new recipe updates in Conan Center will only be compatible 
with Conan 2. Please read below to see how this might affect you.**

## For Conan 1.x users

### Users accessing the ``https://center.conan.io`` remote via the Conan client

The Conan Center remote will stop being updated for Conan 1.x users. This means that from this date:
- **No new recipe revisions** will be published or visible to the Conan 1.x client.
- **No new versions of libraries** will be published or made available for Conan 1.x.
- **No new recipes** will be published or visible for Conan 1.x.
- All **previously available and published recipes** and binaries will continue to be accessible.
- **No configuration changes** are required. After the stated deadline, the Conan Center remote for Conan 1.x users 
will be frozen at its current state and will not receive any further updates, as detailed above.
- Under **exceptional circumstances**, updates may be published for security reasons.

### Users maintaining their own fork of the conan-center-index git repository

- There will be a branch that contains the **frozen versions/revisions** on the aforementioned date - details will follow shortly
- From then on, we will **no longer guarantee that recipes remain compatible with Conan 1.x** in the main (master) branch.

## For Conan 2.x users

From the date of the switch, new recipe updates will be uploaded internally to a new repository. New details will be 
announced soon, the team is working in two possible solutions to facilitate this transition:
- Requests coming from Conan 2 clients will be able to see the up-to-date revisions, without impacting legacy Conan 1, 
and without requiring any configuration changes for Conan 1 users.
- A new remote endpoint will be made public

## Contributions in the conan-center-index repository

- Coinciding with the switch, the Conan Center CI service will only validate recipes and publish packages only for Conan 2
- It will no longer be a requirement to retain Conan 1.x compatibility - contributors are free to use Conan 2-only 
features where it aligns with the PR goal
- **We emphatically ask community contributors to not submit pull requests to perform refactorings to remove old logic or 
mass recipe modernizations**. We want to avoid overwhelming our CI resources and the review team - and continue 
prioritizing new features, bug fixes, new versions, new platforms and new recipes.
  - Pull requests with recipe modernizations only and no functional changes or bug fixes will not be prioritized, and 
we may ask the contributor to reopen the PR at a later date.
  - Pull requests that perform recipe modernizations alongside other valid changes (functional or bug fixes) may 
experience delays in reviews if the changesets/diffs make it less obvious what is being changed.
  - As usual, opening a large number of PRs in a short time is hugely discouraged and against our guidelines.
- The Conan Center CI service will undergo upgrades to rely on Conan 2 features - further changes will be announced in the near future

For questions or feedback, please follow the discussion in Github.






