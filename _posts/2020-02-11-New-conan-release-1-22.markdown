---
layout: post
comments: false
title: "Conan 1.22: New downloads cache, store scm data in conandata.yml, Python 2 deprecation and
more."
---

2020 has started with lots of new features and bugfixes in Conan 1.22. Let's check some of the most
important ones.

## New downloads cache

With each new Conan release, we are trying to help to speed-up the CI's step by step. The last one
was in Conan 1.21, where we introduced the [parallel
uploads](https://docs.conan.io/en/latest/reference/commands/creator/upload.html?highlight=parallel#conan-upload)
that can get and **increase in speed for around 400%**. 

Now we are releasing a new download cache that can be concurrently used by several Conan instances
using different `CONAN_USER_HOME` folders. This cache could be shared between different simultaneous
CI jobs, so if the files were previously downloaded, they could be reused from the cache without the
need to download them again.

If you want to test this feature you have to set the appropriate configuration in the *conan.conf* file.

```
$ conan config set storage.download_cache="/path/to/my/cache"
```

You could test the performance improvement of the feature by subsequently changing the
`CONAN_USER_HOME` for different Conan calls that install a big package but setting the same
downloads cache for all of them.

```
$ export CONAN_USER_HOME=/Users/yourusername/conan_home_1/
$ conan config set storage.download_cache="/Users/yourusername/central_cache"
$ time conan install boost/1.72.0@
...
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', ...
boost/1.72.0: Package folder: /Users/yourusername/conan_home_1/.conan/data/boost/1.72.0/_/_/package/69168f775732984eb37d785004b6ef25111fe5f9
conan install boost/1.72.0@  4.70s user 3.87s system 36% cpu 23.428 total
...
$ export CONAN_USER_HOME=/Users/yourusername/conan_home_2/
$ conan config set storage.download_cache="/Users/yourusername/central_cache"
$ time conan install boost/1.72.0@
...
boost/1.72.0: LIBRARIES: ['boost_wave', 'boost_container', 'boost_contract', ...
boost/1.72.0: Package folder: /Users/yourusername/conan_home_2/.conan/data/boost/1.72.0/_/_/package/69168f775732984eb37d785004b6ef25111fe5f9
conan install boost/1.72.0@  4.03s user 3.38s system 51% cpu 14.491 total
...
```

As you can see in the command line output, the first time, with an empty cache the download takes
**23.428 seconds**, that is the same time that it would have taken to download if there was no cache.
After setting the second `CONAN_USER_HOME` with the downloads cache pointing to the same folder the
download time is **14.491 seconds** which is almost half of the time it would take without the
downloads cache.

If you want to deactivate the cache, don't forget to do:

```
$ conan config rm storage.download_cache
```

An then removing the contents of the cache folder. Also, if you changed the `CONAN_USER_HOME`,
restore it to the original value.

## Easier credential handling when using SCM

When using `scm` and `auto` mode, after calling to `conan create` the information in the `scm`
dictionary is evaluated and written in the *conanfile.py* that is stored in the package. That
can be problematic when you want to get the credentials from the environment, because the environment
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

Now, if you do a `conan create .` on this recipe and go to the package folder in the local cache you
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

The `password` and `username` values are stored in the *conanfile.py* file packaged.

Now, since Conan 1.22 there's a way of avoiding this problem using the `scm_to_conandata`
configuration value in the *conan.conf* file.

```
conan config set general.scm_to_conandata=True
```

With `scm_to_conandata` enabled, after creating the package, if you inspect the local cache export
folder you will see that the scm dictionary has not been evaluated (it is identical to the one in
your scm repository) and that there's a *conandata.yml* next to the *conanfile.py* file. If you
inspect that file, you will see something similar to this:

{% highlight yaml %}
.conan:
  scm:
    revision: 3e5f02d6a557253sdas34fdee86b776cf70130c
    type: git
    url: https://github.com/somerepo/libA.git
{% endhighlight %}

If you have a *conandata.yml* for your recipe, these fields are added to your file when packaged.

As you can see, now the `scm` dictionary is evaluated and stored in the *conandata.yml* file **except
for** `username` and `password` fields so that you can inject the credentials from the environment
but without storing those credentials in the package.

## Using symbolic names with imports

Now imports can use *symbolic* names that are preceded with @, like `@bindirs`, `@libdirs`, etc. This
is useful if you have variable package layouts. For example, if you define a custom layout in
`package_info()`:

{% highlight python %}
    def package_info(self):
        ...
        self.cpp_info.bindirs.append("mybin")
        ...
{% endhighlight %}

The files in that folder can be imported using the symbolic name `@bindirs`:

{% highlight python %}
def imports(self):
    ...
    self.copy("*", src="@bindirs", dst="bin")
    ...
{% endhighlight %}

This feature can also be used if you are using the package in editable mode and `[bindirs]` was
defined.

## Add extra user-defined properties using MSBuild build helper

Using the new `user_property_file_name` parameter you can pass a list of filenames with user properties
to the [`build`](https://docs.conan.io/en/latest/reference/build_helpers/visual_studio.html#build)
method that will have priority over the `conan_build.props` file (values from these files will
override that file values).

## Python 2 deprecation

On January 1st, **Python 2 was deprecated** by the Python maintainers so Conan will not support Python 2 anymore starting from the 1.22 version.

If you are still using Python 2, please update as soon as possible.

<br>

-----------

<br>

Have a look at the full list of features and fixes in the
[changelog](https://docs.conan.io/en/latest/changelog.html).

Please, report any bug or share your feedback opening a new issue in our [issue
tracker](https://github.com/conan-io/conan/issues) and don't forget to
[update](https://conan.io/downloads.html).