---
layout: post
comments: false
title: "It's Time to Deprecate Python 2"
---

## Why are we doing this?

Python 3 has now been out for a long time, and Python 3 compatibility is quite common. Perhaps more importantly, there are beginning to be cool features in Python libraries that only work in Python 3.

As per [PEP 373](https://www.python.org/dev/peps/pep-0373/), Python 2 will be officially deprecated at the end of 2019. More importantly to us, several of our dependent libraries are already deprecating Python 2 support and providing new features supported only for Python 3 -- and there is no guarantee that new versions will continue to work in Python2, which may require us to pin to an outdated version. For example, we would like to be able to support [Unicode file names](https://github.com/conan-io/conan/issues/2163) which is basically built-in to Python3 and very hard to execute in Python 2.

## What does this mean for Conan?

For now we will require that all existing Conan tests continue to work with Python 2, and by default new capabilities will be tested in both Py2 and Py3. However, if a specific requirement comes up that can only be easily implemented in Python 3, we will allow the test to run only in Python 3, and provide that feature only for Python 3 users, documenting it accordingly.

An example of this was [support of xz](https://github.com/conan-io/conan/pull/3197) in Conan 1.6. When Conan 2 is released(most likely in 2019) we will probably start the process of dropping Py2 tests entirely to reduce the maintenance overhead.

In Conan 1.5, when we added the Python version to the user-agent Conan string, one of our key strategies for determining the best schedule was to check the Python versions being used by users that are regularly updating their Conan client. This was also discussed in the user forum at SwampUP! 2018, where we received positive feedbacks. Since we understand that both of these combined approaches may not provide us with a complete sense of the entire community, we decided to open this issue up to the community.

## Let’s talk about this

We’ve opened up a [GitHub issue #3334](https://github.com/conan-io/conan/issues/3334). Please provide your comments there. It would be helpful to know the timeline you think you need to migrate to Py3, so that we can assess the best path to take.

