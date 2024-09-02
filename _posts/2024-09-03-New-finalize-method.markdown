---
layout: post
comments: false
title: "Introducing finalize() method: Customizing packages locally"
meta_title: "Introducing finalize() method: Customizing packages locally"
description: "New conan finalize() method which allows preserving immutability and local configurations of packages"
keywords: "finalize,local configuration,pycache,pyc,cache integrity"
---


We’re excited to unveil the new ``finalize()`` method in Conan, a way of allowing users to customize packages locally while preserving their immutability
in the Conan cache. This feature is crucial for scenarios where modifications
are required on the local machine, such as generating configuration files or
managing execution-generated files like Python’s *pycache*.

## Why ``finalize()`` matters?

Package immutability is a key principle in Conan, ensuring consistency and
reliability across various environments. The ``finalize()`` method respects this
principle while enabling local adjustments, maintaining the integrity of the
original package stored in the Conan cache.

Common use cases for ``finalize()`` include:

- **Ensuring cache integrity**: Handling files generated during package execution (e.g., *pycache*) in a way that doesn't alter the original package.
- **Local modifications**: Creating or adjusting configuration files necessary for the package to function correctly on the local machine which can’t be achieved at package creation time.


### How ``finalize()`` Works

The ``finalize()`` method is invoked after a package is installed in the local
cache but before it is used by consumers. This allows you to implement logic to
locally copy or generate files without affecting the original package. For
instance:

```py
from conan import ConanFile
from conan.tools.files import copy
import os

class Package(ConanFile):
    def package(self):
        copy(self, "*", src=self.source_folder, dst=os.path.join(self.package_folder, "bin"))

    def finalize(self):
        copy(self, "*", src=self.immutable_package_folder, dst=self.package_folder)
```

In this example we introduce a new class attribute, ``immutable_package_folder``.
This attribute will always point to the ``self.package_folder`` that is used in the ``package()`` method.

When a package which declares a ``finalize()`` method is consumed, the
``package_folder`` of that package will no longer point to the previous path, but
a new path which follows this structure in the cache
“\<conan\_cache\>/p/b/\<build\_id\>/f”. This folder will not be tracked for
integrity so any alteration on this path will be transparent for conan.

This is why in the ``finalize()`` method we must ensure all the needed files
installed in the ``immutable_package_folder`` are also **copied** or **symlinked**
to the new ``package_folder``.  
And that is what the example is doing in the last line.

> **Note**: finalize method will only run once per *package\_id*. This means that, if the package is used multiple times, the ``finalize()`` method will only run the first time, so different consumers will use the same *final folder*.

> **Warning**: packages can’t change its "binary" compatibility or footprint in any way. Otherwise, other packages consuming this one will not work when uploaded and reused, because they will depend on a binary that is not uploaded. This feature is intended for customizations of runtime or build utilities to correctly consume the package, build against it and use it at run time.

> **Warning**: symlinking in Conan recipes is a non recommended practice due to its bad portability, specially to Windows ecosystem.
Even though, in special and controlled cases, symlinking could be useful to avoid great sized libraries duplication. Users under their own risk!

### Examples

#### Meson cache integrity

Traditionally, maintaining cache integrity during package uploads, especially
for tools like *Meson*, required disabling Python bytecode generation to
prevent cache corruption. However, using ``finalize()``, you can keep Python’s
caching efficiency intact while ensuring that cache integrity is preserved.
Let’s see in deep detail with a typical workflow:

1. A package is installed
2. The package is tested locally in order to verify the changes are correct. During this step, files could be generated in the Conan local cache package folder. In the case of “Meson”, ``.pyc``  
3. Upload the modified package to a remote. Conan will perform an integrity check on the local cache before uploading the package when called with the ``-–check`` argument. This would historically fail because the cache is now “dirty”. Those ``.pyc`` files have been created automatically in the ``package_folder`` and Conan caught the mismatch.

This is a simplified version of the current *Meson* package method, where Python bytecode generation has been disabled:

```py
def package(self):
    # Create wrapper functions
    save(self, os.path.join(self.package_folder, "bin", "meson"), textwrap.dedent("""\
        #!/usr/bin/env bash
        meson_dir=$(dirname "$0")
        export PYTHONDONTWRITEBYTECODE=1
        exec "$meson_dir/meson.py" "$@"
    """))
```

