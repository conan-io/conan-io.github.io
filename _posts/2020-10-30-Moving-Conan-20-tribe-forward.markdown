---
layout: post 
comments: false 
title: "Moving the Conan 2.0 Tribe Forward"
---

In July of this year, we announced ["the launch of the Conan 2.0 Tribe"]({{
site.baseurl }}/2020/07/28/Launching-Conan-2.0-Tribe.html) and the plan to move
Conan 2.0 forward with the help and feedback of the tribe members. We're now
beginning to execute on that plan, and provide some additional details about how
you can get engaged and follow the progress.

<p class="centered">
    <a href="https://conan.io/">
        <img src="{{ site.baseurl }}/assets/post_images/2020-11-25/conan-tribe.png"
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

{:class="table table-bordered"}
| Name                 | Organization                   | Name                  | Company                       |
|----------------------|--------------------------------|-----------------------|-------------------------------|
| Robert Conde         | a\.i\. solutions, inc\.        | Tijmen Verhulsdonck   | Loomai Inc\.                  |
| Ayaz Salikhov        | AIM Tech                       | Dean Moldovan         | Lumicks                       |
| Romain Deterre       | Alazar Technologies Inc\.      | Christopher McArthur  | Matrox                        |
| Chandler Scott       | Aquaveo                        | Nenad Miksa           | Microblink                    |
| Fabien Laurent       | ASAP Engineering               | Yuri Timenkov         | Nasdaq                        |
| Kellya Clanzig       | ASAP Engineering               | Roman Zaytsev         | NTT LLC                       |
| Julien Bernard       | Australian National University | Ken Frederickson      | NXC Systems                   |
| Alban Lefebvre       | Bloomberg LP                   | Luis Caro Campos      | Oxbotica                      |
| Michael Maguire      | Bloomberg LP                   | Jan Linnenkohl        | Pepperl\+Fuchs SE             |
| Yoann Potinet        | Bluemanoid                     | Tamás Szelei          | Plex                          |
| Daniel Roberts       | Bose                           | Nils Brinkmann        | Rheinmetall Electronics GmbH  |
| Simon Ortego Parra   | BSH Electrodomésticos España   | Janosch Steinhoff     | Robert Bosch GmbH             |
| Claudio Bantaloukas  | CCDC                           | Javier Povedano       | RTI                           |
| Sheng Mao            | CircleCVI                      | Alexandre Petitjean   | SBG Systems                   |
| Keef Aragon          | Cognitiv                       | Harald Achitz         | Self employed, consult        |
| Kerstin Keller       | Continental                    | Mike Detwiler         | Shift5                        |
| Bruno Manganelli     | Cybergram LTD                  | Johannes Asal         | SICK AG                       |
| Kevin A\. Mitchell   | Datalogics                     | Yevgeniy Shaporynskyy | SWIFT                         |
| Nils Gerke           | Digitalwerk GmbH               | Theo Delrieu          | Tanker                        |
| David Allemant       | ECA robotics                   | Mark Final            | The Foundry Visionmongers Ltd |
| Julien Marrec        | EffiBEM                        | Canmor Lam            | ThoughtWorks                  |
| Andreas Hader\-Kregl | ENGEL Austria GmbH             | James Weir            | TomTom                        |
| Thomas Steiner       | ENGEL Austria GmbH             | Maikel van den Hurk   | TomTom                        |
| Andreas Kleber       | ESI Group                      | Eric Pederson         | Tradeweb Markets              |
| R\. Andrew Ohana     | ESI Group                      | Max Kolesin           | V\-Nova Ltd                   |
| Aleksa Pavlovic      | Everseen                       | Jani Mikkonen         | Varjo Technologies            |
| Martin Stelzer       | German Aerospace Center        | Daniel Heater         | VMware                        |
| Markus Hedvall       | HiQ                            | Jared White           | WAGA                          |
| Kevin Puetz          | John Deere                     | Martin Pausch         | Zeiss Meditec AG              |
| Kai Wolf             | Kai Wolf \- SW Consulting      | Alexandr Timofeev     | ASD Co\. Ltd                  |
| Zack Johnson         | Keysight Technologies          | Alex Brinkman         | Nasa-JPL                      |
{:.table-striped}

