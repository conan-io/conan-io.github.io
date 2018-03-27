---
layout: post
comments: false
title: Announcing JFrog Artifactory Community Edition for C/C++
description: JFrog announces a great new release for the Conan ecosystem, Artifactory CE! An improved server for Conan repositories, providing all the power and flexibility of the Artifactory repository for Conan and generic binaries to the entirety of the Conan community for any team’s needs.
# other options
---

<link rel="stylesheet"
      href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/default.min.css">
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"></script>

Today, JFrog announces a great new release for the Conan ecosystem:
[JFrog Artifactory Community Edition for C/C++](https://jfrog.com/open-source/),
a completely free of charge server for Conan repositories. This product provides all the power and
flexibility of the Artifactory repository for Conan and generic binaries to the entirety of the Conan
community for any team’s needs.


<p class="centered">
    <img src="{{ site.url }}/assets/post_images/2018-03-27/artifactory_ce.png" align="center"
    width="600" alt="JFrog Artifactory Community Edition for C/C++"/>
</p>


JFrog Artifactory has been on the market for 10 years and is established as the premier solution for
managing binary repositories. The new Artifactory community edition features the following benefits:

- [**Local Conan Repositories**](https://www.jfrog.com/confluence/display/RTF/Conan+Repositories#ConanRepositories-LocalRepositories){:target="_blank"}
Power and collaboration capabilities of the conan_server combined with the power and flexibility of Artifactory

- [**Web UI**](https://www.jfrog.com/confluence/display/RTF/Browsing+Artifactory){:target="_blank"}
Easy to use UI allowing you to browse, search, and manage the contents of your repositories.

- **Advanced Authentication**
[User authentication support](https://www.jfrog.com/confluence/display/RTF/Managing+Users){:target="_blank"},
including available [LDAP authentication](https://www.jfrog.com/confluence/display/RTF/Managing+Security+with+LDAP),
local groups and the ability to [manage permissions](https://www.jfrog.com/confluence/display/RTF/Managing+Permissions)
on individual Conan repositories, packages and versions.

- **Better User Scalability**
More robust and able to handle a large number of concurrent users.

- [**Generic Repositories**](https://www.jfrog.com/confluence/display/RTF/Configuring+Repositories#ConfiguringRepositories-GenericRepositories){:target="_blank"}
Storage in Artifactory for all executables, installers, tarballs, and other random file types

- [**Checksum Based Storage with Deduplication**](https://www.jfrog.com/confluence/display/RTF/Checksum-Based+Storage){:target="_blank"}
Efficiently manage your binary files, reducing the filestore volume by deduplication. Any binary file that is checksum-identical is stored only once, so you can have as many copies of a binary package as you would like without worrying about on-disk storage costs. For example, multiple channels with the same package, or multiple revisions of a recipe with some binary packages the same and some different.

- [**Artifactory REST API**](https://www.jfrog.com/confluence/display/RTF/Checksum-Based+Storage){:target="_blank"}
Manage your binaries and automate all activities in your server through the powerful Artifactory REST API. This includes the ability to copy and move artifacts between repositories to institute promotion processes.

- [**JFrog CLI**](https://www.jfrog.com/confluence/display/CLI/JFrog+CLI){:target="_blank"}
A powerful, fast capability for managing generic binaries directly from a command line.

- [**Advanced Search**](https://www.jfrog.com/confluence/display/RTF/Searching+for+Artifacts){:target="_blank"}
Advanced Search functions for your repositories, based on advanced metadata such as date created, date last accessed and more.
You can also use these capabilities to [clean up](https://jfrog.com/blog/aql-cli-a-match-made-in-heaven/) unwanted binaries.

- [**Artifactory/Jenkins Plugin DSL for Conan**](https://www.jfrog.com/confluence/display/RTF/Working+With+Pipeline+Jobs+in+Jenkins#WorkingWithPipelineJobsinJenkins-ConanBuildswithArtifactory){:target="_blank"}
Basic linking between Artifactory and Jenkins for Conan binaries.


JFrog and the Conan project remain committed to the importance of an OSS reference implementation of
the Conan repository API. We will continue to publish and maintain the MIT-licensed Conan server.

Use the [following simple script](https://github.com/JFrogDev/artifactory-scripts/tree/master/conan/ConanServerToArtifactory){:target="_blank"}
to migrate your binaries from the Conan server to the JFrog Artifactory:


    import os
    import subprocess

    def run(cmd):
       ret = os.system(cmd)
       if ret != 0:
           raise Exception("Command failed: %s" % cmd)

    # Assuming local = conan_server and artifactory remotes
    output = subprocess.check_output("conan search -r=local --raw")
    packages = output.splitlines()

    for package in packages:
       print("Downloading %s" % package)
       run("conan download %s -r=local" % package)

    run("conan upload * --all --confirm -r=artifactory")



To learn more:

- Download JFrog Artifactory Community Edition for C/C++ from [Bintray](https://bintray.com/jfrog/product/JFrog-Artifactory-Cpp-CE/view){:target="_blank"}.
- If you want to learn more about using Conan and Artifactory together to create powerful DevOps for
  C/C++, join us for a dedicated Conan track at [JFrog’s user conference](https://swampup.jfrog.com/#training){:target="_blank"} on May 17-18.
  Training day on May 16th includes classes on Bintray, Artifactory and Conan.
  If you are a Conan contributor, contact us for a special promotional discount code!
