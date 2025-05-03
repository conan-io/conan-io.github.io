---
layout: post
comments: false
title: "Introduction to WT library for C++"
---

When it comes to web development nobody thinks about C++, but when it comes to
performance everyone thinks about C++. Don't we care about performance when we
are developing or running a web service?

It is time to think about hardware resources again and maybe reconsider the web
stack. Can we reduce our hosting bill by orders of magnitude by using more
performant processes? Can we run a C++ backend and save tons of resources?

## WT : A Web Toolkit written in C++

There are different frameworks and libraries to write web applications in C++.
Today,  we are going to introduce you to [WT : a Web
Toolkit](https://www.webtoolkit.eu/wt) written in C++. It is a popular and
mature open-source library hosted on Github, with over 1000 stars. It has
outstanding
[documentation](https://www.webtoolkit.eu/wt/doc/reference/html/index.html)
featuring example code for almost all of it's major features. In this blog post,
we're going to provide an extremely simple example, and then add some widgets to
it iteratively.

## WT : A Simple Example

**Note:** We've recorded a screencast where we perform all the steps and show
the results of this example which you can view below.

{% include youtube-embed.html id="O2E-W9P-jKc" %}

One of the unique characteristics of WT when compared to many other web
frameworks is that you can write your web application as if you were writing a
desktop one. This provides a familiar experience to many C++ developers who have
worked on traditional Desktop applications in the past.

The first step is to write the `main` function. It should provide the function
that will instantiate the application after all the HTTP request is negotiated,
and the barebones of the application itself:

```cpp
#include <Wt/WApplication.h>
 
class HelloApplication : public Wt::WApplication {
   public:
       HelloApplication(const Wt::WEnvironment& env);
};
 
HelloApplication::HelloApplication(const Wt::WEnvironment& env) : WApplication(env) {
   setTitle("Application title");
}
 
int main(int argc, char **argv) {
   return Wt::WRun(argc, argv, [](const Wt::WEnvironment &env) {
       return std::make_unique<HelloApplication>(env);
   });
}
```

Next, we'll compile and run the application to verify that it works:

```bash
./bin/wt-example --docroot="." --http-listen=127.0.0.1:8080
curl http://127.0.0.1:8080/
```

## WT : Basic Widgets

To build the web application, Wt offers many built-in widgets for different HTML
elements: text, forms, charts, and many others contributed by the community.
Let's add a simple text and a form with a button:

```cpp
setTitle("Application title");
// Add simple text and form bith button
root()->addWidget(std::make_unique<Wt::WText>("Lorem ipsum dolor sit amet"));

nameEdit_ = root()->addWidget(std::make_unique<Wt::WLineEdit>());
nameEdit_->setMargin(5, Wt::Side::Left);
nameEdit_->setFocus();

auto button = root()->addWidget(std::make_unique<Wt::WPushButton>("Send"));
button->setMargin(5, Wt::Side::Left);
```

We can keep adding more widgets to the application, and use different layouts to
help with the placement of the widgets in the rendered webpage. But, here we
want to show how easy it is to connect these widgets and start building a useful
application.

Wt uses a signal system to connect one widget to others. Widgets emit different
events and we can connect other functions to these events.  Let's add an empty
text that will be populated after clicking the button.

```cpp

setTitle("Application title");

// Add simple text and form bith button
root()->addWidget(std::make_unique<Wt::WText>("Lorem ipsum dolor sit amet"));

nameEdit_ = root()->addWidget(std::make_unique<Wt::WLineEdit>());
nameEdit_->setMargin(5, Wt::Side::Left);
nameEdit_->setFocus();

auto button = root()->addWidget(std::make_unique<Wt::WPushButton>("Send"));
button->setMargin(5, Wt::Side::Left);

// Add a Text widget and connect the button to write to it
root()->addWidget(std::make_unique<Wt::WBreak>());
greeting_ = root()->addWidget(std::make_unique<Wt::WText>());
button->clicked().connect(this, &HelloApplication::greet);
```

It works like any desktop application, no need to manage HTTP requests. It's
just about connecting the signals and the Wt library behind the scenes
implements all the required functionality.

We can make the form interactive, and update the message with every keypress.
Using the signal mechanism this is quite easy to implement, just connect the
proper event to the function we want to execute:

All the implementation complexity is managed by the Wt library.

```cpp
setTitle("Application title");

// Add simple text and form bith button
root()->addWidget(std::make_unique<Wt::WText>("Lorem ipsum dolor sit amet"));

nameEdit_ = root()->addWidget(std::make_unique<Wt::WLineEdit>());
nameEdit_->setMargin(5, Wt::Side::Left);
nameEdit_->setFocus();

auto button = root()->addWidget(std::make_unique<Wt::WPushButton>("Send"));
button->setMargin(5, Wt::Side::Left);

// Add a Text widget and connect the button to write to it
root()->addWidget(std::make_unique<Wt::WBreak>());
greeting_ = root()->addWidget(std::make_unique<Wt::WText>());
button->clicked().connect(this, &HelloApplication::greet);

// Make the greeting interactive
root()->addWidget(std::make_unique<Wt::WBreak>());
greeting_ = root()->addWidget(std::make_unique<Wt::WText>());
nameEdit_->keyWentUp().connect(this, &HelloApplication::greet);
```

## WT : Widgets Gallery

And this is just the beginning. Have a look at the [widget
gallery](https://www.webtoolkit.eu/widgets) and all the built-in functionality
it provides. In addition to basic HTML elements, there are widgets for charts,
tables, graphics, or media:

## WT MVC Table

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-18/mvc-table.png"
     align="center" alt="WT MVC table widget"/>
</p>

## WT MVC Tree

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-18/mvc-tree.png"
     align="center" alt="WT MVC tree widget"/>
</p>

## WT 3D Category Chart

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-18/3d-category-chart.png"
     align="center" alt="WT 3D category chart widget"/>
</p>

## WT 3D Numerical Chart

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-18/3d-numerical-chart.png"
     align="center" alt="WT 3d numerical chart widget"/>
</p>

## WT Pie Chart

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-03-18/pie-chart.png"
     align="center" alt="WT pie chart widget"/>
</p>

## Conclusion

Wt is a powerful library for writing single page web applications, which
provides a familiar experience for developers who are accustomed to working with
desktop applications. Best of all, it brings the power, reliability,
performance, and integration which C++ provides.

Consider using C++ to build your next web application, and enjoy the benefits of
performant low-level libraries in the backend, such as data format parsers,
computation algorithms, usage of system sockets, and [hundreds of libraries
available in ConanCenter](https://conan.io/center/).
