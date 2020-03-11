---
layout: post
comments: false
title: "Conan 1.23: Parallel installation of binaries, to speed up populating packages in a cache, Add environment variable ‘CONAN_V2_MODE’ to enable Conan v2 behavior."
---

Feature: New general.parallel_download=<num threads> configuration, for parallel installation of binaries, to speed up populating packages in a cache. #6632 . Docs https://github.com/conan-io/docs/pull/1583
Feature: Add environment variable ‘CONAN_V2_MODE’ to enable Conan v2 behavior. #6490 . Docs https://github.com/conan-io/docs/pull/1578
Feature: Implement conan graph clean-modified subcommand to be able to clean the modified state of a lockfile and re-use it later for more operations. #6465 . Docs https://github.com/conan-io/docs/pull/1542
Feature: Allow building dependency graphs when using lockfiles even if some requirements are not in the lockfiles. This can happen for example when test_package/conanfile.py has other requirements, as they will not be part of the lockfile. #6457 . Docs here
Feature: Implement a new package-ID computation that includes transitive dependencies even when the direct dependencies have remove them, for example when depending on a header-only library that depends on a static library. #6451 . Docs here

<br>

-----------

<br>

Have a look at the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html).

Please, report any bug or share your feedback opening a new issue in our [issue
tracker](https://github.com/conan-io/conan/issues) and don't forget to
[update](https://conan.io/downloads.html).
