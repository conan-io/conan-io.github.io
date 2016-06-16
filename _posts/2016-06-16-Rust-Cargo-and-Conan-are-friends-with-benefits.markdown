---
layout: post
comments: true
# other options
---

Well, Sorry if you expected to find some picture with conan the barbarian making dirty things...
But we are going to see great things about Rust language, Cargo and Conan C/C++ package manager, and how they can work 
together to ease the creation of better Rust code with embedded C code. 

<h2 class="section-heading">Rust packages, Always repeatable?</h2>

Extracted from his website:

   *<<Cargo is a tool that allows Rust projects to declare their various dependencies and ensure that you’ll always get a repeatable build.>>*

But when you are talking about C library dependencies and cross platform support... 
you may need some help with the "always repeteable" thing and keeping the things clean.


The Cargo <a href="http://doc.crates.io/build-script.html">solution</a> to integrate C code is:
 
 *<<allowing a package to specify a script (written in Rust) to run before invoking rustc. Rust is leveraged to implement platform-specific configuration and refactor out common build functionality among packages.>>*

And we really think that is a good approach, but also a big problem if we want to keep our library cross platform.

<h2 class="section-heading">Conan to the rescue!</h2>

Cargo just need to know very common things in the C world:

- Which are the libraries we need to link with.
- Where are those libraries.
- Where are the headers of those libraries.

You can use a custom build Rust script that prints those paths to the output:


{% highlight bash %}

  
fn main() {
    println!("cargo:rustc-link-search=native=/path/to/my/lib");
    println!("cargo:rustc-link-lib=mylibname");
    println!("cargo:include=/path/to/my/lib/headers");
}


{% endhighlight %}


Well, conan knows well where are all those paths and libraries, and the link order (very important if you have recursive dependencies)

Moreover the file's format needed by Cargo is too simple, conan already have file generators for cmake, visual studio, xcode...etc
and recently added support to dynamic generators.

With dynamic generators we can require a generator in the same way we require a conan package, 
so we can write our conanfile.txt file with the required dependencies and the cargo generator:

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


Conan has been generated a **conan_cargo_build.rs** file automatically. 
This file should be ignored in git (or any other vcs), and should be regenerated with "conan install" command in every clean project.

Edit your **Cargo.toml** file and specify the build script:

{% highlight rust %}

    [package]
	name = "mypackage"
	version = "0.1.0"
	build = "conan_cargo_build.rs"
	
{% endhighlight %}



Now build your Cargo package:

{% highlight bash %}

 $ cargo clean
 $ cargo build
	
{% endhighlight %}


Need to add a new C dependency? Add it to conanfile.txt and execute *conan install*

Now yes, we can say that Rust packages (with C code) are Always repeatable.


You can find the conan-cargo generator and it's documentation <a href="https://github.com/lasote/conan-cargo-wrapper-generator">here</a>.


