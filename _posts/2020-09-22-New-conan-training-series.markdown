---
layout: post 
comments: false 
title: "Free Conan Training Series on JFrog Academy"
---

Today we are very exicted to announce a new milestone in the Conan project. We
have now published our very own self-paced interactive training courses online,
free to anyone who is interested in learning Conan. The courses are hosted on
JFrog's very own learning platform: JFrog Academy, which also features a wide
variety of courses on other related topics.  

<p class="centered">
    <a href="https://academy.jfrog.com/series/conan">
        <img src="http://localhost:4000//assets/post_images/2020-09-22/jfrog-academy-screenshot.png" align="center" width="85%" height="85%" alt="Conan Series on JFrog Academy"/>
    </a>
</p>

## Motivation

The courses are adapted from the interactive training sessions we've held at
CPPCon and online over the past two years. These trainings were very succesful
with 20 sessions in 2 different timezones and 460 unique trainees total. It was
also highly rated with 70% of trainees rating it "excellent" and 25% rating it
"very good". The online sessions had limited capacity and all filled up within a
few days of being announced resulting in a waiting list. It quickly became very
clear that creating and offering a self-paced training strategy was the right
thing for scale, and the JFrog Academy was the perfect platform for us to create
it on. Now, anyone can enjoy the training without restrictions on timezones or
availabilty.

## Learning Format

The courses feature interactiveexercises which walk users through the running of
commands, exploring and editing of important Conan-related files and
directories, and quizzes to invoke critical thinking after each section.  Thanks
to the JFrog Academy platform, we've now made these courses self-paced and
available to be done on your own schedule.

## Intro to Conan

<img src="http://localhost:4000//assets/post_images/2020-09-22/intro-to-conan.png"
align="center" width="20%" height="20%" alt="Intro to Conan"/>

The first course is named "Intro to Conan." It is very short, and
intended for developers with no previous exposure to Conan, and provides simple
explanations of conan’s most fundamental innovations and benefits. It shows how
Conan abstracts away build systems, defines a “Project API” for C++ project,
provides a repository system for multi-binary packages, and is the ideal
building block for Continuous Integration workflows.

## Conan Essentials

<img src="http://localhost:4000//assets/post_images/2020-09-22/conan-essentials.png"
align="center" width="20%" height="20%" alt="Conan Essentials"/>

The second course is named "Conan Essentials". It is intended for developers
with little-to-no Conan experience and will take you through a series of
interactive exercises demonstrating Conan's most basic features. Along the way,
we'll explain fundamental Conan concepts such as "Package ID", "generators",
"settings", "options", and "profiles", as well as the basic anatomy of the
"Conanfile".  By the end of the course trainees will have enough experience to
start working with Conan as part of their daily development process.  

## Conan Advanced

<img src="http://localhost:4000//assets/post_images/2020-09-22/conan-advanced.png"
align="center" width="20%" height="20%" alt="Conan Advanced"/>

The third course is named "Conan Advanced" and is intended for users who have a
solid grasp on the fundamentals of Conan. This includes users who have already
gone through our "Essentials" course, and users who have been using Conan's
basic features for real-world development. The course begins with advanced
scenarios surrounding requirements management. For example, the handling of
version and configuration conflicts, conditional requirements, and the special
features of "build requirements" and "python requirements". It also covers
advanced versioning topics such as the use of semantic versioning, version
ranges, Conan's built-in revisioning system, and Conan's Lockfile
feature. Finally, it includes a deeper dive into the topics of Conan
configuration and Package ID. By the end of the course, trainees will have a
deeper understanding of how these advanced features are intended to be used, and
how they can solve some of the more challenging real-world scenarios that emerge
when using Conan at Scale.  

## Conan CI/CD
<img src="http://localhost:4000//assets/post_images/2020-09-22/conan-cicd.png"
align="center" width="20%" height="20%" alt="Conan CI/CD"/>

The fourth course will be titled "Conan CI/CD" and is still in production. This
course will be intended for users who build automated build pipelines with Conan
on CI services in enterprise environments. The exercises in this course feature
a collection C and C++ libraries and applications which have are being built
automatically on a CI server, with Conan at the Center of the process. It
features a realistic environment featuring a GIT repository, Conan Repository,
and Jenkins CI Server instance. It also uses a common development flow using GIT
branches, pull requests, and merges. The exercises demonstrate how each commit
can be built and tested, and then followed by the build and test of all
consumers, before finally doing a merge and "artifact promotion" at the end of
the workflow. Crucially, it shows how each commit is run through this entire
pipeline in complete isolation, ensuring that all changes are tested
individually. By the end of the course, trainees will have a deep understanding
of the key features of Conan revisions and Lockfiles, and how they represent the
ideal cornerstone of automated build pipelines for C and C++.

## Accessing the Conan Series at JFrog Academy

Here is the link to the Conan series landing page:  

[Conan Series in JFrog Academy](https://academy.jfrog.com/series/conan)

This page shows all the currently available Conan courses.  With that said, we
encourage everyone to checkout the entire catalog of courses in JFrog
artifactory.  

[JFrog Academy Course Catalog](https://academy.jfrog.com/series/course-catalog)

Access to the courses requires a signup, but it's completely free to register.

Also of note, the training courses require the use of Docker. All necessary
docker commands are provided in the courses, so trainees do not need to be
experienced with Docker prior to starting them, but it does need to be
installed.

## Support, Feedback and Improvement

We already have a lot of ideas for improving all of our courses over time and
are constantly looking for feedback from attendees. If you have any questions
during the training, please open an issue under the following Github repository:

[Conan Training Repository on Github](https://github.com/conan-io/training)

This repository contains all the content for all the exercises in both the
Essentials and Advanced courses, and so it's also the best place to report
any sort of feedback relating to existing courses, or even suggesting new ones.

As you complete the courses, if you enjoyed them and want to help spread the
word, there are links to promote them on Twitter and LinkedIn.

Stay tuned for more updates about new courses and updates to existing courses
in the coming months!
