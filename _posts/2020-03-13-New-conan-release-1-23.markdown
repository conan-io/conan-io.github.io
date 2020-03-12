---
layout: post
comments: false
title: "Conan 1.23: Parallel installation of binaries, to speed up populating packages in a cache, Add environment variable ‘CONAN_V2_MODE’ to enable Conan v2 behavior."
---

March bring us a new Conan release. Sadily it also brought us the notice of having to postpone
ConanDays due to growing concerns about the Coronavirus. This was a hard decision for the safety and
well being of all of you, but we hope it will make possible for an even greater meeting of the Conan
community in the near future. But lets focus on the good news and see what comes with Conan 1.23.

## Parallel binary downloads

As you know, we have been doing a great effort to speed-up several Conan commands especially aiming
to lower the CI times. We already implemented some cool features in Conan 1.21 and 1.22:

 - [Parallel
   uploads](https://docs.conan.io/en/latest/reference/commands/creator/upload.html#conan-upload):
   since Conan 1.21, it is possible to upload Conan packages to remotes faster thanks to the use of
   multiple threads. To activate this feature you just have to add the `--parallel` argument to the
   `conan upload` command. This feature can get and **increase in speed for around 400%** depending
   on the situation. 

 - [Download
   cache](https://docs.conan.io/en/latest/configuration/download_cache.html#download-cache): in Conan
   1.22 we introduced a download cache that can be concurrently used by several Conan instances using
   different `CONAN_USER_HOME` folders. This cache can be shared between different simultaneous CI
   jobs, so if the files were previously downloaded, they will be reused from the cache without the
   need to download them again. Use this feature setting storage.download_cache="path/to/the/cache"
   in conan.conf.

Now, as the icing on the cake on Conan 1.23 we are providing the possibility to also download
binaries in parallel. To use it, set ``general.parallel_download`` in `conan_conf`. This parameter
has to be set to the number of threads you want to use for downloading and will speed-up. This
setting will be used when dependencies are installed (``conan install``, ``conan create``) and when
multiple binaries for the same package are retrieved via ``conan download`` command.

Let's see an example of how much time we could save using this feature if we need, for example, to
downmload a package for lots of configurations. We will download zlib/1.2.11 for all the 82 different
configurations available in [Conan-Center Index](https://github.com/conan-io/conan-center-index).
Doing this would tipically take **around 3 minutes** for a regular Internet connection.

We will set the number of download threads to 8 but feel free to play with this setting depending on
your machine.

```
➜ conan config set general.parallel_download=8
➜ time conan download zlib/1.2.11      
Downloading conanmanifest.txt completed [0.29k]                                          
Downloading conanfile.py completed [7.59k]                                               
Downloading conan_export.tgz completed [0.23k]                                           
Decompressing conan_export.tgz completed [0.00k]                                         
Downloading conan_sources.tgz completed [6.91k]                                          
Decompressing conan_sources.tgz completed [0.00k]                                        
zlib/1.2.11: Getting the complete package list from 'zlib/1.2.11#419994c54789da229ef991be6c2563b3'...
zlib/1.2.11: Downloading binary packages in 8 parallel threads
zlib/1.2.11: Retrieving package 6cc50b139b9c3d27b3e9042d5f5372d327b3a9f7 from remote 'conan-center' 
zlib/1.2.11: Retrieving package 37dbc353875958e967097ad32a2b5aa8894ae5fb from remote 'conan-center' 
...                              
Downloading conaninfo.txt completed [0.46k]                                              
Downloading conan_package.tgz completed [88.12k]                                         
Decompressing conan_package.tgz completed [0.00k]                                        
zlib/1.2.11: Package installed c83d8b197f1a331ca3b55943846d427ad4f7f8e1
conan download zlib/1.2.11@ -r conan-center  4.23s user 0.96s system 16% cpu 30.536 total       
```

As you can see it just took around 30 seconds to download all the binaries what means an
**improvement of around a 600% in time**.

If you try this feature you may experience some message overlaps in the command line output. We have prioritized the feature over a clean output but will solve these output problems in the near future.





<br>

-----------

<br>

Have a look at the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html).

Please, report any bug or share your feedback opening a new issue in our [issue
tracker](https://github.com/conan-io/conan/issues) and don't forget to
[update](https://conan.io/downloads.html).
