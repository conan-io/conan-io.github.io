---
layout: post
comments: false
title: "Conan Extension for Visual Studio"
---

Thanks to our amazing community we can release a first version of the
[Conan Extension for Visual Studio](https://marketplace.visualstudio.com/items?itemName=conan-io.conan-vs-extension).
It's been a team effort of several people, we have to mention SSE4, ForNeVer, solvingj and
sboulema, but many others have contributed providing feedback, reporting early issues and
testing the first versions ([all contributors](https://github.com/conan-io/conan-vs-extension/graphs/contributors)).
Thanks to all of them today we have an usable version we want
to endorse and share with the rest of our users. 

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-05-09/marketplace-header.png" width="600"/>
        <figcaption>Conan Extension for Visual Studio in the Microsoft marketplace</figcaption>
    </figure>
</div>

This extension provides smooth integration between Conan and your Visual Studio project. It
will detect a ``conanfile.py`` or ``conanfile.txt`` next to a project file (or in parent directory),
retrieve the requirements and generate the property sheet (``.props`` file) with all the information
of the dependencies handled by Conan to be included in that project. The extension will also add
the property sheet automatically to the project.

## Install and configure

This first version we are releasing, ``v1.0.x`` has a very basic behaviour and configuration, but
it covers the most common use cases. Once you have Conan already installed in your system,
follow the next steps to get it working in your Visual Studio IDE (only version 2017 and
2019 are currently supported):

 * Use the Extensions Manager of your IDE to find "Conan Extension for Visual Studio" and click
   the download button to install it. Alternatively you can go to the
   [marketplace](https://marketplace.visualstudio.com/items?itemName=conan-io.conan-vs-extension),
   download de VSIX file and install it.
   
    <div align="center">
        <figure>
            <img src="{{ site.url }}/assets/post_images/2019-05-09/vs-marketplace-conan.png" width="600"/>
            <figcaption>Install Conan using the Extension Manager inside Visual Studio</figcaption>
        </figure>
    </div>
       
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

To use this extension you will need a ``conanfile.txt`` or ``conanfile.py`` in your **Visual Studio
project** declaring the requirements of your project. Conan will download them from the configured
remotes (or build them if binaries are not available), the extension will generate the `.props`
file and it will automatically included it in your project with all the paths and flags needed
to use and link against those required libraries.

Conan will detect the configuration used in your build to select the proper settings for the
requirements, so if you change build type from ``Debug`` to ``Release``, the toolset or runtime,
Conan will use the proper settings and flags to retrieve or build the matching binaries.
The output window shows all the information printed by Conan related to the executed command.

<div align="center">
    <figure>
        <img src="{{ site.url }}/assets/post_images/2019-05-09/vs-screen.png" width="600"/>
        <figcaption>Visual Studio project using Conan Extension</figcaption>
    </figure>
</div>

Have a look at the [CLI example](https://github.com/conan-io/conan-vs-extension/tree/master/Conan.VisualStudio.Examples/ExampleCLI)
available in our repository, and if you have doubts, face any issue or want to provide useful
feedback, you can reach us in [Cpplang Slack](https://cpplang.slack.com/messages/C41CWV9HA/),
social networks and, of course, in [Github](https://github.com/conan-io).

Keep updated to new versions, there is a lot of work ahead and we expect to release new versions
of this plugin with new functionalities.

Happy coding!
