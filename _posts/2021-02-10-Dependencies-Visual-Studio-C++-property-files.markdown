---
layout: post
comments: false
title: "Managing dependencies in Visual Studio C++ projects with property files"
---

# Introduction

Dependencies in C and C++ projects are hard. Building C and C++ projects is hard, and maintaining the dependencies information inside C and C++ projects is hard.

Visual Studio C++ is the most popular IDE and compiler in Microsoft Windows platforms, massively used by C and C++ developers. It is very common that developers manually add information to the project manually in the IDE, but this method is difficult to maintain over time. Fortunately, MSBuild, the build system used by Visual Studio, allows defining external user property files (those are XML files), which makes an interesting extension point for automation and standardization of many tasks.

This post introduces the syntax of Visual Studio ``.vcxproj`` files and property files, and how they can be leveraged to define C++ dependencies to external libraries in a systematic and scalable way.


# Adding a dependency

Let’s start by manually adding an external library to one existing project. Let’s imagine that we need some compression capabilities in our project and we want to use the popular ZLib library for that purpose. A team of developers could decide that they will put all of their dependencies in “C:\TeamDeps”, and the process to add such information to our project typically involve some steps:

- Adding the include directories where headers like ``zlib.h`` can be found
- Adding the libraries that needs to be linked, like ``zlib.lib``
- Adding the library directories where these libraries can be found
- Adding possible preprocessor definitions that the library might require for proper behavior.


All these tasks can be done interactively in the IDE, going to the project view, right click and open “Properties”. For defining the include directories, it is necessary to go to the C/C++ -> Preprocessor -> Additional Include Directories:

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-02-10/vs_add_include.png"
     align="center" alt="Visual Studio C++ Additional Header Path"/>
</p>


Note that all this information is defined per configuration, in this image, the Release - x64 configuration is being changed. If we add the include directories to this configuration, and then later switch to Debug in the IDE, the build will fail not finding the ZLib headers. So it is necessary to add the include directories typically to all configurations.

In a similar way, the libraries that our application is linking can be defined in Linker -> Input -> Additional Dependencies.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-02-10/vs_add_lib.png"
     align="center" alt="Visual Studio C++ Additional Dependencies"/>
</p>

And finally, the library paths are necessary, this can be specified in Linker -> General. As the above properties, it can also be defined for multiple configurations.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-02-10/vs_add_lib_path.png"
     align="center" alt="Visual Studio C++ Additional Dependencies Path"/>
</p>


This process is very manual, but we can check how it is translated to the project files. If we check the ``.vcxproj`` file we would find something like this:

```xml
<ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <FunctionLevelLinking>true</FunctionLevelLinking>
      <IntrinsicFunctions>true</IntrinsicFunctions>
      <SDLCheck>true</SDLCheck>
      <PreprocessorDefinitions>ZLIB_STATIC;NDEBUG;_CONSOLE;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <ConformanceMode>true</ConformanceMode>
      <AdditionalIncludeDirectories>C:\TeamDeps\zlib\include;$(SolutionDir)\include;$(SolutionDir)\..\include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
    </ClCompile>
    <Link>
      <SubSystem>Console</SubSystem>
      <EnableCOMDATFolding>true</EnableCOMDATFolding>
      <OptimizeReferences>true</OptimizeReferences>
      <GenerateDebugInformation>true</GenerateDebugInformation>
      <AdditionalLibraryDirectories>C:\TeamDeps\zlib\lib;%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
      <AdditionalDependencies>zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>
    </Link>
  </ItemDefinitionGroup>
```

This is a great starting point if we want to automate the management of dependencies in MSBuild projects. Note the cumulative ``<AdditionalDependencies>zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>`` expression. This is done to respect and keep possible existing values in AdditionalDependencies, that could come defined elsewhere.

# Using MSBuild property files

Given that ``.vcxproj`` are XML files it is possible to directly add properties in it. However, property files give a very convenient way to do the same, but keeping the desired decoupling and separation of concerns in software engineering. Property files are also XML files with the ``.props`` extension that basically share the same syntax, but that can be imported from the ``.vcxproj`` and even other property files. Following the single responsibility principle, we will create separated property files dedicated exclusively to handle the dependencies information.

For the above example, we could create a ``zlib.props`` file like:

```xml
<?xml version="1.0" ?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
	<ItemDefinitionGroup>
		<ClCompile>
			<AdditionalIncludeDirectories>C:\TeamDeps\zlib\include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
			<PreprocessorDefinitions>ZLIB_STATIC;%(PreprocessorDefinitions)</PreprocessorDefinitions>
		</ClCompile>
		<Link>
			<AdditionalLibraryDirectories>C:\TeamDeps\zlib\lib;%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
			<AdditionalDependencies>zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>
		</Link>
	</ItemDefinitionGroup>
</Project>
```

