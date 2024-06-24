---
layout: post
comments: false
title: "Introducing vendoring packages: Create and share packages decoupled from their dependencies"
meta_title: "(optional) A longer more descriptive title for search engines to index"
description: "A short summary of the post that will be displayed in the search engine results"
keywords: "repackage,repackaging,conan repackage,package_id"
---


We’re excited to roll out a highly anticipated feature that will significantly
enhance how Conan users, including software vendors, manage and distribute
their packages: the "vendor" feature. This new addition aims to streamline the
deployment and sharing process of Conan packages, offering greater control over
internal recipes and binaries **without exposing proprietary details**, or simply
isolating implementation details across organization teams. Let’s dive into
what "vendor" packages bring to the table and how they can benefit your
workflow.

## What is a "vendored package"?

The "vendor" feature allows developers to distribute their software through
Conan while keeping internal dependencies and recipes private. By enabling the
vendor attribute in your Conan recipe, you can prevent Conan from downloading
the recipes and binaries of your package's dependencies. This means you can
encapsulate all necessary binaries and libraries within your package, ensuring
that end-users have no access to your internal build details or private
repositories.

## Key Benefits

1. **Enhanced Privacy and Security**

    By using the vendor feature, you can share your software packages without
    exposing the recipes and binaries of your internal dependencies. This is
    crucial for maintaining the confidentiality of proprietary code and internal
    build processes.


2. **Streamlined Distribution**

    - The vendor feature simplifies the distribution process. Whether you’re using
    Conan Center Index or a private artifact repository, pre-built binaries for
    various configurations can be included, ensuring that end-users receive a
    ready-to-use package without the need for additional downloads
    - Vendoring can also be useful inside organizations by allowing sharing
    - SDKs between different work groups without sharing internals
    
3. **Reduced Build Times**

    When a consumer installs a vendored recipe, Conan won’t download individual
    dependency binaries or recipes from the server, potentially saving significant
    time and storage space, especially in production environments.

## Usage example

For this example, make sure to at least have Conan v2.4.1 installed available.

1. Create a basic library from the CMake template

    ```sh
    $ mkdir vendor-example && cd vendor-example
    $ mkdir lib_a && cd lib_a
    $ conan new cmake_lib -d name=lib_a -d version=1.0
    $ conan create .
    ```

2. Create a package depending on the previous library, which will be the one we’ll use to vendor its dependencies

    ```sh
    $ cd .. && mkdir sdk && cd sdk
    $ conan new cmake_lib -d name=sdk -d version=1.0 -d requires="lib_a/1.0"
    $ conan create .
    ```

3. Create a consumer application depending on the sdk library:

    ```sh
    $ cd .. && mkdir app && cd app
    $ conan new cmake_exe -d name=app -d version=1.0 -d requires="sdk/1.0" 
    ```

4. Install the created application 

    ```sh
    $ conan install . --build=missing

    ======== Computing dependency graph ========
    ...
    Requirements
        lib_a/1.0#ab64452c42599a3dc0ee6a0dc90bbd90 - Cache
        sdk/1.0#1cb781c232f63845b7943764d8a084ed - Cache

    ======== Computing necessary packages ========
    Requirements
        lib_a/1.0#ab64452c42599a3dc0ee6a0dc90bbd90:39f48664f195e0847f59889d8a4cdfc6bca84bf1#e34a89988cafb2bf67f6adf40b06f442 - Cache
        sdk/1.0#1cb781c232f63845b7943764d8a084ed:12ffb661ea06cee312194b5f6acd48e8236b8ed8#9127cf762dfd1a1f505ecd1d3ac056b9 - Cache
    ```

    Transitive dependencies are required as expected.


5. Generate the graph to see a later comparison

    ```sh
    $ conan graph info . --format=html > graph.html
    ```

