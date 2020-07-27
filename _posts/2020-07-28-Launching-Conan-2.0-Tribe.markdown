---
layout: post 
comments: false 
title: "Launching the Conan 2.0 Tribe"
---

## Launching the Conan 2.0 Tribe

Conan continues to experience incredible growth and adoption. After our own conference "ConanDays" in Madrid was postponed, we decided to take the planned training online. We have had to repeat the sessions multiple times, even in the same week for the same training, and hold separate  sessions in both US and EMEA/APAC time zones. Every training session we’ve announced has been sold out within a few days, and we currently have a long list of outstanding requests from different companies who missed out on past sessions and to get seats in future sessions.

At the same time, the new ConanCenter repository [conan-center-index](https://github.com/conan-io/conan-center-index) has processed more than 1200 pull requests from contributors since it opened early this year, contributing more than 430 new packages (multiple versions per package, and hundreds of binaries per version). This is 20x faster than it was last year. Millions of packages are downloaded from ConanCenter every month. 

Our [documentation](https://docs.conan.io/en/latest/) gets more than 200k views/month, with very long reading times, and our internal metrics show thousands of companies using Conan in production.

The [Conan codebase](https://github.com/conan-io/conan) has also been growing steadily, with a strong commitment to stability, not breaking recipes or builds since releasing Conan 1.0 more than 2 years ago. Conan has learned great new features like package revisions, SCM automation, lockfiles, hooks, python-requires, and more transparent integrations with the build systems, all while upholding our compatibility guarantees.

With all the learnings of these last years, we want to start working on the next major Conan version, Conan 2.0. This is very necessary to keep evolving, we need to shed some substantial technical debt, while defining new and more adequate defaults. As an example, Conan was born with Python 2.7 support only, and the C++ default standard library for all versions of GCC is ``libstdc++``, not ``libstdc++11``, because GCC 4.9 was the first reference GCC compiler version that we supported.

The feedback that we have received, especially contributions, bug reports, feature requests in Github has been spectacular. There are many users doing things with Conan that we couldn’t imagine, and that information is critical to keep improving, as those use cases and lessons learnt are something that we cannot do by ourselves. But sometimes, the conversations and discussions are a bit too local. For the next major leap, we need very solid and good quality feedback, in a consistent and unbiased way, over extended periods of time. This is the aim of the Conan 2.0 Tribe.


## The Conan 2.0 Tribe

The Conan 2.0 Tribe is a technical group of experienced and active Conan users and contributors, willing to provide quick and consistent feedback for defining the next major Conan 2.0 version over an extended period of time (several months). The tribe will kick off the 1st of September 2020, and first Conan 2.0-alpha releases are expected end of 2020

The tribe will be always fully remote and distributed. The purpose of this tribe is to give feedback and to answer questions that will be of critical importance in the new design of Conan 2.0 (see the [Github milestone](https://github.com/conan-io/conan/milestone/59)). There are many things that there is already enough consistent feedback to take action, but there are still many open questions which would need an answer *before* starting working on them. A few examples:

- What should be the default ``package_id_mode`` in Conan 2.0?
- Would it be ok if build-requirements were always resolved and be part of the graph?
- Should build-requirements be able to affect the ``package_id``?
- Which is the minimum CMake version that we should support? And the minimum Python version?
- Can multi-config (``self.cpp_info.debug`` and ``self.cpp_info.release``) packages be deprecated?

These questions don’t have a "correct" answer, and the only way to do the right steps is to get good quality feedback, that is somewhat statistically representative of the Conan users base, and get it in relatively short periods of time.


## Joining the Tribe

The tribe is an open and public group, the main criteria to belong to it is to be an active and experienced Conan 1.X user, using Conan in production in your team, company or organization, or to be a relevant Conan open source contributor, willing to give feedback about important architecture and design issues for Conan 2.0.

The only commitment is to keep giving feedback in asynchronous communication (no in-person meetings or video calls will be necessary).

To join the tribe, please fill out this [very short form](https://docs.google.com/forms/d/e/1FAIpQLScJSLSpWQhvipRLBNOazFv8CBpwtjaJ7S5gCrbMcDUzXb2amg/viewform?usp=sf_link). The tribe will be launched on the 1st of September, if you would like to join please submit your application before the 7th of August.


## Getting feedback

We know that time is precious, and that this activity shouldn’t be a burden for tribe members. The important commitment is to do this in a consistent way over time, and we would expect the vast majority of the committee to respond to most questions, but most of the activities will only take very little time. 

The communication principles will be:

- The tribe will communicate mainly in a public space, most likely a Github organization or project. If some members can’t communicate in Github, an email will also be possible as an exception.
- All communications will always be online, no in-person meetings will be compulsory. Anyone can effectively contribute to the tribe and to define the future of Conan irrespective of timezones and other possible constraints.
- Communication will be asynchronous. If some video call is done at some point, it will be optional and meeting minutes will be taken to make them available to everyone and for follow up discussion offline.
- As we know that there is sensitive information that companies can’t disclose in public, there will also be email support, to support and complement the public discussions. The intent is that most discussions happen in public, and the email is a fallback when this is not possible. The maintainers will be processing it, and when possible, anonymizing and posting conclusions in the public forums.
- Most of the communications can be handled and responded quickly, taking little time. But responding, even for expressing irrelevance or not interested in the question, is important.

The plan is to start with a brief bi-weekly communication that will push a very few questions and discussions to the tribe. These questions typically come from an aggregation of Github issues, slack conversations, emails from users. These questions centralize and condense them into a single place, separate from the main Conan development repo. The idea is that most of the questions accept a quick yes/no/"don’t care" response, although there will be space for deeper discussion when necessary. Feedback will be gathered in the following few (up to 5) days. With this feedback, decisions will be made and moved into the Conan 2.0 development.


## Why joining

The most important reason to join the Conan 2.0 Tribe is to have a loud voice in the future of Conan. The open source space is amazing, but also very noisy. The tribe will be key to defining what Conan 2.0 will look like. If your team or company is heavily invested in Conan, it is likely that someone might be interested to join.

Besides the open and public communication, there will be at least monthly exclusive progress reports and news. Understand quickly and easily what is happening and the Conan roadmap before it happens.

The tribe will play an important role in all alpha and beta testing, getting special attention and help for the testing, and even for later public testing, feedback from the tribe will get priority. Of course, Conan will continue completely open source, it will keep being developed openly and released publicly and everything will be free as it is today.


## Join us

As usual, this is our initial proposal. Nothing is written in stone and surely we will learn as we move forward. The only important thing is: let's do it as always, together.

Do you want to join the Conan 2.0 Tribe? Submit [your application to this form](https://docs.google.com/forms/d/e/1FAIpQLScJSLSpWQhvipRLBNOazFv8CBpwtjaJ7S5gCrbMcDUzXb2amg/viewform?usp=sf_link) and if you have any questions, write to us info@conan.io.
