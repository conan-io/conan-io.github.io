---
layout: post
comments: true
title: "MeetingC++ Quiz"
---


MeetingC++, the major C++ conference in Europe, and the 2nd largest in the world was celebrated in Berlin last week. Like previous conferences, it was very well organized, with very interesting talks and a gorgeous environment.


We wanted to collaborate, so we joined as silver sponsors, and we also organized and sponsored a C++ quiz that was held in the evening after a nice pizza & pasta buffet.

<img src="{{ site.url }}/assets/meetingcpp_quiz.jpeg" />

It seems the initiative was very welcome. Thanks very much to the many people who attended and participated in the quiz!


# The rules of the quiz
The rules were very simple; to guess the output of 10 code snippets, all guaranteed to compile and work, and print a single line of text of up to 10 characters. Each question had to be solved within  3 minutes, after the code was projected on the screen. Each correct character scored 1 point, which means that the best score achievable was 100.

Attendees worked in teams of up to 6 people each. We encouraged them to mix and meet others,  and not to stick with their  work colleagues. Each team  received a single paper form, and was not allowed to use any computer or device (besides their analog brains) for the task.


The rule that I liked most was that the quiz code didn’t have to be portable, modern, to make sense, be good practice, or even work on other machines. I could say **as it works on MY machine**. A programmer's heaven :)  If you intend to replicate the code, I was using an MBP with Win10, Visual Studio 14u2, building for Release and 64 bits with the standard build provided by CMake “add_executable” command.

# Code & Solutions
I must admit, the quiz was not simple. I was afraid that others would get all the correct answers, so I crafted some crazy exercises, some simple, but others quite convoluted. Here are the snippets, go ahead, solve each one in 3 minutes!:


<script async class="speakerdeck-embed" data-id="f4d028ec381c4b5eaf106af13c2434e8" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
We wanted the exercise to be entertaining and fun, so there were more slides besides the code! Obviously, you can only enjoy that part if you attend in person, so if you want to have fun, make sure you don’t miss any of the upcoming  MeetingC++ conferences.


There were tricks, like the comparison of ``unsigned int i=4`` with `` i > -1``, which is false! Other exercises were more conventional, like recursive variadic templates, in the sense that the only challenge was to track the evaluation of the templates, without any tricks. Some quiz questions included modern C++ features like lambdas, while others had terrible legacy meta-programming with macros, STL, delegating constructions, threads with a barrier, moving semantics… Controversial practices, like using an object after moving it (nope, it is not undefined behavior), or guessing the result of a random_shuffle, all provided some spice to the mix.


# And the winners!
We didn’t expect so many attendees, so some volunteers helped to evaluate the forms, thanks very much to all of them.


We were more than impressed, and completely baffled by the expert level of the participants. The average score of 75 points was even higher than expected, and all scores were above 60 points. Congrats to all of them!


<img src="{{ site.url }}/assets/meetingcpp_quiz_winners.jpeg" />


We still can’t believe it, but the winners scored a perfect 100!! They were a team of just 2 people, but they proved to be extremely talented: Rostislav Khlebnikov, from [think-cell](https://www.think-cell.com/en/) and Ivan Sorokin from the JetBrains [ResharperC++](https://www.jetbrains.com/resharper-cpp/) team. Congrats!


These are the teams that achieved glory, the MeetingC++2016 Quiz hall of fame:


**1st place: (100 points) “SPb”**

- Rostislav Khlebnikov, from [think-cell](https://www.think-cell.com/en/)
- Ivan Sorokin, from JetBrains [ResharperC++](https://www.jetbrains.com/resharper-cpp) team

**2nd place (96 points): “Operator ++”**

- Matthew Chaplain, from TomTom
- Paul M. Bendixen
- Valentino Picotti [@paicoz](https://twitter.com/paicoz).
- Paul Dreik, [Dreik Ingenjörskonst AB](https://www.dreik.se/)
- Lukas Bergdoll [homepage](https://www.lukas-bergdoll.net)

**3rd place (86 points): “reinterpret_cast\<cpp\>(Java)”**

- Jakub Chlanda, from [Codeplay Software](https://www.codeplay.com/)
- Peter Goldsborough
- Bruno Manganelli,  student
- Jan Babst, from [Elektrobit](https://www.elektrobit.com)
- Philipp Lenk


There are some missing names here! Please check your emails, or contribute with a PR to this post.


Special mention also needs to go to the teams “; drop table *” and “Number 1”, who were really close to third place.

# Prizes
The winners received a new innovative puzzle: a customized Rubik’s cube, even more challenging that the original, with tiles that need to be in the correct orientation, besides color, and letters.


<img src="{{ site.url }}/assets/RubikCube.jpeg" style="width:200px;display: block;margin: 0 auto;"/>


We will also send them to the 2nd place team members, if you were part of it, please check your email!

# After the quiz
When the quiz was over we all joined a very nice party organized by MeetingC++, where we had drinks and lots of fun. We strongly believe that the best part of these conferences is meeting other developers, face to face, meeting new people and sharing experiences, and of course the party is just as important. We wouldn’t trade it for anything else!. Thanks very much to Jens for organizing such a great conference.


We think that most people had fun with the quiz, we indeed had a great time ourselves, so we are definitely proposing it again for next year! Couldn’t make it to MeetingC++ this year? You should definitely try to attend next years. Hope to see you all there :)