6. Now let's dive into the vendoring feature. Some changes need to be made in the SDK ``conanfile.py``:
    - As this example aims to make a vendored **static library**, we should first change the ``package_type`` accordingly
    - Set the class attribute ``vendor`` to ``True``. This will enable the vendoring feature
    - Remove the unnecessary shared option from options and default_options, and remove configure method because it not needed anymore
    - Actually repackage the lib_a library inside the SDK. As we are generating a static library, we can achieve this by copying the ``liblib_a.a`` static library inside the SDK library
    - Finally, update the ``cpp_info.libs`` adding the ``lib_a`` dependency for consumers

    ```py
    from conan import ConanFile
    from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
    from conan.tools.files import copy
    import os


    class sdkRecipe(ConanFile):
        name = "sdk"
        version = "1.0"
        package_type = "static-library"
        vendor = True

        # <span class="hll">vendor = True</span>

        # Optional metadata
        license = "<Put the package license here>"
        author = "<Put your name here> <And your email here>"
        url = "<Package recipe repository url here, for issues about the package>"
        description = "<Description of sdk package here>"
        topics = ("<Put some tag here>", "<here>", "<and here>")

        # Binary configuration
        settings = "os", "compiler", "build_type", "arch"
        options = {"fPIC": [True, False]}
        default_options = {"fPIC": True}

        # Sources are located in the same place as this recipe, copy them to the recipe
        exports_sources = "CMakeLists.txt", "src/*", "include/*"

        def config_options(self):
            if self.settings.os == "Windows":
                self.options.rm_safe("fPIC")

        def layout(self):
            cmake_layout(self)

        def requirements(self):
            self.requires("lib_a/1.0")

        def generate(self):
            deps = CMakeDeps(self)
            deps.generate()
            tc = CMakeToolchain(self)
            tc.generate()

        def build(self):
            cmake = CMake(self)
            cmake.configure()
            cmake.build()

        def package(self):
            # Repackage static dependencies inside the package
            copy(self, "*.a", src=self.dependencies["lib_a"].cpp_info.libdir, dst=os.path.join(self.package_folder, self.cpp_info.libdir))
            cmake = CMake(self)
            cmake.install()

        def package_info(self):
            self.cpp_info.libs = ["sdk", "lib_a"]

    ```

7. Apply the changes and create the SDK package:

    ```sh
    $ cd ../sdk
    $ conan create .
    ```

8. Finally, let’s reinstall the application again.

    ```sh
    $ cd ../app 
    $ conan install . --build=missing

    ======== Computing dependency graph ========
    Graph root
    ...
    Requirements
        sdk/1.0#f2fd2a793849725303073d37b15042b2 - Cache

    ======== Computing necessary packages ========
    Requirements
        sdk/1.0#f2fd2a793849725303073d37b15042b2:5d605f63db975c8c6004cc0a0b5c99c99dce6cc3#92c538ec767c2ff02a2fddf6b4106d02 - Cache
    ```

    As it can be seen, while computing the dependency graph, conan does not
    retrieve either the recipe of ``lib_a/1.0`` nor the binaries. 

9. We could try to even remove ``lib_a`` from our local cache and install again the application:

    ```sh
    $ conan remove "lib_a*" -c
    Found 1 pkg/version recipes matching lib_a* in local cache
    Remove summary:
    Local Cache
      lib_a/1.0#ab64452c42599a3dc0ee6a0dc90bbd90: Removed recipe and all binaries
    ```

    ```sh
    $ conan install .
    ...
    Requirements
        sdk/1.0#f2fd2a793849725303073d37b15042b2 - Cache
    ...
    Install finished successfully
    ```

    It works!!! Here is where vendoring feature shines. Package creators can
    distribute their packages without needing to distribute their private
    dependencies.


