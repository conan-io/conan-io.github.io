---
layout: post
comments: false
title: "Ensuring Build Reproducibility with Conan's Source Backup Feature"
meta_title: "Introduction to the Conan's Source Backup feature"
description: "Explore the benefits and implementation details of Conan's Source Backup feature to improve the reproducibility and security of your builds"
---

# Ensuring Build Reproducibility with Conan's Source Backup Feature

## Introduction

In the fast-paced world of software development, reproducibility and traceability are more
and more a need. But what happens when the third-party sources you rely on suddenly become
unavailable? With the new Conan Source Backup feature you can ensure that your builds are not
only reproducible but also resilient against the uncertainties of external dependencies.

Thanks to this feature, you can configure Conan so that when a recipe downloads the
sources of a library, it allows you to fetch sources on a file server within your
infrastructure. This is done in a completely transparent manner for the developer and can
be set up to be used only as a last resort in case the URL of the original sources fails.

Some of the advantages of using this feature are:

- **Reproducibility**: Ensures long-term reproducibility in your builds. 
- **Traceability**: Keeps a record of the origin of downloaded files. 
- **Security**: Stores the sources in your own infrastructure, reducing reliance on
  third-party services.
- **Improved Speed**: Hosting source files internally can yield faster download speeds
  compared to fetching from external servers.
- **Cost Efficiency**: Having sources within the same network can reduce egress charges,
  thus saving on networking costs.

In this post, we'll show you how to make the most of the sources backup feature, using our
experience at Conan Center as an example. This will give you a clear picture of how you
can seamlessly integrate this feature into your workflow for better reliability and
efficiency.

## How the Conan team uses this feature in Conan Center

This feature has been used for some time now in a production environment like Conan
Center. Conan Center hosts over 6000 distinct references with thousands of different
source origins. Hence, it's highly susceptible to situations where some of these source
origins might become unavailable or even disappear. Under these conditions, it becomes an
ideal production environment for the internal use of Conan's Sources Backup feature within
the CI server.

# Using the feature on the developer side

To use this feature, the first step is to have a file server. In Conan Center, we use
a generic Artifactory repository which seamlessly fits with our infrastructure, but you
could use any other file server that supports HTTP `PUT` and `GET` methods. The first
thing to configure is the server URL in the
[global.conf](https://docs.conan.io/2.0/reference/config_files/global_conf.html) file of
the Conan client:

```ini
# global.conf
core.sources:download_urls=["origin",
"https://url/for/my-backup-sources-download-server/"] 
```

As you can see, it's a list where different file servers can be provided to which Conan
will resort each time it encounters a call to
[get()](https://docs.conan.io/2.0/reference/tools/files/downloads.html#conan-tools-files-get)
or
[download()](https://docs.conan.io/2.0/reference/tools/files/downloads.html#conan-tools-files-ftp-download)
in a recipe. To designate the original source, we use the reserved word `origin`. This
way, this configuration will first look for the sources on the original server, and if
anything fails, it will resort to our server. For instance, in Conan Center we use this
server:
[https://c3i.jfrog.io/artifactory/conan-center-backup-sources/](https://c3i.jfrog.io/artifactory/conan-center-backup-sources/).
If we access it, we can see the information regarding the copies of the different source
origins:

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-09-29/conan-center-server.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Configure Conan path"/>
</p>

Bear in mind, if you need credentials for the server, you should configure them with the
[sources_credentials.json](https://docs.conan.io/2.0/reference/config_files/source_credentials.html#source-credentials-json)
configuration file. Another important thing to note is that for the feature to be
activated, the `sha256` of the files used in `get()` or `download()` methods must be
defined (as seen in the image above, the sources of the packages are saved in files that
have the binary hash as the name, along with a metadata `.json` file).

With what has been explained so far, it would be enough for a developer or continuous
integration system to benefit from this feature when it comes to downloading the sources.
Now we will see the configuration that should be applied on the client to configure the
upload of those sources to the server.

# Configuring the source upload

The source upload is something that will typically be done from the CI server. This upload
is carried out completely transparently at the time of doing a `conan upload` if the
following configuration is defined in the `global.conf` file.

```ini
# global.conf
core.sources:upload_url=https://url/for/my-backup-sources-upload-server 
```

It's important to mention that the upload server could be different from the download
servers.

Also, in certain cases, it may be useful to exclude certain origins from the backup
sources upload (imagine it's code you don’t want all users to have access to). In these
cases, the following configuration can be used to skip them in case a call is made and any
URL that starts with the listed ones in the configuration will be skipped:

```ini
# global.conf
core.sources:exclude_urls=['https://url/mycompanystorage/', 'https://url/mycompanystorage2/'] 
```

To delve deeper into the backup sources feature, you can check the [complete
documentation](https://docs.conan.io/2.0/devops/backup_sources/sources_backup.html#backup-sources-setup-remote).

## Conclusion

The Source Backup feature in Conan is a powerful tool for ensuring the long-term
reproducibility and traceability of your builds. By taking a few simple steps to configure
this feature, you can safeguard your projects against the uncertainties of relying on
third-party source repositories.
