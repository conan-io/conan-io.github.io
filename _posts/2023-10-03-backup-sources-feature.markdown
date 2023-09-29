---
layout: post
comments: false
title: "Enhancing Build Reliability with Conan's third-party source backup feature"
meta_title: "Delve into Conan's Source Backup feature"
description: "Discover how Conan's Source Backup feature can enhance the reproducibility, reliability, and efficiency of your builds, using practical insights from Conan Center."
---

## Introduction

In the fast-paced world of software development, reproducibility and traceability are
becoming increasingly crucial. However, what happens when the third-party sources you rely
on suddenly become unavailable? With the new Conan Source Backup feature, you can ensure
that your builds are not only reproducible but also resilient against the uncertainties of
external dependencies.

Thanks to this feature, you can configure Conan so that when a recipe downloads the
sources of a library, it allows you to fetch sources from a file server within your
infrastructure. This is done in a completely transparent manner for the developer and can
be set up to be used only as a last resort in case the URL of the original sources fails.

Some of the advantages of using this feature are:

- **Reproducibility**: Ensures long-term reproducibility in your builds.
- **Traceability**: Keeps a record of the origin of downloaded files.
- **Robustness**: Stores the sources in your own infrastructure, reducing reliance on
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

To use this feature, the first step is to have a file server. In Conan Center, we use a
generic Artifactory repository which seamlessly fits with our infrastructure, but you
could use any other file server that supports HTTP `PUT` and `GET` methods. The first
thing to configure is the server URL in the
[global.conf](https://docs.conan.io/2.0/reference/config_files/global_conf.html) file of
the Conan client:


```ini
# global.conf
core.sources:download_urls=["origin", "https://url/for/my-backup-sources-download-server/"] 
```

As illustrated, a list of different file servers can be provided, and Conan will refer to
this list each time it encounters a call to
[get()](https://docs.conan.io/2.0/reference/tools/files/downloads.html#conan-tools-files-get)
or
[download()](https://docs.conan.io/2.0/reference/tools/files/downloads.html#conan-tools-files-ftp-download)
in a recipe. To designate the original source, we use the reserved word `origin`. Thus,
this configuration will first attempt to find the sources on the original server, and if
that fails, it will fall back to our server (you can list them in the configuration by
order of preference). For instance, in Conan Center, we use this server:
[https://c3i.jfrog.io/artifactory/conan-center-backup-sources/](https://c3i.jfrog.io/artifactory/conan-center-backup-sources/).
Upon accessing it, we can view the information regarding the copies of the different
source origins:


<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-10-03/conan-center-server.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Configure Conan path"/>
</p>

Bear in mind, if server credentials are needed, they should be configured with the
[sources_credentials.json](https://docs.conan.io/2.0/reference/config_files/source_credentials.html#source-credentials-json)
configuration file. Another crucial point is that for the feature to be activated, the
`sha256` of the files used in `get()` or `download()` methods must be defined (as seen in
the image above, the sources of the packages are saved in files with the binary hash as
the name, accompanied by a metadata `.json` file).

With the explanation provided, a developer or continuous integration system would have
enough information to benefit from this feature for downloading sources. Now, we'll look
into the configuration needed on the client to facilitate the upload of those sources to
the server.

# Configuring the source upload

The source upload is typically executed from the CI server. In Conan Center, for example,
the backup of sources is uploaded every time a PR for a new version passes all checks
(turns green). This upload is performed transparently during a `conan upload` if the
following configuration is defined in the `global.conf` file.

```ini
# global.conf
core.sources:upload_url=https://url/for/my-backup-sources-upload-server 
```

It's important to note that the upload server could differ from the download servers.

Additionally, in some scenarios, it may be needed to exclude certain origins from the
backup sources upload (imagine it's code you don’t want all users to have access to). In
such cases, the following configuration can be utilized to skip them if a call is made,
and any URL that starts with the listed ones in the configuration will be skipped:

```ini
# global.conf
core.sources:exclude_urls=["https://url/mycompanystorage/", "https://url/mycompanystorage2/"] 
```

To explore the backup sources feature further, you can check the [Conan
documentation](https://docs.conan.io/2.0/devops/backup_sources/sources_backup.html#backup-sources-setup-remote).

## Conclusion

Conan's Source Backup feature is a potent tool for ensuring long-term reproducibility and
traceability of your builds. By taking a few simple steps to configure this feature, you
can shield your projects from the uncertainties associated with relying on third-party
source repositories.
