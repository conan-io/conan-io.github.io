---
layout: post
comments: true
# other options
---

<img src="{{ site.url }}/assets/conan_cargo.png" />


Well, sorry if you expected to find some picture of conan the barbarian doing dirty things...
But we are going to see great things about Rust, Cargo and Conan C/C++ package manager, and how they can work together to ease the creation of better Rust code with embedded C code. 

<h2 class="section-heading">Rust packages, Always repeatable?</h2>

Extracted from their website:

   *<<Cargo is a tool that allows Rust projects to declare their various dependencies and ensure that you’ll always get a repeatable build.>>*

But when you are talking about C library dependencies and cross platform support... 
you may need some help with the "always repeteable" thing and keeping it clean.


The Cargo <a href="http://doc.crates.io/build-script.html">solution</a> to integrate C code is:
 
 *<<allowing a package to specify a script (written in Rust) to run before invoking rustc. Rust is leveraged to implement platform-specific configuration and refactor out common build functionality among packages.>>*

And we really think that is a good approach, but also a big problem if we want to keep our Rust code cross platform.

<h2 class="section-heading">Conan to the rescue!</h2>

Cargo just need to know the following information for the C libraries:

- Which are the libraries we need to link with.
- Where are those libraries.
- Where are the headers of those libraries.

Cargo requires that the build script outputs the assignment of some variables to the appropiate values for the C libraries you want to build, something like this:

{% highlight bash %}

fn main() {
    println!("cargo:rustc-link-search=native=/path/to/my/lib");
    println!("cargo:rustc-link-lib=mylibname");
    println!("cargo:include=/path/to/my/lib/headers");
}

{% endhighlight %}

So the issue is how retrieve to your computer the required C library, build the binary if needed, and automatically get the include directories, library name and library directories, in a cross-platform way. Conan package manager can do this tasks, and it knows well where are all those paths and libraries, and their link order (very important if you have transitive dependencies)

Moreover the file's format needed by Cargo is very simple, so it can be easily automated with a conan generator. A conan generator produces an output file that can be consumed by a certain tool. For example conan already has build-in file generators for cmake, visual studio, xcode...etc. 

With the recently introduced generator packages, we can create and require a generator in the same way we require a conan package. So we can write our conanfile.txt file with the required dependencies and the cargo generator:

**conanfile.txt**:

{% highlight conf %}

[requires]
ConanCargoWrapper/0.1@lasote/testing
OpenSSL/1.0.2h@lasote/stable

[generators]
ConanCargoWrapper

{% endhighlight %}

and execute conan install:


{% highlight bash %}

 $ conan install 

{% endhighlight %}

Conan has automatically generated a **conan_cargo_build.rs** file . 
This file should be ignored in git (or any other vcs), as it will be regenerated with "conan install" command in every clean project.

Edit your **Cargo.toml** file and specify the build script:

{% highlight rust %}

    [package]
	name = "mypackage"
	version = "0.1.0"
	build = "conan_cargo_build.rs"
	
{% endhighlight %}



Now build your Cargo project:

{% highlight bash %}

 $ cargo clean
 $ cargo build

{% endhighlight %}


Need to add a new C or C++(with C API) dependency? Add it to conanfile.txt and execute *conan install*

Now yes, we can say that Rust packages cargo builds (using C/C++ code too) are Always repeatable.


You can find the conan-cargo generator and it's documentation <a href="https://github.com/lasote/conan-cargo-wrapper-generator">here</a>.

You can see the <a href="https://github.com/imazen/imageflow">**Imageflow**</a> project as a complete example of creating a C library's <a href="https://github.com/imazen/imageflow/tree/master/wrappers/server">Rust wrapper</a>.


