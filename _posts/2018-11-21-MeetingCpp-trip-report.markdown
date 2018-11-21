---
layout: post
comments: false
title: "Meeting C++ and Meeting Embedded trip report"
---


## Meeting Embedded

On Wednesday, before Meeting C++, we[^1] attended 
and presented a talk at [Meeting Embedded](https://meetingembedded.com/2018/), 
a new conference about many topics related to embedded systems. C++ and C had a relevant role in this 
conference, obviously (accordingly to Dan Saks statistics around 60% in embedded 
code is C, then around 20% is C++, followed by assembly), but where other topics 
presented, like Rust, protocols for embedded (MQTT), academic and professional 
education, real-time systems. 

We did our own talk *Continuous Integration of C/C++ for embedded and IoT with Jenkins, 
Docker and Conan*, which went quite well, especially considering that we were running 
a real demo, live updating the embedded code in a Raspberry PI, that was built with 
Docker in Jenkins, using cross-compiled (from Windows) packages, and uploaded to 
Artifactory, all of that done in the live demo.

<div align="center">
    <blockquote class="twitter-tweet" data-lang="es"><p lang="en" dir="ltr">.<a href="https://twitter.com/conan_io?ref_src=twsrc%5Etfw">@conan_io</a> on embedded with <a href="https://twitter.com/diegorlosada?ref_src=twsrc%5Etfw">@diegorlosada</a> at <a href="https://twitter.com/meetingembedded?ref_src=twsrc%5Etfw">@meetingembedded</a> <br><br>I love it! <a href="https://t.co/4YmO7iH7Oa">pic.twitter.com/4YmO7iH7Oa</a></p>&mdash; Odin Holmes (@odinthenerd) <a href="https://twitter.com/odinthenerd/status/1062646088375693312?ref_src=twsrc%5Etfw">14 de noviembre de 2018</a></blockquote>
    <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>

Overall, the conference was interesting and relevant, highly recommended if you are 
working in the embedded domain. We think in the following years it can become a 
milestone in embedded programming, in the same way that Meeting C++ has become the 
must go for C++ in Europe.


## Meeting C++

We[^2] have attended [Meeting C++](https://meetingcpp.com/2018/) conference for many years. 
As attendees, as speakers, and recently also as sponsors (JFrog). We feel at home in this conference, we 
can meet lots of old friends and colleagues, but also is good to make new ones. Lunch, 
dinner is served by the conference in the break areas, which is not only very convenient 
but also helps to socialize and connect with people.

The technical program is also top, with the best C++ speakers and a range of interesting 
topics and different talks, arranged in 4 tracks.

### The booth

We had a booth at the conference, it is the best way to get feedback from users and to
spread the word.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/booth.jpg" width="600"/>
        <figcaption>Conan booth full of people attending demos</figcaption>
    </figure>
</div>

There was a lot of interest in Conan, we played a lot of demos and had many interesting 
discussions.

But the best part was meeting in person many users we had already interacted 
online (mainly in GitHub and Slack). Users coming to say thank you, very happy 
about Conan. Very interesting feedback and ideas on how to keep further improving 
Conan. It is great to *de-virtualize* and connect with users, and see what an amazing 
community is out there. Thanks!


### Talks and keynotes

*Note.- Slides for all the talks are available in the Meeting C++ webpage [here](https://meetingcpp.com/mcpp/slides/).*

#### Keynote: What is the next big paradigm? (Andrei Alexandrescu)

It was the opening keynote, full room, max expectancy, and Alexandrescu does not 
disappoint. He first explored how the next big things for C++ programming and the 
general world were perceived at the very beginning: threads, online voting, NLP, 
privacy, ranges,... and from this starting point he proposed what he thinks it is 
the next big thing for our beloved C++. The main problem for us, developers, is 
code bases becoming bigger and bigger because of the number of bugs per line of code. 
He enforces that the most valuable next big thing among concepts, metaclasses and 
introspection is the last one, and we have to agree with him, it will allow us to write 
less code and get more expressiveness, and the community also must be agreed too because 
of the several talks that addressed this issue during this conference and many others.

#### Data-oriented design in practice (Stoyan Nikolov)

One of the first talk we were able to attend! Stoyan Nikolov gave a great talk 
comparing Data-oriented with Object-oriented designs and how our mental model 
structure for programming is not always the best approach to achieve performance. 
What we really liked about the talk was the real example of the Chromium project 
(definitely something we should check out to learn), as we were able to see how a 
DoD for the animations rendering could have been done instead of the original OoD.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/stoyan.jpg" width="600"/>
        <figcaption>Stoyan Nikolev - Data-oriented design in practice</figcaption>
    </figure>
</div>

#### Keynote: The truth of a Procedure (Lisa Lippincott)

Lisa Lippincot offered the second keynote of the conference, it was about procedural 
logic from a theoretical math point of view. Lisa talked about procedures and 
assertions in a so didactic way that these complex concepts become affordable for 
those of us that are not familiarized with the abstract ones. She exposes the truth 
of the procedures as a game between an evil and a good boy, each of them can make 
different statements, choose among different branches, delegate execution in the 
other guy and, given a set of losing conditions, the full procedure will be true 
or false.

The game was increasing its complexity from the simple *game of truth* that 
depends only on inputs and outputs to the *game of necessity* where the players 
traverse a story and finally to the *game of proof* where some claims can be requested.
Given these rules, the procedures could become true (the good boy wins) or false 
(the evil one does), differentiating into good programs made of true procedures 
and bad programs made of undecidable procedures or false ones. 

In the end, there is hope, as Lisa says, because programming is not about the good 
programmer against an evil world, but a work of cooperation between good developers 
where each player is trying to win their own game.

We found it quite interesting and some of us is willing to read all the references that 
Lisa added to the slides.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/lippincot.png" width="600"/>
        <figcaption>There are no demons, just other players trying to win their games</figcaption>
    </figure>
</div>

#### Cross-platform C++ development is challenging - let tools help! (Marc Goodner)

As one would expect, we were really interested in a talk around tooling for the 
C++ ecosystem. Marc Goodner from Microsoft introduced some of the improvements 
available in the latest versions of the tools provided by the company. Of course, 
he talked about interesting points a C++ developer has to deal with every day, 
such as using libraries, using new features in the compilers following the standard, 
avoiding platform-specific logic… We also liked that half of the talk was a demo, 
showing attendees how to configure your Visual Studio to debug or test properly 
and use it to compile with the support for Linux in latest Windows versions. He 
obviously talked about vcpkg and showed some live usage with SFML but admitted 
there were many things happening in the ecosystem such as Conan :)

#### C++, QML, and static reflection (Manuel Sánchez)

Manu made an introduction about Qt and QML and how can you develop a graphic 
interface for your project. But then it came the interesting part… A good engineer 
doesn’t repeat the same code EVER. But all the frameworks, like Qt, require to 
follow some rules/interfaces. Most of the developers will say, “ok, there is nothing 
to do here, I would need to live with that”, but not Manu.
He developed a library called “tinyrefl”,  “A work in progress minimal C++ static 
reflection API and codegen tool” so he managed, by using tinyrefl, to develop a 
layer to abstract/convert all the Qt types and connect a regular std-types application 
transparently without all the boilerplate that a QML application usually requires.

It was very interesting how a very common software design issue can be resolved
using very advanced techniques like the static reflection of the language. 
The talk was also funny!

#### C++ Concepts and Ranges - How to use them? (Mateusz Pusz)

Following the useful and practical talks he gave in past conferences this year
(code::dive and CppCon), we really wanted to be part of the public at this talk. 
Mateusz talked about a different thing this time and provided us with useful 
and detailed information about how to use Concepts and Ranges in our code. 
He rushed us through a lot of information as usual but included examples in 
almost every single slide to guide the explanation.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/pusz.jpg" width="600"/>
        <figcaption>Mateusz Pusz - C++ Concepts and Ranges, how to use them?</figcaption>
    </figure>
</div>

However, sometimes the information was a bit overwhelming 
(too many concepts) and that maybe it would have been better to just 
provide some insights and let people dig into cppreference.com on their own later. 
Anyway, it was great to attend one of his talks and we are sure that many people will 
come back to his slides and the recording of the talk once they are uploaded!


### Additional talks

Other interesting talks we attended and that worth a mention was *Text Formatting 
For a Future Range-Based Standard Library* (Arno Schödl), who provided an insight 
on how your code can benefit from ranges and how are they using it at Think-Cell 
providing also a OSS library for the community.

And also the talk of Jonathan Müller about *Writing Cache-Friendly C++*, which was 
a great synthesis of how to use efficiently the cache and introduced two libraries 
for this purpose: tiny and array. He concluded with useful pieces of advice such 
as reducing main memory access and using benchmarking tools.
James McNellis did a great talk, but the best part was an impressive demonstration 
of Microsoft Time Travel Debugging (TTD) reverse debugging toolkit. 
If you found yourself debugging complex things for Windows platforms very often, 
you certainly want to have a look at this talk.

There were a few talks that we definitely tried to attend but couldn’t 
(full, packed rooms, and we couldn’t go earlier because of being busy at the booth), 
like *More Modern CMake - Working with CMake 3.12 and later* (Deniz Bahadir) and 
*Compile Time Regular Expressions* (Hana Dusíková). We are looking forward to 
seeing those videos uploaded!


## The Conan Quiz

This is the 3rd year we have been running an (evil) C++ Quiz in Meeting C++. 
It is our favorite moment of the conference. It requires a ton of effort to prepare 
it, but is definitely worth it, once you see the attendees struggling with the 
puzzles, surprised and amazed, but overall working and having fun together 
(participants are arranged in teams, and they cannot belong to the same company 
or organization!).

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/quiz.jpg" width="600"/>
        <figcaption>"Wonders and horrors of C++" by Jens Weller</figcaption>
    </figure>
</div>

Many people asked for the slides if we were posting them online. No, we are not doing it. 
They would lose most of their meaning if online. All the hidden messages, traps, jokes, 
stories… won’t be understood. The whole point of the quiz is to mingle, to network 
with colleagues and have some fun together. You can only get that if you attend 
the event in person, sorry :)

<div align="center">
    <blockquote class="twitter-tweet" data-lang="es"><p lang="en" dir="ltr">Having a blast doing the <a href="https://twitter.com/conan_io?ref_src=twsrc%5Etfw">@conan_io</a> C++ Quiz <a href="https://twitter.com/meetingcpp?ref_src=twsrc%5Etfw">@meetingcpp</a> 🤓<a href="https://twitter.com/diegorlosada?ref_src=twsrc%5Etfw">@diegorlosada</a> is an evil man 😜 <a href="https://twitter.com/hashtag/extremecpp?src=hash&amp;ref_src=twsrc%5Etfw">#extremecpp</a> <a href="https://twitter.com/hashtag/meetingcpp?src=hash&amp;ref_src=twsrc%5Etfw">#meetingcpp</a> <a href="https://t.co/F7jWX7IudY">pic.twitter.com/F7jWX7IudY</a></p>&mdash; Victor Ciura (@ciura_victor) <a href="https://twitter.com/ciura_victor/status/1063163330960023553?ref_src=twsrc%5Etfw">15 de noviembre de 2018</a></blockquote>
    <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>

<div align="center">
    <blockquote class="twitter-tweet" data-lang="es"><p lang="en" dir="ltr">Woot, my team, the &quot;Uninformed Initialization&quot; won the <a href="https://twitter.com/conan_io?ref_src=twsrc%5Etfw">@conan_io</a> <a href="https://twitter.com/hashtag/cplusplus?src=hash&amp;ref_src=twsrc%5Etfw">#cplusplus</a> Quiz on <a href="https://twitter.com/hashtag/meetingcpp?src=hash&amp;ref_src=twsrc%5Etfw">#meetingcpp</a>!<a href="https://twitter.com/meetingcpp?ref_src=twsrc%5Etfw">@meetingcpp</a> <a href="https://t.co/Pf9NLU0K0s">pic.twitter.com/Pf9NLU0K0s</a></p>&mdash; ℍannеs ℍauswеdеll (@__h2__) <a href="https://twitter.com/__h2__/status/1063172855872004097?ref_src=twsrc%5Etfw">15 de noviembre de 2018</a></blockquote>
    <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>

## Conclusion
Meeting C++ is our favorite conference. It is a great event, with top speakers 
and talks, well organized and run, in a great and interesting location. The talks 
videos will be online, that will be great to be able to listen to the talks we 
couldn’t attend. But the talks are not the best part of the conference. The people, 
the networking, the spirit, the fun we had on the Quiz… difficult to explain. 
So looking forward to being there again next year.

**See you in Meeting C++ 2019!**

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2018-11-21/conan-team.jpeg" width="600"/>
        <figcaption>Luis, (The Frogarian), Katrin, Diego, Javi and Dani</figcaption>
    </figure>
</div>

----

[^1]: Meeting Embedded took place on Wednesday, only Daniel and Diego were in Berlin to attend it.

[^2]: On Thursday, more members of the Conan team joined from Spain: Luis and Javier. Katrin from the marketing team also joined from France.