This was a valid solution in order to ensure cache integrity inside the conan
cache. Remember that this problem did not only affect *Meson* maintainers but
every user who has used the *Meson* build system as a dependency. Without this
tweak, performing a quick ``conan cache check-integrity "meson"`` will fail.

But this still was not a perfect solution as it threw all python caching
efficiency out of the window. This is one of the main reasons for implementing
the ``finalize()`` method. Let’s see how could we modify *Meson* package in order
to keep python’s cache efficiency and cache integrity intact:

&nbsp;1. First we could get rid of the ``PYTHONDONTWRITEBYTECODE`` environment variable because we want python to generate ``.pyc`` files:

```py
def package(self):
    # Create wrapper functions
    save(self, os.path.join(self.package_folder, "bin", "meson"), textwrap.dedent("""\
        #!/usr/bin/env bash
        meson_dir=$(dirname "$0")
        exec "$meson_dir/meson.py" "$@"
    """))
```

&nbsp;2. We need to create a ``finalize()`` method which will copy all contents of the ``immutable_package_folder`` to the final and isolated ``package_folder``

```py
def finalize(self):
    copy(self, "*", src=self.immutable_package_folder, dst=self.package_folder)
```

As explained above, in the context of the ``finalize()`` method until the consumer, ``self.package_folder`` will now aim to the *final folder*.

This way, making use of this new method, we can completely isolate *Meson*
application, being sure now that the cache integrity will be kept intact.

#### Custom configuration files within package scope

The ``finalize()`` method is also beneficial for packages that need to generate
custom configuration files locally. For example, a package can use ``finalize()``
to create a ``whoami.txt`` file containing the current user’s name, ensuring this
file is present without altering the original package.