## Recapping the Motivation

It has been a few months since the initial announcement, so we also want to
reiterate why we've created the tribe to begin with, and what our primary goals
are.  There were two major reasons for the tribe.  First, we believe Conan’s
evolution should be guided by all  our users with a consistent and unbiased
approach.  This includes our enterprise users, who we’ve found are
under-represented in the existing public discussions. It also includes the
open-source community, who have been providing the vast majority of feedback
thus far. The tribe provides a way to meet the goal and of consistent and
unbiased feedback, and reconcile both sets of feedback together.

Regarding Conan’s enterprise users, it’s important to point out just how
important and numerous these people are. In a single enterprise organization
with a C/C++ codebase, it’s not uncommon for there to be 100-500 individuals who
might use Conan. We also know of cases where there are 1000+. Conan is now used
in hundreds of these enterprise organizations, and even with conservative
estimates, the total number of Conan users in these organizations already dwarfs
the number of developers who use Conan for open-source development or small
projects. Furthermore, this gap will only over time. The problem today is that
we don’t receive an amount of feedback from these users which is proportional to
their numbers. Many of these developers either can’t engage with the community
due to company policy, or choose not to for other reasons.

Conversely, from the open-source community, we get plenty of feedback. In the
third quarter of 2020, the Conan repository received tremendous numbers of
issues and pull requests:

{:class="table table-bordered"}
| Open | Closed |
|---------------|
| 1886 |  1666  |
{:.table-striped}

This translates to 10,000+ messages in the form of notifications and
conversations. This also doesn’t account for all the conversations that take
place in the #conan channel of the CPPLang slack workspace, which is
consistently one of the most active channels.

So, when it comes to major design choices and potentially breaking changes, the
Conan Tribe 2.0 also aims to help us in meeting the goal of gathering the
maximum feedback in the most constructive and scalable way possible.

## Operational Details

The majority of interactions for the tribe will take place under [the Conan
Tribe Github repository](https://github.com/conan-io/tribe).

One of the fundamental challenges in evolving a versatile development tool like
Conan is that it's very difficult for most users to find the time to understand
every proposed change, and determine whether or not it will affect them, and in
what way. Also, it can be tedious to provide a written response to each issue,
and tedious for the Conan team to "weigh" written responses.

Thus, the format for tribe feedback aims to be extremely simple for both the
tribe members and the maintainers. The Conan team will provide a written summary
of each significant change or feature in a Github pull request. Tribe members
will then vote on the Github pull request using the Github upvote/downvote
buttons. Of note, Conan community members who have not joined the tribe can
still vote, however the Github API allows the Conan team to group and evaluate
the votes from tribe-members independently from the rest. As an example, here is
[a pull request](https://github.com/conan-io/tribe/pull/3) to discuss the
minimum Python version Conan will support.

There is also an email group for the tribe. This will be used for
notifications, results reporting, and additional discussion. There is also
another reason for the email group. Many of the Conan tribe members represent
private organizations. These members need a way to provide feedback which may
contain sensitive information which cannot be disclosed to the public. So, any
material conversations or conclusions which will impact decisions about Conan
will ultimately be shared with the tribe and community, however the Conan team
needs the ability to anonymize and protect the source of information when
necessary.  Finally, feedback from tribe members will be requested at least
every 2 weeks, but initially more often.

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
and are confident in the stability and viability of the release. At that point
(later in 2021), we will move to a “beta release” model.

## Conclusion

In closing, we want to reiterate one of the major purposes of this blog post,
which is to extend our thanks to everyone in the tribe. We really do feel as
though we have a completely unique, special, and downright awesome user
community surrounding Conan, and we just can't say enough about it. The other
purpose was to provide an update on the status, and the links necessary to
see how we’re moving forward (and get engaged.)

Also, to inquire about the member application process, please send an email to
[the Conan
team](mailto:tribe-maintainers@conan.io?subject=Conan%20Tribe%20Question).
