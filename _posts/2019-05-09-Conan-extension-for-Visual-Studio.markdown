---
layout: post
comments: false
title: "Conan Extension for Visual Studio"
---

Thanks to our amazing community we can release today a first version of the
[Conan Extension for Visual Studio](https://marketplace.visualstudio.com/items?itemName=conan-io.conan-vs-extension).
It's been a team effort of several people, we have to mention SSE4, ForNeVer, solvingj and
sboulema, but many others have contributed providing feedback, reporting early issues and
testing the first versions ([all contributors](https://github.com/conan-io/conan-vs-extension/graphs/contributors)). Thanks to all of them today we have an usable version we want
to endorse and share with the rest of our users. 

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-05-09/marketplace-header.png" width="600"/>
        <figcaption>Conan Extension for Visual Studio in the Microsoft marketplace</figcaption>
    </figure>
</div>

This extension provides an smooth integration between Conan and your Visual Studio project. It
will detect a ``conanfile.py`` or ``conanfile.txt`` in the solution, retrieve the requirements
and generate the `.prop` file to be included in your solution.

## Install and configure

This first version we are realeasing in May has a very basic behaviour and configuration, but
it convers the most common use cases. Once you have Conan already installed in your system,
follow the next steps to get it working in your Visual Studio IDE (only version 2017 and
2019 are currently supported):

 * Use the Extensions Manager of your IDE to find "Conan Extension for Visual Studio" and click
   the download button to install it. Alternatively you can go to the
   [marketplace](https://marketplace.visualstudio.com/items?itemName=conan-io.conan-vs-extension),
   download de VSIX file and install it.
   
   >>> Image here with the extension found in the marketplace (download button...) <<<<
 * Enter the configuration options of the Conan Extension and make sure that the Conan executable
   has been correctly identified.
    
    <div align="center">
        <figure>
            <img src="{{ site.url }}/assets/post_images/2019-05-09/tools-options.png" width="600"/>
            <figcaption>Accessing the options for Conan Extension</figcaption>
        </figure>
    </div>
 
   You can leave the other options with the default values, it isn't the aim of this blog post
   to enter into those details, but you can read about them and many other features in the
   [Conan documentation](https://docs.conan.io/en/latest/).

## Use Conan Extension for Visual Studio

To use this extension you will need a ``conanfile.txt`` or ``conanfile.py`` in your Visual Studio
solution declaring the dependencies of your project. Conan will download them from the configured
remotes (or build them if binaries are not available) and generate the `.prop` file that will
be included in your project with all the paths and flags needed to use and link against that
required libraries.

Conan will detect the configuration used in your build to select the proper settings for the
requirements, you can change build type from ``Debug`` to ``Release``, or the toolset and Conan
will use the proper settings and flags. You can check it having a look to the output window.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-05-09/vs-screen.png" width="600"/>
        <figcaption>Visual Studio project using Conan Extension</figcaption>
    </figure>
</div>

Have a look at the [CLI example](https://github.com/conan-io/conan-vs-extension/tree/master/Conan.VisualStudio.Examples/ExampleCLI)
available in our repository, and if you have doubts, face any issue or want to provide useful
feedback, you can reach us in Cpplang Slack (channel #conan), social networks and, of course,
in [Github](https://github.com/conan-io).

Keep updated to new versions, there is a lot of work ahead and we expect to release new versions
of this plugin with new functionalities.

Happy coding!
