---
layout: post 
comments: false 
title: "Moving the Conan 2.0 Tribe Forward"
---

In July of this year, we announced ["the launch of the Conan 2.0 Tribe"]({{
site.baseurl }}/2020/07/28/Launching-Conan-2.0-Tribe.html), and the plan to move
Conan 2.0 forward with the help and feedback of the tribe members. We're now
beginning to execute on that plan, and provide some additional details about how
you can get engaged and follow the progress.

<p class="centered">
    <a href="https://conan.io/">
        <img src="{{ site.baseurl }}/assets/post_images/2020-10-30/graphics-tbd.png"
        align="center" width="75%" height="75%" alt="Conan 2.0 Tribe"/>
    </a>
</p>

## Community Response to the Tribe 2.0 Launch

Before we talk about Conan 2.0, we want to take a moment to share our
appreciation to everyone who responded to the call when we announced the Conan
Tribe. We were amazed at how many people have volunteered to engage in the
process. It was great to read all the descriptions from users about how and
where they use Conan, and why they were so interested in being involved. Here is
the current list of tribe members, to whom we are extremely grateful.  

list of names and companies
graphics

## Recapping the Motivation

It's also been a few months since the initial announcement, so we also want to
reiterate why we've created the tribe to begin with, and what our primary goals
are.  

issues and pull requests table
bintray downloads stats

paragraph to explain

## Operational Details

The majority of interactions for the tribe will take place under [the Conan
Tribe Github repository](https://docs.google.com/forms/d/e/1FAIpQLScJSLSpWQhvipRLBNOazFv8CBpwtjaJ7S5gCrbMcDUzXb2amg/viewform?usp=sf_link).

One of the fundamental challenges in evolving a versatile development tool like
Conan is that it's very difficult for most users to find the time to understand
every proposed change, and determine whether or not it will affect them, and in
what way. Also, it can be tedious to provide a written response to each issue,
and tedious for the Conan team to "weigh" written responses.

Thus, the format for tribe feedback aims to be extremely simple for both
the tribe members and the maintainers. The Conan team will provide a written
summary of each significant change or feature in a Github issue. Tribe
members will then vote on the Github issue using the Github upvote/downvote
buttons. Of note, Conan community members who have not joined the tribe
can still vote, however the Github API allows the Conan team to be
able to group and evaluate the votes from tribe-members independently from the
rest.

There will also be an email group for the tribe. This will be used for
notifications, results reporting, and additional discussion. There is also
another reason for the email group. Many of the Conan tribe members represent
private organizations. These members need a way to provide feedback which may
contain sensitive information which cannot be disclosed to the public. So, any
material conversations or conclusions which will impact decisions about Conan
will ultimately be shared with the tribe and community, however the Conan team
needs the ability to anonymize and protect the source of information when
necessary.

Finally, feedback from tribe members will be requested at least every 2 weeks,
but initially more often. The complete list of features being tracked for Conan
2.0 can be viewed in the following [Github
Milestone](https://github.com/conan-io/conan/milestone/59) but here is a brief
summary of priorities:

* Better graph model
* Changing defaults
* Modernizing build system toolchains and practices

## Time Frames

There is a long list of items on the roadmap for 2.0. Many of those items have
been explored to some degree, however many others haven't even been discussed.
Thus, the dates that we will be planning for and suggesting here should be
considered very rough estimates rather than a commitment.

Beginning in December, we plan to create a branch (tentatively named "develop2")
which will be open for pull requests. This will become the new landing place for
all new changes and features which would be breaking for Conan 1.x.  As a
reminder, the `CONAN_V2_MODE` environment variable currently exists with a
default value of "Off", which allowed for a number of potentially-breaking
changes and features to be added to Conan 1.x in a safe way. This has enabled
power users and our own dev team to explore some of the features in real-world
scenarios prior to releasing Conan 2.0. So, this new branch will also
effectively change the default value for the `CONAN_V2_MODE` to "On".  

Beginning sometime in Q1 of 2021, Conan will begin continuously publishing
"alpha releases" as we work out final bugs and incorporate the feedback from the
users in the tribe who are working off the new branch. This process will go on
as long as it needs to until we feel we've worked out any fundamental problems
and are confident in the stability and viability of the release. However, we
hope that we can reach this point within 2 months of the first "alpha release".

## Conclusion

In closing, we want to re-iterate one of the major purposes of this blog post,
which is to extend our thanks to everyone in the tribe. We really do feel as
though we have a completely unique, special, and downright awesome user
community surrounding Conan, and we just can't say enough about it.

Also, if you are a user who did not apply to join the tribe in the past, but
wants to apply now, it's not too late! We have decided to continue accepting
applications until further notice. If you wish to apply, please just send an
email to [info@conan.io](mailto:info@conan.io).
