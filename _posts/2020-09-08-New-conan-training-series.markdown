---
layout: post 
comments: false 
title: "Conan Training Series on JFrog Academy"
---

The Conan team has recently completed the first in a new series of training 
courses designed to help developers and devops engineers learn to use Conan more
quickly and easily.  

## Learning Format

The courses are adapted from the interactive training sessions we've held in the
past at CPPCon and online over the past 2 years. They feature interactive
exercises which walk users through the running of commands, exploring and
editing of importantC Conan-related files and directories, and quizzes to invoke
critical thinking after each section.  Thanks to the JFrog Academy platform,
we've now made these courses self-paced and available to be done on your own
schedule.

## Conan Essentials

The first course is available now and entitled: "Conan Essentials". This course
is intended for developers with little-to-no Conan experience and will take you
through a series of interactive exercises. Along the way, we'll explain
fundamental Conan concepts such as "Package ID",  "generators",  "settings",
"options", and "profiles", as well as the basic anatomy of the "Conanfile".  By
the end of the training you will have enough experience to start working with
Conan as part of your daily development process.  

## Conan Advanced

We're now working on finishing the content for the second course in the series,
which is called "Conan Advanced". This course is intended for users who have a
solid grasp on the fundamentals of Conan. This includes users who have already
gone through our "Essentials" course, and users who have been using Conan's
basic features for real-world development. The course will take you through a
series of exercises including advanced scenarios surrounding requirements
management. For example, the handling of version and configuration conflicts,
conditional requirements, and the special features of "build requirements" and
"python requirements". It will handle advanced versioning topics such as the use
of semantic versioning, version ranges, Conan's built-in revisioning system, and
Conan's Lockfile feature. It will also include a deeper dive into the topics of
Conan configuration and Package ID. By the end of the training, you will have a
deeper understanding of how these advanced features are intended to be used, and
how they can solve some of the more challenging real-world scenarios that emerge
when using Conan at Scale.  

## Conan CI/CD

The third course will be next on the list and will be titled "Conan CI/CD".
HThis course is intended for users who build automated build pipelines with
Conan on CI services in enterprise codebases. Conan is an ideal building block
for invoking builds of C and C++ software in CI pipelines, but there are a
number of real-world challenges which repeatedly arise for users as they try to
implement Conan in such pipelines.  The course will take you through a series of
exercises which demonstrates a collection C and C++ libraries and applications
which have are being built automatically on a CI server, with Conan at the
Center of the process. It features a realistic environment featuring a GIT
repository, Conan Repository, and Jenkins CI Server instance. It also uses a
common development flow using GIT branches, pull requests, and merges. The
exercises demonstrate how each commit can be built and tested, and then followed
by the build and test of all consumers, before finally doing a merge and
"artifact promotion" at the end of the workflow. Crucially, it shows how each
commit is run through this entire pipeline in complete isolation, ensuring that
all changes are tested individually.   By the end of the training, you will have
a deep understanding of the key features of Conan revisions and Lockfiles, and
how they represent the ideal cornerstone of automated build pipelines for C and
C++.

## Accessing the Conan Series at JFrog Academy

Here is the link to the Conan series landing page:  

[Conan Series in JFrog Academy](https://academy.jfrog.com/series/conan)

This page shows all the currently available Conan courses.  With that said, we
encourage everyone to checkout the entire catalog of courses in JFrog
artifactory.  

[JFrog Academy Course Catalog](https://academy.jfrog.com/series/course-catalog)

Access to the courses requires a signup, but it's completely free to register.

## Feedback and Improvement

We already have a lot of ideas for improving all of our courses over time and
are constantly looking for feedback from attendees. If you have feedback on our
existing courses, or want to suggest a new course, please open an issue under
the following Github repository:

[Conan Training Repository on Github](https://github.com/conan-io/training)

This repository contains all the content for all the exercises in both the
Essentials and Advanced courses, and so it's also the best place to report
any sort of feedback.  

As you complete the coureses, if you enjoyed them and want to help spread the
word, there are links to promote them on Twitter and LinkedIn.

Stay tuned for more updates about new coureses and updates to existing coureses
in the coming months!
