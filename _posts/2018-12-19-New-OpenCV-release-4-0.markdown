---
layout: post
comments: false
title: OpenCV 4.0.0 new Graph API (G-API)
description: OpenCV has released new 4.0.0 version, which introduces new feature called G-API
---

### What is OpenCV?

[OpenCV](https://opencv.org) stands for **Open**-Source **C**omputer-**V**ision Library.

As name suggests, library has lots of various features for computer vision, for instance:

* [Machine Learning](https://docs.opencv.org/master/d1/d69/tutorial_table_of_content_ml.html)
* [Image processing](https://docs.opencv.org/master/d7/da8/tutorial_table_of_content_imgproc.html)
* [Motion analysis](https://docs.opencv.org/master/d7/df3/group__imgproc__motion.html)
* [Gesture recognition](https://docs.opencv.org/master/d9/db7/group__datasets__gr.html)
* [Face recognition](https://docs.opencv.org/master/de/d93/group__datasets__fr.html)

OpenCV is cross-platform, supporting major desktop platforms (Windows, Linux, MacOS), as well as mobile platforms (iOS, Android).

The project is open-source software, licensed under BSD license.

Also, it has bindings for Java, Python, Haskel, MATLAB, etc.

OpenCV has strong focus on performance, with optimized code for various microarchitectures (SSE and AVX on x86, NEON on ARM, VSX on PowerPC, etc).

Library is suitable for heterogeneous computing, supporting CUDA and OpenCL.

To summarize, OpenCV library is very large, and has tons of features for the computer vision. In addition, it has collection of additional modules called [OpenCV Contrib](https://github.com/opencv/opencv_contrib), if base is not enough.

### What's new in OpenCV 4.0.0 release?

OpenCV has released final version [4.0.0](https://opencv.org/opencv-4-0-0.html) on November 2018.

There are a lot of new features (see the complete [changelog](https://opencv.org/opencv-4-0-0.html)), for instance:

* [QR-Code detector](https://docs.opencv.org/4.0.0/de/dc3/classcv_1_1QRCodeDetector.html)
* [G-API framework](https://docs.opencv.org/4.0.0/d7/d0d/group__gapi.html)
* [KinectFusion algorithm](https://docs.opencv.org/4.0.0/d8/d1f/classcv_1_1kinfu_1_1KinFu.html)

also, OpenCV 4.x is getting rid of some technical debt, for example:

* OpenCV is now [C++11](https://en.wikipedia.org/wiki/C%2B%2B11) library and requires [C++11-compliant compiler](https://en.cppreference.com/w/cpp/compiler_support#cpp11)
* Removed many of OpenCV 1.x C APIs
* [std::string](https://en.cppreference.com/w/cpp/string/basic_string) and [std::shared_ptr](https://en.cppreference.com/w/cpp/memory/shared_ptr) are now used instead of hand-crafted [cv::String](https://docs.opencv.org/3.4/d1/d8f/classcv_1_1String.html) and [cv::Ptr](https://docs.opencv.org/3.4/d0/de7/structcv_1_1Ptr.html)

as usual, there are numerous bug fixes and performance improvements.

### OpenCV G-API

Let's take a deeper look at new OpenCV feature called [G-API](https://github.com/opencv/opencv/wiki/Graph-API) (stands for Graph API).

Previously, with classic OpenCV 2.x API, programming model was very traditional - you call OpenCV functions, they perform some computations and return the result. This model should look familar and natural to the most programmers, as it's similar to regular [filesystem API](https://en.cppreference.com/w/cpp/experimental/fs), for example.
OpenCV 4.x introduces very different programming model where you define pipeline of operations to be performed first, and then apply this pipeline to some actual data. In other words, whenever you call OpenCV G-API function, execution is deferred (lazily-evaluated), and deferred operation result is being returned instead of actual computation result. This concept might sound very similar to [Ranges TS](https://en.cppreference.com/w/cpp/experimental/ranges) (or [Range V3](https://github.com/ericniebler/range-v3), or [Boost Range](https://www.boost.org/doc/libs/1_68_0/libs/range/doc/html/index.html)).

This is an especially important feature, as if you don't need to get an intermediate results, you can easily off-load the entire pipeline into the GPU, therefore there will be no intermediate copying from the system to the video memory and vice versa - only initial input and final output has to be loaded to/from the GPU.

### Practicing G-API

Complete code examples from this blog post are available on GitHub: [opencv4-demo](https://github.com/SSE4/opencv4-demo) (project uses [CMake](https://cmake.org) and [conan](https://conan.io) to build).

For instance, we have the following code which uses classic OpenCV 2.x API:

{% highlight cpp %}

#include <cstdlib>
#include <opencv2/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>

int main(int argc, char * argv[])
{
    cv::Mat imgIn = cv::imread("in.png"), imgBlur, imgGray, imgOut, sobelX, sobelY, gradX, gradY;

    cv::GaussianBlur(imgIn, imgBlur, cv::Size(3, 3), 0, 0, cv::BORDER_DEFAULT);

    cv::cvtColor(imgBlur, imgGray, cv::COLOR_BGR2GRAY);

    cv::Sobel(imgGray, sobelX, CV_16S, 1, 0, 3);
    cv::Sobel(imgGray, sobelY, CV_16S, 0, 1, 3);

    cv::convertScaleAbs(sobelX, gradX);
    cv::convertScaleAbs(sobelY, gradY);

    cv::addWeighted(sobelX, 0.5, sobelY, 0.5, 0, imgOut);

    cv::imwrite("out.png", imgOut);

    return EXIT_SUCCESS;
}

{% endhighlight %}

The example takes an input image file, blurs it, converts to the grayscale and finally applies the [Sobel operator](https://en.wikipedia.org/wiki/Sobel_operator), then saves result of operator applied to an another image file. So, if we have the following image file as an input:

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2018-12-19/in.png"  align="center"
    width="300"  alt="A color picture of a steam engine"/>
</p>

then result might look like:

<p class="centered">
    <img  src="{{ site.url }}/assets/post_images/2018-12-19/out.png"  align="center"
    width="300"  alt="The Sobel operator applied to that image"/>
</p>

Such code is usually used for the [edge detection](https://en.wikipedia.org/wiki/Edge_detection), which is frequently used image processing task.

Okay, how to migrate the code you already have to the G-API? First off, you'll need to include additional OpenCV headers:

{% highlight cpp %}

#include <opencv2/gapi.hpp>
#include <opencv2/gapi/core.hpp>
#include <opencv2/gapi/imgproc.hpp>

{% endhighlight %}

Second, functions from the **cv::** namespace are being replaced by corresponding functions from the new **cv::gapi::** namespace, e.g. [cv::Sobel](https://docs.opencv.org/4.0.0/d4/d86/group__imgproc__filter.html#gacea54f142e81b6758cb6f375ce782c8d) becomes [cv::gapi::Sobel](https://docs.opencv.org/4.0.0/da/dc5/group__gapi__filters.html#gae1443445c4cb3187dcf439a57cfa534f), and so on. These functions do not have an output argument, instead, they return value of [cv::GMat](https://docs.opencv.org/4.0.0/df/daa/classcv_1_1GMat.html) type (analogue of well-known [cv::Mat](https://docs.opencv.org/4.0.0/d3/d63/classcv_1_1Mat.html) type). Same for the input arguments - they also accept **cv::GMat**.
Some functions might be missing in the **cv::gapi::** namespace, for instance [cv::convertScaleAbs](https://docs.opencv.org/4.0.0/d2/de8/group__core__array.html#ga3460e9c9f37b563ab9dd550c4d8c4e7d), but it's pretty straightforward to implement it yourself:

{% highlight cpp %}

static cv::GMat convertScaleAbs(const cv::GMat & src, double alpha = 1.0, double beta = 0.0)
{
    auto result = cv::gapi::absDiffC(cv::gapi::addC(cv::gapi::mulC(src, alpha), beta), 0.0);
    return cv::gapi::convertTo(result, CV_8UC1);
}

{% endhighlight %}

With implementation above, rewriting image processing code is pretty straightforward:

{% highlight cpp %}

    auto imgBlur = cv::gapi::gaussianBlur(gIn, cv::Size(3, 3), 0, 0, cv::BORDER_DEFAULT);

    auto imgGray = cv::gapi::convertTo(imgBlur, CV_32F);

    auto sobelX = cv::gapi::Sobel(imgGray, CV_16S, 1, 0, 3);
    auto sobelY = cv::gapi::Sobel(imgGray, CV_16S, 0, 1, 3);

    auto gradX = convertScaleAbs(sobelX);
    auto gradY = convertScaleAbs(sobelY);

    auto gOut = cv::gapi::addWeighted(sobelX, 0.5, sobelY, 0.5, 0);

{% endhighlight %}

Once pipeline is established, it's time to construct the [cv::GComputation](https://docs.opencv.org/4.0.0/d9/dfe/classcv_1_1GComputation.html) object:

{% highlight cpp %}

    cv::GComputation computation(cv::GIn(gIn), cv::GOut(gOut));

{% endhighlight %}

And finally, computation might be applied to the actual data:

{% highlight cpp %}

    computation.apply(cv::gin(imgIn), cv::gout(imgOut));

{% endhighlight %}

At this time, actual data processing takes its place.

The complete example using the G-API:

{% highlight cpp %}

#include <cstdlib>
#include <opencv2/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/gapi.hpp>
#include <opencv2/gapi/core.hpp>
#include <opencv2/gapi/imgproc.hpp>

static cv::GMat convertScaleAbs(const cv::GMat & src, double alpha = 1.0, double beta = 0.0)
{
    auto result = cv::gapi::absDiffC(cv::gapi::addC(cv::gapi::mulC(src, alpha), beta), 0.0);
    return cv::gapi::convertTo(result, CV_8UC1);
}

int main(int argc, char * argv[])
{
    cv::GMat gIn;

    auto imgBlur = cv::gapi::gaussianBlur(gIn, cv::Size(3, 3), 0, 0, cv::BORDER_DEFAULT);

    auto imgGray = cv::gapi::convertTo(imgBlur, CV_32F);

    auto sobelX = cv::gapi::Sobel(imgGray, CV_16S, 1, 0, 3);
    auto sobelY = cv::gapi::Sobel(imgGray, CV_16S, 0, 1, 3);

    auto gradX = convertScaleAbs(sobelX);
    auto gradY = convertScaleAbs(sobelY);

    auto gOut = cv::gapi::addWeighted(sobelX, 0.5, sobelY, 0.5, 0);

    cv::GComputation computation(cv::GIn(gIn), cv::GOut(gOut));

    cv::Mat imgIn = cv::imread("in.png"), imgOut;

    computation.apply(cv::gin(imgIn), cv::gout(imgOut));

    cv::imwrite("out.png", imgOut);

    return EXIT_SUCCESS;
}

{% endhighlight %}

### Conclusion

OpenCV 4.0 release adds very foundational changes, that completely change the way how do you write programs, making support of heterogeneous computing much more straightforward.
Feel free to try to experiment with new OpenCV features, such as G-API, check out the [opencv4-demo](https://github.com/SSE4/opencv4-demo) repository, in order to compile and run examples from this article.