10. Generate graph info of the application using vendored SDK

    ```sh
    $ conan graph info . --format=html > vendored-graph.html 
    ```

    Comparison between graphs:

    <div class="centered" style="display: flex; justify-content: center; margin-bottom: 1rem;">
        <div style="display: flex; flex-direction: column; align-items: center; margin: 0 10px;">
            <img src="{{ site.baseurl }}/assets/post_images/2024-06-24/standard-sdk-graph.png" alt="Standard sdk graph" style="width: 50%;" />
            <span>Standard sdk graph</span>
        </div>
        <div style="display: flex; flex-direction: column; align-items: center; margin: 0 10px;">
            <img src="{{ site.baseurl }}/assets/post_images/2024-06-24/vendored-sdk-graph.png" alt="Vendored sdk graph" style="width: 50%;" />
            <span>Vendored sdk graph</span>
        </div>
    </div>
    <br/>

    **Note**: Red dashed borders mean the package is vendoring its dependencies

## How should the “vendor” feature be used?

For releasing a vendored package, the creator should follow these steps:

1. **Encapsulation of dependencies**

    Ensure that all dependencies are correctly repackaged inside the vendoring
    package. This involves encapsulating binaries, static libraries, and shared
    libraries within the vendoring domain. Users may use the vendoring package with
    different kinds of environments, dependencies, shared libraries enabled, etc.
    The package creator is responsible for ensuring no conflicts should surface.

2. **Distribution of vendoring packages**

    When distributing a vendoring package, pre-built binaries should be generated
    for the different configurations your consumers might need. That way, users
    could use the vendored package without needing to compile it from scratch and
    without the need to have direct access to the package dependencies (which may
    be private for the organization)


## Advanced details

### Dependency graph and its importance

To understand the inner workings of the "vendor" feature, it is essential to
grasp the concept of a dependency graph in Conan. When Conan builds the
dependency graph for a package, it downloads the recipes and binaries for all
dependencies, constructing a detailed map of all relationships and
configurations involved.

The dependency graph is a critical component in Conan, representing how
packages depend on each other. It ensures that all necessary binaries and
libraries are correctly resolved and compatible. Typically, Conan expands this
graph fully, downloading all the recipes and binaries involved. However, with
the vendor feature enabled, you can limit this expansion.

### Limiting Graph Expansion

By enabling the vendor option, the consumer of the recipe is instructed not to
expand the dependency graph beyond the vendored package. This means Conan won't
download the recipes or binaries of internal dependencies, keeping the build
process lean and secure. This feature is particularly useful for:

- **Encapsulation**: Keeping private dependencies hidden and secure.
- **Efficiency**: Reducing download and build times by not fetching unnecessary components.
- **Control**: Allowing software vendors to manage how their packages are used and distributed without exposing internal details.

### Forcing the build of a vendoring package

We have seen how a vendor can be used from a consumer directly downloading
binaries without needing to download any dependency data.

But what happens if we want to compile the internal vendored dependencies?

1. As we have previously deleted ``lib_a`` package, we should re create it:

    ```sh 
    $ cd ../lib_a && conan create .
    ```
    Now, let’s force the build of our previous SDK example:

    ```sh
    $ cd ../app
    $ conan install . --build="sdk/1.0"
    ...
    ======== Computing necessary packages ========
    sdk/1.0: Forced build from source
    Requirements
        sdk/1.0#f2fd2a793849725303073d37b15042b2:5d605f63db975c8c6004cc0a0b5c99c99dce6cc3 - Invalid
    ERROR: There are invalid packages:
    sdk/1.0: Invalid: The package 'sdk/1.0' is a vendoring one, needs to be built from source, but it didn't enable 'tools.graph:vendor=build' to compute its dependencies
    ```

    Trying to build a vendor package will fail by default unless setting the ``tools.graph:vendor`` configuration to “build”.