And then import it in the ``.vcxproj``. This import can be added manually in the IDE as well, going to “Property Manager”->”Add Existing Property Sheet” and navigating and selecting the ``zlib.props`` file. But as we have learned a bit how the ``.vcxproj`` looks like, let’s do it directly in it:

```xml
<ImportGroup Label="Dependencies">
    <Import Project="zlib.props" />
</ImportGroup>
```

Once we have this setup, adding a new dependency to the project is simple, adding a new xxxx.props file and importing it under the same "Dependencies" section in our .vcxproj, in one single line.

# Managing multi-configuration: Release, Debug

Visual Studio C++ is a multi-configuration IDE. It means that it can handle different build configurations, like Release, Debug, or architectures like x64 or x86, in the same project without restarting, just selecting it in a combo box.

It is important to note that in the general case it is not possible to link libraries compiled with a different build type or architecture into the project. All the libraries and the executables using them must be built with the same build type and architecture. When not doing that, the most typical error is a link error that can look like:

```
1>IlmImf-2_5.lib(ImfStringAttribute.obj) : error LNK2038: mismatch detected for '_ITERATOR_DEBUG_LEVEL': value '0' doesn't match value '2' in main.obj
1>IlmImf-2_5.lib(ImfStringAttribute.obj) : error LNK2038: mismatch detected for 'RuntimeLibrary': value 'MD_DynamicRelease' doesn't match value 'MDd_DynamicDebug' in main.obj
```

If we want to support and develop multiple configurations, typically, at least a different library per configuration is needed. There are different alternatives, the first one would be using different names for the library, for example ``zlibd.lib`` for the debug one, ``zlib.lib`` for the release one, and variants like ``zlib64d.lib`` for 64 bits ones. A second alternative is to keep the same library name, but locate it inside different folders, like Release/x64 or Debug/Win32.

To let Visual Studio MSBuild use the active configuration values, we can introduce conditionals on both the “Configuration” and “Platform” IDE values our previous ``zlib.props`` file, something like:

```xml
<?xml version="1.0" ?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
	<ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
		<ClCompile>
			<AdditionalIncludeDirectories>C:\TeamDeps\zlib\include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
		</ClCompile>
		<Link>
			<AdditionalLibraryDirectories>C:\TeamDeps\zlib\lib\Debug\Win32;%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
			<AdditionalDependencies>zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>
		</Link>
	</ItemDefinitionGroup>
	<ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
		<ClCompile>
			<AdditionalIncludeDirectories>C:\TeamDeps\zlib\include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
		</ClCompile>
		<Link>
			<AdditionalLibraryDirectories>C:\TeamDeps\zlib\lib\Release\x64;%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
			<AdditionalDependencies>zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>
		</Link>
	</ItemDefinitionGroup>
</Project>
```

Depending on the scale, number of dependencies and configurations to manage, it could be interesting to go one step further and completely decouple the data from the functionality. In this case, it would mean to define a ``zlib.props`` file that imports a specific data file for one configuration:

```xml
<?xml version="1.0" ?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
	<ImportGroup Label="Configurations">
		<Import Condition="'$(Configuration)' == 'Release' And '$(Platform)' == 'x64'" Project="zlib_release_x64.props"/>
		<Import Condition="'$(Configuration)' == 'Debug' And '$(Platform)' == 'Win32'" Project="zlib_debug_win32.props"/>
	</ImportGroup>

	<ItemDefinitionGroup>
		<ClCompile>
			<AdditionalIncludeDirectories>$(ZLibIncludeDirectories)%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
		</ClCompile>
		<Link>
			<AdditionalLibraryDirectories>$(ZLibLibraryDirectories)%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
			<AdditionalDependencies>$(ZLibLibraries)%(AdditionalDependencies)</AdditionalDependencies>
		</Link>
	</ItemDefinitionGroup>
</Project>
```

And each of the files would define the specific variables, for example ``zlib_release_x64.props`` would be:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup Label="DepsVariables">
    <ZLibIncludeDirectories>C:\TeamDeps\zlib\include;</ZLibIncludeDirectories>
    <ZLibLibraryDirectories>C:\TeamDeps\zlib\lib\Release\x64;</ZLibLibraryDirectories>
    <ZLibLibraries>zlib.lib;</ZLibLibraries>
  </PropertyGroup>
</Project>
```

This approach makes more evident the important values that need to be defined, changes and improvements become less error prone.

# Transitive dependencies

It is very common that one library depends on another library functionality. For example, the popular Poco C++ framework, depends on ZLib (besides other libraries like expat, sqlite, etc). Most times, when a user wants to build an application using the Poco C++ framework, they don’t want to take care of all the transitive dependencies of Poco, and they just want to specify in their project their dependency on Poco, but not on other transitive dependencies as Zlib. Many times, users are not even aware of these transitive dependencies

It is possible to implement this logic in our property files, and introduce in the ``poco.props`` file:

```xml
 <?xml version="1.0" ?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
	<ImportGroup Label="Dependencies">
		<Import Condition="'$(zlib_props_imported)' != 'True'" Project="zlib.props"/>
	</ImportGroup>
	<PropertyGroup>
		<poco_props_imported>True</poco_props_imported>
	</PropertyGroup>