Let’s use a very simplified example located at [examples2 repository](https://github.com/conan-io/examples2)

&nbsp;1. Clone the ``example2`` repository:

```
$ git clone git@github.com:conan-io/example2
$ cd examples2/examples/conanfile/finalize/finalize_method
```

&nbsp;2. In ``src/main.cpp`` we have a basic program that reads a file called ``whoami.txt`` and prints the content to the standard output

```c++
std::ifstream in("whoami.txt", std::ios_base::in);
std::cout << in.rdbuf() << '\n';
```

&nbsp;3. In the ``conanfile.py`` we can highlight the ``finalize()`` method:

```py
def finalize(self):
    copy(self, "*", src=self.immutable_package_folder, dst=self.package_folder)
    save(self, os.path.join(self.package_folder, "bin", "whoami.txt"), getpass.getuser())
```

- As we can see, the first line will copy all content of the ``immutable_package_folder`` (the executable itself) to the *final folder* (remember, the path with this pattern in the cache “\<conan\_cache\>/p/b/\<build\_id\>/f”).  
- But we are also creating a file called ``whoami.txt`` with the result of invoking ``getpass.getuser()`` value, which is the pythonic way of getting the current user. Note that this would not be possible to do until now in the ``package`` method as we want the ``whoami`` results of the running machine, not the packaging one.

&nbsp;4. Create the package and observe the traces:

```sh
$ conan create .
...
whoisconan/1.0: Calling package()
...
whoisconan/1.0: Package folder /Users/conan/.conan2/p/b/whoisf8485f8a03c9b/p
whoisconan/1.0: Calling finalize()
whoisconan/1.0: Finalized folder /Users/conan/.conan2/p/b/whoisf8485f8a03c9b/f
```

As we can see, after the ``package()`` method is invoked, the ``finalize()`` method will be run, copying the contents of the ``/p`` folder to ``/f`` folder.

&nbsp;5. Go to finalized folder path

```sh
$ cd /Users/conan/.conan2/p/b/whoisf8485f8a03c9b/f/bin
```

&nbsp;6. Run the application and observe the result

```sh
$ ./whoisconan
conan
```

As we can see, the executable will perform a basic ``cat`` of the content of ``whoami.txt`` file located next to the executable.

This example shows how the ``finalize()`` method allows the package to
customize files according to the local environment, or any kind of
modifications while keeping the Conan cache pristine and without altering the
``package_id``.

### Accessing folders of packages which has the ``finalize()`` method

The main idea of the ``finalize()`` method is not to influence at all on the consumers of the package, meaning it would be fully transparent to the end user. 

When a consumer accesses its ``package_folder`` dependency, it will work as always. This folder will contain the contents needed to work but also ensure that any local changes do not impact the immutable package stored in the cache. 

Let’s dive into an example of accessing the folders of a package which has a ``finalize()`` method in it.

&nbsp;1. To simplify things, let’s use the ``finalize_consume`` example in example2 repository:

```sh
$ git clone git@github.com:conan-io/example2
$ cd examples2/examples/conanfile/finalize/finalize_consume
```

This folder contains two packages, the dependency one which has a finalize method and the consumer which will just print the content of the dependency folders.

&nbsp;2. Create dependency package

```sh
$ conan create dependency
...
dependency/1.0: Calling package()
dependency/1.0: package(): Packaged 2 '.txt' files: file2.txt, file1.txt
...
dependency/1.0: Package folder /Users/conan/.conan2/p/b/depen856e3d9c06c1f/p
dependency/1.0: Calling finalize()
dependency/1.0: Running finalize method in /Users/conan/.conan2/p/b/depen856e3d9c06c1f/f
dependency/1.0: Finalized folder /Users/conan/.conan2/p/b/depen856e3d9c06c1f/f
dependency/1.0: Running package_info method in /Users/conan/.conan2/p/b/depen856e3d9c06c1f/f
```

Two files (``file1.txt`` and ``file2.txt``) were packaged in the original ``package_folder`` (``.conan2/p/b/depen856e3d9c06c1f/p``)   
We can also see that in the ``package_info`` method context, the ``package_folder`` points to the *final folder* (``.conan2/p/b/depen856e3d9c06c1f/f``). This is going to be from now on until the consumer consumes this package, the real path when accessing the ``package_folder``.

&nbsp;3. Create the consumer package:

```sh
$ conan create consumer
...
consumer/1.0: Calling generate()
...
consumer/1.0: Running generate method
consumer/1.0: Dependency package_folder: /Users/conan/.conan2/p/b/depen856e3d9c06c1f/f
consumer/1.0: Content in dependency package_folder:
['file1.txt']
consumer/1.0: Dependency immutable_package_folder: /Users/conan/.conan2/p/b/depen856e3d9c06c1f/p
consumer/1.0: Content in dependency immutable_package_folder:
['file2.txt', 'file1.txt', 'conanmanifest.txt', 'conaninfo.txt']
...
consumer/1.0: Generating the package
consumer/1.0: Packaging in folder /Users/conan/.conan2/p/b/consuea78f76f2c500/p
```

As described above, when a consumer access a dependency ``package_folder`` 

```py
self.dependencies["dependency"].package_folder
```

The obtained path will be the *final folder* and not the typical ``/p`` path (the immutable one).  
We can also appreciate that the content of the ``package_folder`` just contains what we explicitly have copied in the ``finalize`` method on the ``dependency`` package.

> **Note**: in most of the cases, consumers will never need to access ``immutable_package_folder``. 

> **Note**: as soon as a ConanFile has defined the ``finalize`` method, no matter if the method is empty, the resulting ``package_folder`` will point to the *final folder* (the one ended with ``/f``)

#### Why ``immutable_package_folder``?

As the original ``package_folder`` get’s overridden by the *final folder*, without any other property, there could be no way to access the original package folder for a dependency or even inside ``package_info``. 

This feature has been created with the idea of never needing to access the original ``package_folder``. Consumers should never need to know which folder (the ended with ``/p`` or the ended with ``/f``) a dependency is using. This will always be transparent for the consumers.

But there might be a reason for creating this extra and new attribute, vendoring.

Remember the [last post](https://blog.conan.io/2024/07/09/Introducing-vendoring-packages.html) where we talked about the new “vendoring feature”. We explained that the user who wants to vendor a package is fully responsible for correctly encapsulating the needed components of their dependencies inside the vendored package.  
There might be some reasons in which, when vendoring, we may want to check if a dependency has a ``finalize`` method. This assertion could be easily achieved by comparing ``dependency.immutable_package_folder == dependency.package_folder``. If they are not the same, it means that the dependency.package\_folder is an isolated one and not the original one.   
In that case, users could decide to vendor the contents not from the ``package_folder`` but from ``immutable_package_folder``, or both...

### Conclusion

The ``finalize()`` method is a great enhancement in Conan, offering a flexible
way to manage local customizations while ensuring the original package’s
immutability. Whether you need to handle execution-generated files or create
custom configurations, ``finalize()`` provides a robust solution that preserves
both performance and cache integrity. This method is a powerful addition to
Conan’s toolset, enabling developers to tailor packages to their local
environment without compromising the consistency that is critical for reliable
package management.

Stay tuned for more updates and, as always, happy packaging with Conan!
