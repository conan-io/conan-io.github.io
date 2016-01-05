---
layout: post
comments: true
# other options
---

Conan has received **consistent feedback**, some in the form of public blog posts [http://mcraveiro.blogspot.co.uk](http://mcraveiro.blogspot.co.uk/2015/12/nerd-food-dogen-package-management-saga.html) , [http://maitesin.github.io](http://maitesin.github.io/GoogleTest-C++), in the reddit and hackernews threads or in the [social media](https://twitter.com/conan_io), and we have been reported improvements in creating package time 10x faster than biicode dependency manager, for exactly the same library.

Two things are needed for a developer tool to succeed: **be useful and save coders time**, and generate enough **trust** to invest time in learning and adopting it. This blog will try to achieve the later one by being **transparent** with our community, C and C++ developers.

In our commitment with transparency, we did what we could, while keeping as lean as possible: **release a Free and Open Source Software** (FOSS) full stack, including the server that can be deployed on-premises by any developer or company willing to do so, with the extremely permissive MIT license.

Since its launch 1 month ago, it has been **very well received** by the community, the main [Github Repository](https://github.com/conan-io/conan) has received more than 200 stars and 20 forks so far, but what is more important, it has had very useful contributions in the form of **Pull Requests**, from QMake and YouCompleteMe generators to a full proof-read of the documentation, for example. This fact, together with many new improvements we have developed ourselves makes us think that the codebase is well designed and understandable.

Conan was also referenced in a recent [**CppCast**](http://cppcast.com/2015/12/eric-niebler/), with **Eric Niebler**, and a concern was raised about who was behind the project, or whether it was backed by a company or not. There was no intent to hide this detail, basically we didn´t have the time to address this issue, and the answer is no, **there is no company behind conan right now**. Conan is lead by former biicode employees, we have been working in this problem for more than 3 years now, and we intentionally did it this way. Such a tool as a package manager for C and C++ developers gets more acceptance as a **FOSS project** than as a proprietary tool, and building a company (with all the extra costs that means) to just release everything as FOSS makes little sense. So we try to keep as **lean as possible** (if you are not into startups, you might be interested in reading Eric Fries “Lean Startup”), build a **tool** as useful as possible with **zero distractions** from business issues and **total freedom** (no company, no financials, no investors/board, no hiring).

That doesn't mean that there is no potential business model. We are currently investing **huge amounts of time**, plus a few monthly $ (less than 100$) to pay the conan.io servers and storage, so this is not sustainable for a long time, we should **get some revenue at some point**. We work under the premise that a pay-for-private packages will work, something very similar to the Github business model, but are open to any other possibility: consultancy, training, investment, acquisition… as long as they keep the initial and current spirit, **openness and license of the project**, and is beneficial for our community.

The **companies**, that are really important at this stage, are the potential first corporate users of such a tool, so we are working with some of them in order to understand conan value proposition, to **learn about the needs** of corporate development, and to develop required features that such environment requires. So far we have been working with 4 companies, both very big and SMEs, and there is strong initial evidence of the value of the tool, so it is very likely that it will be deployed in their everyday development soon. We will try to keep our community updated, disclosing when possible success stories like these.

Actually, this is also a **main goal of this blog**, **establish a meeting point for the community**: success stories, dev or SW engineering topics, popular and useful packages… Did you contribute an interesting package to conan? **Write a short blog post** with an intro to the library, a small example. Want to talk about the **usage of conan in your company**? Want to talk about **any general C or C++ topic** (not necessarily about conan) that could be of interest to the conan C and C++ community? Do you want us to talk about the tool **internals or design**? Everything from **everybody is welcomed in this blog**. Just open an issue in the [Github repo](https://github.com/conan-io/conan-io.github.io), get some feedback, and **write the post** if there is interest.

Our current efforts are oriented towards the community. First **we are eating our own dog food**. Conan user “lasote” has many *hundreds* of packages for Boost, OpenSSL and some other libraries. He is probably one of the largest C++ binary package creators in the world. This, together with users (both corporate and open source individual developers) feedback and contributions is what is defining the development of conan.

So, as a conclusion for this post and **to summarize** our learnings in this first month after launch, we`d say that the most important thing is that **there is still a huge need** for a C and C++ portable package manager, as previous efforts have not lead to the minimal traction to take off. Given our experience in the field, it seems that **conan is a more than good enough solution** to the problem, and it is in the right track.

We are very grateful with the response and acceptance it is receiving, and we are quite confident that if people keep contributing with packages and pull requests as they have being doing so far, our community will have a wonderful tool for all of us this new (happy!) 2016 year. Let's keep working, **next 0.6 release soon**!