```

Note the condition on ``zlib_props_imported``, this is a flag that we introduce to avoid importing the same file twice. How could this happen? This is what is called a “diamond” in the dependency graph. If we had another dependency, like the Boost library, that also depends on ZLib, and we want to use both Poco and Boost in our project, the ``zlib.props`` file would be imported twice.

Lets recap at this stage the files that we have so far:
- ``zlib.props``: Entry point for the zlib library. It contains conditional logic based on the Visual IDE “configuration” and “platform” to select one of the following files. It also implements “import guards” to avoid being included transitively more than once.
- ``zlib_release_x64.props``: Contains the specific data about zlib library in its release|x64 mode, as ``ZLibLibraryDirectories``, that can change between different configurations.
- ``zlib_debug_x64.props``: Same as the previous one, but for Debug configuration. Other configuration files are also possible.
- ``poco.props``: Entre point for the poco library. This file is the one that users will include in their ``.vcxproj`` project files. It contains a transitive dependency to ``zlib.props``.
- ``poco_release_x64.props``: Specific data for poco library for the release|x64 configuration
- … other files, per each transitive dependency and per configuration.

# Automating the dependencies

Now that the dependencies are very structured, we have the necessary infrastructure to further automate the process. This could be very useful in several cases, like evolving dependencies. Many teams need to work with multiple projects and different versions of their C++ libraries. It would be relatively straightforward to define a layout like ``C:\TeamDeps\zlib\1.2.11`` and ``C:\TeamDeps\zlib\1.2.8``. Each project could define its versions and have some script to automate the generation of the different properties files.

Also, there are possibly more configurations that some teams need to manage for their deliveries, like needing to manage different variants of the library. A very typical example is linking with shared and static libraries. This would require also to be included in the dependencies layout.

Having this automation in place would be very convenient for developers working in different projects, or CI build agents that need some kind of isolation, and then require to use a different ``C:\TeamDeps`` for different jobs.


# An example with ImGui, OpenCV and Poco libraries

In this [Github repo](https://github.com/conan-io/examples/tree/master/libraries/imgui-opencv-poco) there is a C++ project for ``Visual Studio 16 2019`` implementing an application that is able to download an image from the internet using some functionality from the Poco library, process it with OpenCV library and display it using the ImGui graphical user interface rendering it with GLFW. All these libraries in turn have several transitive dependencies.

We could manually download them and build them from sources, put them in a folder like “C:\TeamDeps”, and then write our properties files. Conan C++ package manager can automate this for us, managing to download the packages from a central repository of open source packages [ConanCenter](https://conan.io/center), install them in a Conan cache so they don’t pollute or change the system in any way, and finally, using the [MSBuildDeps generator](https://docs.conan.io/en/latest/reference/conanfile/tools/microsoft.html#msbuilddeps) generate from the dependency graph all property files automatically for our project.

The first step is to install the dependencies (read the [conanfile.py file](https://github.com/conan-io/examples/blob/master/libraries/imgui-opencv-poco/conanfile.py) if you want to check how dependencies versions are specified there):

```bash
$ git clone https://github.com/conan-io/examples
$ cd examples/libraries/imgui-opencv-poco
$ cd msvc
$ conan install .. --generator=MSBuildDeps --install-folder=conan
```

This command will download and install all our dependencies from [ConanCenter](https://conan.io/center) and transitive dependencies (27 of them). The dependency graph can be generated with ``$ conan info .. --graph=graph.html`` and then open the ``graph.html`` file:

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-02-10/dependency_graph.png"
     align="center" alt="ImGui Poco OpenCV dependency graph"/>
</p>


After the ``$ conan install`` command, go to the ``conan`` folder and check there all the generated ``.props`` files.

Once the dependencies are installed, and the property files have been added to the project (this needs to be done just once, the project in the Github repo already has added the property files, no need to do anything), then it is possible to build and run the project. Remember to select “Release” and “x64”, as this is the default configuration that will be installed with ``conan install``.


<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2020-02-10/imgui_opencv_poco_bird.gif"
     align="center" alt="ImGui Poco OpenCV application running"/>
</p>


# Conclusion

Using property files is a convenient and structured way to manage dependencies information in Visual Studio C++ projects. They can be organized in a very systematic way to scale to any number of dependencies, manage transitive dependencies and multiple configurations (Release/Debug, x64/x86).

Read more about:
- [Conan C/C++ Package Manager](https://conan.io)
- [Poco Project](https://pocoproject.org/)
- [Dear-ImGUI library](https://blog.conan.io/2019/06/26/An-introduction-to-the-Dear-ImGui-library.html)
- [OpenCV](https://opencv.org/)
- [Visual Studio property files](https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-file-structure?view=msvc-160)