2. Once the ``vendor`` configuration is enabled, the user must have access to packaged dependencies as if it were a normal package.

    ```sh
    $ conan install . --build="sdk/1.0" -c tools.graph:vendor=build
    ...
    ======== Computing necessary packages ========
    sdk/1.0: Forced build from source
    Requirements
        lib_a/1.0#ab64452c42599a3dc0ee6a0dc90bbd90:39f48664f195e0847f59889d8a4cdfc6bca84bf1#5a8bfa1c980c2008e7e24996a4b48477 - Cache
        sdk/1.0#f2fd2a793849725303073d37b15042b2:5d605f63db975c8c6004cc0a0b5c99c99dce6cc3 - Build

    ======== Installing packages ========
    lib_a/1.0: Already installed! (1 of 2)
    ...
    Install finished successfully
    ```

    When forcing the compilation of a vendored dependency, the graph expands again,
    revealing the encapsulated dependencies necessary for the build.

3. Let's generate the graph again to see how the expansion works:

    ```sh
    $ conan graph info . --build="sdk/1.0" -c tools.graph:vendor=build --format=html > vendored-expanded-graph.html
    ```

    <div style="display: flex; flex-direction: column; align-items: center; margin: 0 10px;">
        <img src="{{ site.baseurl }}/assets/post_images/2024-06-24/vendored-expanded-graph.png" alt="Vendored expanded graph" style="width: 25%;" />
        <span>Vendored expanded graph</span>
    </div>
    <br/>

    **Note**: Red dashed border means the package is a vendor and yellow background means the package has been forced to be built

4. To verify a vendored package does not need to have their transitive
   dependencies accessible unless forced to build, we can try to remove our ``lib_a`` package from our local cache and install again:

    ```sh
    $ conan remove "lib_a*" -c
    Found 1 pkg/version recipes matching lib_a* in local cache
    Remove summary:
    Local Cache
      lib_a/1.0#ab64452c42599a3dc0ee6a0dc90bbd90: Removed recipe and all binaries
    ```

    ```sh
    $ conan install . --build="sdk/1.0" -c tools.graph:vendor=build
    ...
    ======== Computing dependency graph ========
    lib_a/1.0: Not found in local cache, looking in remotes...
    lib_a/1.0: Checking remote: conancenter
    ...
    Requirements
        sdk/1.0#f2fd2a793849725303073d37b15042b2 - Cache
    ERROR: Package 'lib_a/1.0' not resolved: Unable to find 'lib_a/1.0' in remotes.
    ```

    As expected, an error package not resolved is thrown when forcing building the vendored package if we do not have access to its dependencies.


### Proxy vendor for Extra Privacy

For vendors that want to further obscure their dependency names and versions, a
proxy vendored package can be created. This proxy package should include all
internal/private dependencies and should be made inaccessible to clients. 

The primary vendored recipe depends on this proxy package, and by marking both
packages as vendored, the actual dependencies and their versions will be hidden
from the end-user.

### Impact on Package ID Calculation

To support the vendor feature, we’ve adjusted how the ``package_id`` is calculated
for vendored packages. Since dependencies and their versions are invisible to
the end-user, they are excluded from the ``package_id`` calculation. Only the
recipe revision will change with recipe content changes, but the ``package_id``
will remain the same. This ensures that any kind of change to internal
dependencies (updating, adding or removing) will not alter the ``package_id``,
saving time and effort in environments where consistent package IDs are
crucial.

It goes without saying that the provider in charge of packaging the package
should be in charge of updating the version of the package when any of its
internal dependencies change version in order to update the ``package_id`` and let
consumers know that the package has changed in some way.

## Conclusion

The "vendoring" feature is a powerful tool for any organization looking to
distribute software through Conan while maintaining control over internal
dependencies. By encapsulating and securing your binaries, you can ensure a
smooth and efficient distribution process, enhanced privacy, and significant
time savings. We’re thrilled to bring this feature to the community and look
forward to seeing how it enhances your workflows.

On the other side, we recommend avoiding abuse of this new feature, for
example, we do not consider that it has any place in ``conan-center-index`` or in
other remotes, except perhaps for some application type package (tool
requires).

Stay tuned for more updates and, as always, happy packaging with Conan!
