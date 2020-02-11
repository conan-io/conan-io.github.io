---
layout: post
comments: false
title: "Conan 1.22: New downloads cache, Store scm data in conandata.yml, Python 2 deprecation and
more."
---

2020 has started with lots of new features and bugfixes in Conan 1.22. Let's check some of the most
important.

## New download cache

With each new Conan release we are trying to help to speed-up the CI's step by step. In Conan 1.21 we
introduced the [parallel
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
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', ...
boost/1.72.0: Package folder: /Users/carlos/conan_home_2/.conan/data/boost/1.72.0/_/_/package/69168f775732984eb37d785004b6ef25111fe5f9
conan install boost/1.72.0@  4.70s user 3.87s system 36% cpu 23.428 total
...
$ export CONAN_USER_HOME=/Users/yourusername/conan_home_2/
$ conan config set storage.download_cache="/Users/yourusername/central_cache"
$ time conan install boost/1.72.0@
...
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', ...
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

## Easier credential handling when using SCM

When using `scm` and `auto` mode, after calling to conan create the information in the `scm`
dictionary is evaluated and written in the *conanfile.py* that is stored in package. That
can be problematic when you want to get the credentials from the environment because the environment
variable you are trying to get will be evaluated and stored in the packaged *conanfile.py* as well.
Let's see an example:


{% highlight python %}
...
class LibA(ConanFile):
    ...
    scm = {"type": "git",
           "url": "auto",
           "revision": "auto",
           # imagine that this environment variable exists 
           # and its value is "this_is_my_secret_password"
           "password": os.environ.get("MYPASS", None),
           # MYUSER is my_user
           "username": os.environ.get("MYUSER", None)} 
    ...
{% endhighlight %}

Now, if you do a conan create . on this recipe and go to the package folder in the local cache you
will see that the *conanfile.py* stored there looks similar to this:

{% highlight python %}
...
class LibA(ConanFile):
    ...
    scm = {"password": "this_is_my_secret_password",
           "username": "my_user",
           "revision": "3e5f02d6a557253sdas34fdee86b776cf70130c",
           "type": "git",
           "url": "https://github.com/somerepo/libA.git"}
    ...
{% endhighlight %}

As you can see the password and username are stored in the *conanfile.py* file that is going to be
package. Now, since Conan 1.22 there's a way of avoiding this problem using the scm_to_conandata
configuration value in the conan.conf file.

```
conan config set general.scm_to_conandata=True
```

Using `scm_to_conandata` feature, after doing conan create command, if you inspect the local cache
export folder you will see that the scm dictonary has not been evaluated (it is identical to the one
in your scm repository) and that there's a *conandata.yml* next to the *conanfile.py* file. If you
inspect that file, you will see something similar to this:

{% highlight yaml %}
.conan:
  scm:
    revision: 3e5f02d6a557253sdas34fdee86b776cf70130c
    type: git
    url: https://github.com/somerepo/libA.git
{% endhighlight %}

If you already had a *conandata.yml* for your recipe this fields should have been added to your file in
the local cache.

As you can see, now the scm dictionary is evaluated and stored in the *conandata.yml* file **with the
exception** of `username` and `password` fields so that you can inject the credentials from the
environment but without storing those credentials in the package.

## Using symbolic names with imports

Now imports can use *symbolic* names that are preceded with @, like `@bindirs`, `@libdirs`, etc. This
is useful if you have variable package layouts. For example if you define a custom layout in
`package_info()`.

{% highlight python %}
    def package_info(self):
        ...
        self.cpp_info.bindirs.append("mybin")
        ...
{% endhighlight %}

Now, the files can be imported using the symbolic name `@bindirs`:

{% highlight python %}
def imports(self):
    ...
    self.copy("*", src="@bindirs", dst="bin")
    ...
{% endhighlight %}

This feature can also be used if you are using the package in editable mode and `[bindirs]` was
defined.

## Add extra user-defined properties using MSBuild build helper

Using the new `user_property_file_name` parameter you can pass a list of filenames of user properties
to the [`build`](https://docs.conan.io/en/latest/reference/build_helpers/visual_studio.html#build)
method that will have priority over the `conan_build.props` file (values from these file will
override that file values).

## Python 2 deprecation

**Python 2 has been deprecated** on January 1st, 2020 by the Python maintainers and Conan project
starting in Conan 1.22, will not support Python 2 any more. If you are still using Python 2, please
update as soon as possible.

<br>

-----------

<br>

Have a look at the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html).

Please, report any bug or share your feedback opening a new issue in our [issue
tracker](https://github.com/conan-io/conan/issues) and don't forget to
[update](https://conan.io/downloads.html).