---
layout: post
comments: false
title: "The New ConanCenter Improves Search and Discovery"
---

<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2020-01-13/new_conan_center.png" align="center" alt="New ConanCenter Improves Search and Discovery"/>
</p>


We’re excited to announce the new and improved [ConanCenter](https://conan.io/center/)! Use our new center with an enhanced UI experience to discover your favorite Conan C/C++ packages. 

If you’re not familiar with Conan yet, it’s a decentralized package manager for C/C++ that empowers developers to share packages through a push-pull model similar to Git. ConanCenter is a central repository for open source Conan packages, created and maintained by JFrog.

## Discover the New ConanCenter

When you [visit the new ConanCenter](https://conan.io/center/), you’ll notice the search bar prominent on the first page. You can use it to search for any package by name or description, and retrieve a list of results showing the package version and number of downloads. 

You’ll also notice that the new center has a look and feel that is unified across other JFrog services. It is sleek, focused primarily on search and discovery, and meant to help package authors find rich metadata by providing quick access to Conan packages recipe and configuration information.


<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2020-01-13/new_conan_center_screen.png" align="center" alt="New ConanCenter Improves Search and Discovery"/>
</p>



The configurations page itself is a vast improvement and enables access to a multitude of configurations for each version of a package. You start by selecting an operating system, an architecture, and a compiler to drill-down on the available binaries and find any number of configuration options. Note that every configuration possible for a package may not be immediately available, but as package authors add more to the conan-center-index - the binaries available will be exposed in the UI as well. 


## A New Contribution Process with Artifactory at its Core

One primary infrastructural change with the new ConanCenter is that new packages and versions are now made available through an improved process in a continuous integration system that is managed in a process centered on JFrog Artifactory. This process includes verifying new packages from contributors added through a pull request on the recipes for the [conan-center-index repository on GitHub](https://github.com/conan-io/conan-center-index/wiki). This provides more visibility into how packages get into ConanCenter and improves the audit trail of individual binaries. We’ve opened up this process as part of an “Early Access Program” outlined below. In mid-2020, this will become the only way to make packages available in the new ConanCenter. If you’re currently uploading your Conan packages on Bintray, please migrate to adding packages through the Early Access Program. 

To privately host your own packages, JFrog also provides a free [Artifactory Community Edition for C / C++ for download](https://conan.io/downloads.html).


## EAP: Join Us as a Package Author

From the very start of this project, we wanted to make it easy for contributors and package authors to add new packages to ConanCenter. You’ll already see we have tens of thousands of package versions belonging to hundreds of open source libraries.

You can contribute your packages as well, and share them with thousands of ConanCenter users across the globe.

To contribute new packages, you’ll need to join the Early Access Program. To enroll in EAP, please add a comment on this GitHub issue. 

Once you’re an EAP member, you can add packages to ConanCenter through GitHub:

On the landing page of conan.io/center, you’ll see the Add New Packages button, which will direct you to make a pull request to [conan-center-index](https://github.com/conan-io/conan-center-index) to add new recipes. The specific steps to add new packages are:

1. Fork the conan-center-index git repository, and then clone it.
2. Create a new folder with the Conan package recipe (conanfile.py) and the metadata
3. Push to GitHub, and submit a pull request.
4. Our automated build service will build 100+ different configurations, and provide messages that indicate if there were any issues found during the pull request on GitHub.
 
When the pull request is reviewed and merged, those packages are published to conan.io/center. You can learn more by [Reading the Conan Docs](https://docs.conan.io/en/latest/uploading_packages/bintray/conan_center_guide.html).


## Tell Us What You Think
 
Our team is continuing to enhance the search capabilities and workflow of the new center. As ConanCenter evolves, we expect to add better package discovery, more curation, and content that helps you find your Conan C / C++ project dependencies. We’d love to hear from you about improving the features of the current center and how we can enhance the overall experience. As you search for packages, let us know what might be helpful. 

We’re still improving the overall search and discovery experience on the new ConanCenter, but we would love to hear your immediate feedback. To give specific feedback you can make a comment on the [issues in GitHub](https://github.com/conan-io/conan-center-index/issues/new/choose). 
