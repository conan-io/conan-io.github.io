---
layout: post
comments: false
title: "Conan and Conan Center: 2021 in numbers"
meta_title: "Conan and Conan Center: 2021 in numbers"
description: "Numbers and charts showing the state of Conan and Conan Center in 2021"
meta_description: "Numbers and charts showing the state of Conan and Conan Center in 2021"
---


2021 has been quite a busy year for Conan. We are working hard to get Conan 2.0 ready, almost 3
years after 1.0 was released. And, of course, the 1.X series is still very active, with 10
versions released during the year.

And Conan Center has not lagged behind. In 2021, only two years after its inception, we
celebrated with our community a huge milestone: on August, Conan Center
[reached 1,000 recipes](https://www.youtube.com/watch?v=PjiJ-3sxKbs).

So Conan and Conan Center have come a long way over the last few years. Let's take a look at some
numbers to see how much we have grown.


## Conan

According to the [ISO C++ 2021 survey](https://isocpp.org/files/papers/CppDevSurvey-2021-04-summary.pdf),
Conan is the **most used C/C++ package manager**.

So Conan is the most used, but *how much*? There are
[a lot of ways](https://conan.io/downloads.html) to install Conan, and we don't have data on
installs coming from mirrors. The most popular source, though, is PyPI, the Python package index.
There, we are currently having around **500.000 monthly downloads**. 511.158 in November, to be
precise.

But the true indicator of how healthy an Open Source project is, is its GitHub activity. Here are
the number of Pull Requests over the last few years:

|     | Conan | Conan Center |
|-----|-------|--------------|
|2019 | 758   | 397          |   
|2020 | 735   | 2607         |  
|2021 | 775   | ~3600        | 


### Conan.io

The [Conan website](https://conan.io/) is the main source of information about Conan, and a good
measure to see how the usage of Conan evolves:


|     | Page Views | Unique Users |
|-----|------------|--------------|
|2019 | 1.1M       | 184K         |   
|2020 | 2.0M       | 310K         |  
|2021 | 2.5M       | 450K         | 

CHART <Users evolution>


### Slack

Our channel in the [CppLang slack server](https://cpplang.slack.com/), #conan, is the 2nd most
used channel by members posting and the 4th most active by published messages.


## Conan Center

When we created Conan Center in August 2019 we were trying to fill a void in our ecosystem: back 
then, the latest version of the Conan client was 1.18, so it was completely production-ready, but
we didn't have our own package repository to handle dependencies in a straightforward way. We 
wanted for our users to be able to install open source libraries and tools by just adding a couple
of lines to their ConanFiles.

And we succeeded: as of today, the last days of 2021, we have 1,200 recipes in our repository.

This number is huge, but Conan Center is much, much more that the recipes, and here is some data
that describe our amazing community.

First things first, our contributors, the fuel of Conan Center. There are more than 500
contributors, who commited an average of 50 commits each week during 2021. Here are our most
active contributors, to whom we are most grateful:

| Contributor                                           | Number of Commits |
|-------------------------------------------------------|-------------------|
| [SpaceIM](https://github.com/SpaceIm)                 | 1346              |
| [madebr](https://github.com/madebr)                   | 1010              |
| [ericLemanissier](https://github.com/ericLemanissier) | 699               |
| [uilianries](https://github.com/uilianries)           | 501               |
| [prince-chrismc](https://github.com/prince-chrismc)   | 353               |
| [jgsogo](https://github.com/jgsogo)                   | 295               |
| [SSE4](https://github.com/SSE4)                       | 273               |
| [intelligide](https://github.com/intelligide)         | 248               |
| [theirix](https://github.com/theirix)                 | 211               |
| [gocarlos](https://github.com/gocarlos)               | 157               |

To show how active these contributors are, here is the evolution of PRs created:

CHART <PR evolution over time>
CHART <merged, rejected and open PRs over time>

But Conan Center is not only a recipe repository. We also build and store binaries for the most
common configurations so our users don't have to build their dependencies, which can take A LOT
of time. Those packages are stored in an Artifactory repository. Here are some numbers around it:

| **Total number of binaries** | **11.050.000** |
|------------------------------|----------------|
| **Total size of binaries**   | **11.28TB**    |

Of course, having all this in place would be pointless if anybody was using it. So let's take a
look at how much data traffic is going through our remotes:

CHART <Timeline of data transfer>

And the number of individual requests:

CHART <Timeline of requests>

## The future

The main milestone for 2022 will be, of course, the release of Conan 2.0. And it's an enormous 
milestone: we are writing a completely updated documentation, working on updating all the Conan
Center recipes to be compatible with the new version, as well as the whole Conan Center
infrastructure (building bots, CI pipelines, validation hooks, etc.).

So [stay tuned](https://twitter.com/conan_io) to get the last news about Conan and Conan Center.
See you next year!
