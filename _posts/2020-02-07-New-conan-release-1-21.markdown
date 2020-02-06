---
layout: post
comments: false
title: "Conan 1.22: New download cache that can provide big speed-ups, GLOBAL CMake targets can now
be aliased, SCM learned to store information in conandata.yml, Python 2 support is deprecated"
---

2020 has arrived with lots of new features and bugfixes in Conan 1.22. Let's check some of the most important.

## New download cache

As we release new Conan versions we are trying to help to speed-up the CI's step by step. In Conan
1.21 we introduced the [parallel
uploads](https://docs.conan.io/en/latest/reference/commands/creator/upload.html?highlight=parallel#conan-upload)
that can get and **increase in speed for around 400%**. 

Now we are releasing a new cache that can be
concurrently used among different user conan homes. This cache can be shared among different
concurrent Conan instances so if our CI is using different jobs, each one of those with a different
`CONAN_USER_HOME` they will share the download cache as a source for the files in case they are
already there.

If you want to test this feature you have to set the appropiate configuration in the conan.conf

```
$ conan config set storage.download_cache="/path/to/my/cache"
```

You could do a test of the feature by subsequently changing the `CONAN_USER_HOME` setting the
same downloads cache for all each home and the installing a relatively big package:

```
$ export CONAN_USER_HOME=/Users/yourusername/conan_home_1/
$ conan config set storage.download_cache="/Users/yourusername/central_cache"
$ time conan install boost/1.72.0@
...
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', 'boost_exception', 'boost_graph', 'boost_iostreams', 'boost_locale', 'boost_log', 'boost_program_options', 'boost_random', 'boost_regex', 'boost_serialization', 'boost_wserialization', 'boost_coroutine', 'boost_context', 'boost_timer', 'boost_thread', 'boost_chrono', 'boost_date_time', 'boost_atomic', 'boost_filesystem', 'boost_system', 'boost_type_erasure', 'boost_log_setup', 'boost_math_c99', 'boost_math_c99f', 'boost_math_c99l', 'boost_math_tr1', 'boost_math_tr1f', 'boost_math_tr1l', 'boost_stacktrace_addr2line', 'boost_stacktrace_basic', 'boost_stacktrace_noop', 'boost_unit_test_framework']
boost/1.72.0: Package folder: /Users/carlos/conan_home_2/.conan/data/boost/1.72.0/_/_/package/69168f775732984eb37d785004b6ef25111fe5f9
conan install boost/1.72.0@  4.70s user 3.87s system 36% cpu 23.428 total
...
$ export CONAN_USER_HOME=/Users/yourusername/conan_home_2/
$ conan config set storage.download_cache="/Users/yourusername/central_cache"
$ time conan install boost/1.72.0@
...
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', 'boost_exception', 'boost_graph', 'boost_iostreams', 'boost_locale', 'boost_log', 'boost_program_options', 'boost_random', 'boost_regex', 'boost_serialization', 'boost_wserialization', 'boost_coroutine', 'boost_context', 'boost_timer', 'boost_thread', 'boost_chrono', 'boost_date_time', 'boost_atomic', 'boost_filesystem', 'boost_system', 'boost_type_erasure', 'boost_log_setup', 'boost_math_c99', 'boost_math_c99f', 'boost_math_c99l', 'boost_math_tr1', 'boost_math_tr1f', 'boost_math_tr1l', 'boost_stacktrace_addr2line', 'boost_stacktrace_basic', 'boost_stacktrace_noop', 'boost_unit_test_framework']
boost/1.72.0: Package folder: /Users/carlos/conan_home_3/.conan/data/boost/1.72.0/_/_/package/69168f775732984eb37d785004b6ef25111fe5f9
conan install boost/1.72.0@  4.03s user 3.38s system 51% cpu 14.491 total
...
```

As you can see in the command line output, the first time, with a completely empty cache the download
takes **23.428 seconds**, that is the same time that it would have taken to download if there was no
cache. After setting the second `CONAN_USER_HOME` with the downloads cache pointing to the same
folder the download time is **14.491 seconds** which is almost the half of the time it would take
without the downloads cache.

If you want to deactivate the cache, don't forget to do:

```
$ conan config rm storage.download_cache
```

An then removing the contents of the cache folder. Also, if you changed the `CONAN_USER_HOME`,
restore it to the original value.

## GLOBAL CMake targets


## SCM and conandata.yml


## Python 2 deprecation

## Other cool things


<br>

-----------

<br>

