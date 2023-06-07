---
layout: post
comments: false
title: "New Cheat Sheet for Conan 2.0 is finally here!"
description: "One of the best assets for Conan users was the original cheat sheet, updating this for Conan 2.0 gave was a very good visual to begin explaining the changes, and from migration tip and tricks for users looking to update. This will be a helpful tool to pick up the basics, setting you on the right track for your Conan adventure. This now focuses on installing packages with Conan 2.0, the C and C++ package manager, for consuming dependencies, creating local private packages, changing the Conan client configuration, using conan search to find package and much more."
keywords: "conan search, conan generators, conan install, conan profile, conanfile, conan create, conan generator, conan show location, conan command, conan attributes, conan pdf, conan show change"
---

<style>
  blockquote {font-size: 85%;}
  table {font-size: 85%; width: 100%; margin-bottom: 1rem;}
  td { border-bottom: 1px solid #dddddd;}
  thead { background-color: #dddddd;}
  div.highlight {font-size: 85%;}
</style>

This is the easiest way to see the exciting new features with Conan 2.0

![[download](https://docs.conan.io/2/knowledge/cheatsheet.html)](https://docs.conan.io/2/_images/conan2-cheatsheet-v5.png)

## Comparing 1.x and 2.0

One of the biggest changes is to the command line and this happens to shine with a visual

<div class="centered" style="display: table; margin-bottom: 1rem;">
    <img  src="https://docs.conan.io/1/_images/conan-cheatsheet.png" style="display: inline; width: 50%;" alt="Conan 1.x Cheat Sheet"/>
    <img  src="https://docs.conan.io/2/_images/conan2-cheatsheet-v5.png" style="display: inline; width: 50%;" alt="Conan 1.x Cheat Sheet"/>
</div>

Obvious changes, new design and 1<sup>st</sup> and 2<sup>nd</sup> column switched places but that should not matter, we’ll refer to them by the opening section header.

Let’s dive into the changes.

## Search Packages

| Conan 1.x                        | Conan 2.0                           |
| -------------------------------- | ----------------------------------- |
| conan search zlib -r conancenter | conan search zlib/* -r conancenter |

It’s going to take a keen eye to notice the only change between these. If you spotted the ``/*``, that’s the evidence of the [unified references](https://docs.conan.io/1/migrating_to_2.0/commands.html#unified-patterns-in-command-arguments). This allows more granularity when specifying names, versions, users or channels. This change is also carried into recipes to access dependencies. See [profile patterns](https://docs.conan.io/2/reference/config_files/profiles.html#profile-patterns) for more details.

## Consume Packages

This is where you are most likely to run into the changes.

### [Conan install](https://docs.conan.io/2/reference/commands/install.html)

| Conan 1.x                                                | Conan 2.0                             |
| -------------------------------------------------------- | ------------------------------------- |
| conan install &lt;package_reference> (e.g. zlib/1.2.13@) | conan install -–requires=zlib/1.2.13 |

If the ``--requires`` jumped at you, that’s perfect. Notice the ``@`` is missing? This is the change between 1.x and 2.0. How Conan distinguished between passing the CLI a reference or a path is much more explicit.  
References lose the ``@`` suffix and are explicitly called out by a dedicated argument ``--requires``. This is true for all commands, not just the ``install`` command. This should alleviate misfortune cases where a reference has the same names as the path to its conanfile which leads to erroneous user inputs.

> Note: When adding a user and/or channel the ``@`` is still required, when there is no user the ``@`` can be omitted.

| Conan 1.x                            | Conan 2.0                             |
| ------------------------------------ | ------------------------------------- |
| conan install &lt;path_to_conanfile> | conan install . # path to a conanfile |

Next is ``conan install <path>``, for example ``./conanfile.py`` if it’s in your current directory, this is unchanged. There are other considerations, such as layouts, where if you previously used ``--install-folder`` you may need to adapt this within the recipe.

### [Conanfile.txt](https://docs.conan.io/2/reference/conanfile_txt.html) with build system

This is where we are going to see the most changes, there are two big ones:

- We are using different generators
- There is now a layout section

<!-- The white spaces in the table are important formatting -->

<table>
  <thead>
    <tr><th>Conan 1.x</th><th>Conan 2.0</th></tr>
  </thead>
  <tbody>
    <tr>
<td>
<div class="language-ini highlighter-rouge" style="width: 85%;margin-left: auto;margin-right: auto;">
<div class="highlight"> <pre class="highlight" style="padding: 0.5rem;margin: 0.5rem 0;"><code><span class="nn">[requires]</span>
<span class="err">zlib/1.2.13</span>

<span class="nn">[generators]</span>
<span class="err">cmake_find_package</span>
</code></pre></div></div></td>
<td>
      <div class="language-ini highlighter-rouge" style="width: 85%;margin-left: auto;margin-right: auto;"><div class="highlight">
      <pre class="highlight" style="padding: 0.5rem; margin: 0.5rem 0;"><code><span class="nn">[requires]</span>
<span class="err">zlib/1.2.13</span>

<span class="nn">[generators]</span>
<span class="err">CMakeToolchain</span>
<span class="err">CMakeDeps</span>

<span class="nn">[layout]</span>
<span class="err">cmake_layout</span>
</code></pre></div></div></td>
    </tr>
  </tbody>
</table>

> Note: Instead of listing different generators in the Conan 1.x column the example is more focused on CMake

This takes advantage of the features added in Conan 1.33. We used the new [Generators](https://docs.conan.io/2/reference/tools.html?highlight=Toolchain) [CMakeToolchain](https://docs.conan.io/2/reference/tools/cmake/cmaketoolchain.html) and [CMakeDeps](https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html) and lastly leveraged [layouts](https://docs.conan.io/2/reference/tools/layout.html).

Tip: This is completely valid Conan 1.x syntax and if you are using this you’ll have a harder time switching to 2.0. Make sure to be on the latest Conan 1.x features as a part of your Migration Plan!

The layout is just as important as the updated Generators. Its role is to tell Conan where our code and build scripts are located. For this example the key role is to specify where to output the generated files. Without this Conan will spit everything out in the current directory.

| Conan 1.x                                | Conan 2.0       |
| ---------------------------------------- | --------------- |
| mkdir build && cd build conan install .. | conan install . |

With this in mind, if we look at the next command in the 1.x example, we used to do a ``mkdir build && cd build``. We no longer need this because of the ``cmake_layout`` we declared in the 2.0 ``conanfile.txt``.

All of this has a butterfly effect. Now that we no longer have to change directories (where the build folder is explicit in the declaration of our conanfile) the install commands changed ever so slightly with the path going from parent directory to current directory. One less character to type.

| Conan 1.x                   | Conan 2.0                                                        |
| --------------------------- | ---------------------------------------------------------------- |
| cmake .. && cmake --build . | cmake --preset conan-releasecmake --build --preset conan-release |

> Note: Instead of listing different generators in the Conan 1.x column the example is more focused on CMake

If you have not heard or tried [CMake Presets](https://docs.conan.io/2/examples/tools/cmake/cmake_toolchain/build_project_cmake_presets.html) yet, you are missing out. This makes setting up a project way easier. This example requires CMake 3.23 or newer, but that’s not required as you can explicitly pass in with CMake as old as 3.15 the toolchain file ``-DCMAKE_TOOLCHAIN_FILE=build/generators/conan_toolchain.cmake``. (the exact path varies depending on the CMake generator, platform, and settings so read the CLI output which will give you the correct one).

## [Client Configuration](https://docs.conan.io/2/reference/config_files.html)

This is going to be taking “Show local client configuration” and “configure local client” in addition to “add or modify client configurations”. We’ll also be comparing “Remote repository configurations”.

These sections got the most mixing up because

- ``conan config`` is much leaner
- ``conan user`` was moved to ``conan remote login``

In order to make the comparison easier, I’ve reorganized the commands (from the old 1.x side) to match one to one (or none) with the new replacement

|                        Conan 1.x                       | Conan 2.0                                                   |
| ------------------------------------------------------ | ----------------------------------------------------------- |
|                **Client Configurations**               |                                                             |
|                                                        | conan profile detect                                        |
|                                                        | conan config list                                           |
| conan config get                                       |                                                             |
| conan profile show default                             | conan profile show -pr default                              |
| conan config install &lt;url_or_path>                  | conan config install &lt;url_or_path>                       |
|       conan config set general.revision_enabled=1      |                                                             |
|            **Remote Repository Management**            |                                                             |
|                    conan remote list                   | conan remote list                                           |
|           conan remote add my_remote &lt;url>          | conan remote add my_remote &lt;url>                         |
| conan user -p &lt;password> -r my_remote &lt;username> | conan remote login my_remote &lt;username> -p &lt;password> |

Right off the line, we have a command that's highlighted for 2.0 cheat sheet but was not present for 1.x originally. This is one of the more requested features, opt-in default profiles. [Managing profiles](https://docs.conan.io/2/reference/commands/profile.html?highlight=best%20practices) is one of the critical decisions for using Conan in CI/CD for DevOps. We have witnessed bad habits around relying on ``conan profile detect`` which limited the ability to improve the client. With Conan 2.0, there is [no stability guaranteed for the detected configuration](https://docs.conan.io/2/reference/commands/profile.html?highlight=not%20stable), this is something you should reconsider if you were doing ``conan config set`` which is also removed for the same reason. Alternative solutions are custom commands or managed profiles. 

``conan config list``, this is a very simple command that [shows all the available configurations](https://docs.conan.io/2/reference/commands/config.html#conan-config-list) one could possibly change. To display the value, ``conan config get`` was replaced by [``conan config show``](https://docs.conan.io/2/reference/commands/config.html#conan-config-show) which takes a _pattern_ which is the same as the values. For example ``tools.build.cmake.*`` to list all the CMake specific configurations current values defined in [``global.conf``](https://docs.conan.io/2/reference/config_files/global_conf.html).

[``conan config install``](https://docs.conan.io/2/reference/commands/config.html#conan-config-install) is unchanged and the [recommended way of managing profiles](https://docs.conan.io/2/knowledge/guidelines.html#good-practices), settings in 1.x and custom commands or extensions with 2.0.

``conan profile show default`` gets the same ``-pr`` as ``conan install`` unified command line syntax at its best. ``conan profile show`` also works in 2.0 which should be a simplification for punch keys into a terminal.

Some straight forward commands to review:

- Conan remote list – unchanged
- Conan remote add – unchanged
- ``conan user`` was replaced with [``conan remote login``](https://docs.conan.io/2/reference/commands/remote.html#conan-remote-login).

## Display Information

| Conan 1.x                                 | Conan 2.0                               |
| ----------------------------------------- | --------------------------------------- |
| conan inspect &lt;path> -a &lt;attribute> | conan inspect .                         |
| conan get &lt;reference>                  |                                         |
| conan info &lt;path_or_reference>         | conan graph info –requires zlib/1.2.13  |
|                                           | conan graph info . -f html > graph.html |

``conan inspect`` is mostly unchanged, it’s still focused on local recipes. For migration, it dropped the ``-a attribute``, this is replaced with structured output. You can add ``-f json`` for a more machine readable format to work with.

``conan get`` was removed – a recipe by itself or accessing parts of a remotely hosted export/package was error prone and misused – instead you can use ``conan cache path`` to get the folder and then print the contents of the file however you like.

``conan info`` was rolled into [``conan graph``](https://docs.conan.io/2/reference/commands/graph/info.html) as a subcommand since they were very tightly coupled. It gains the same unified reference syntax that we saw with ``install`` hence the ``--requires`` here. The last command features ``--format html`` which is the new formatters syntax. This supports the HTML view that was present in Conan 1.x.

## Creating a Package

Last but not least.

| Conan 1.x                                 | Conan 2.0                                               |
| ----------------------------------------- | ------------------------------------------------------- |
| conan new &lt;reference> -m &lt;template> | conan new cmake_lib --define name=hello -d version=0.1  |
| conan export &lt;path_to_conanfile>       |                                                         |
| conan create . -pr &lt;profile>           | conan create . # path to conanfile                      |

New has an updated syntax, along with update templates. This change was motivated to enable passing in more different inputs, for example some templates can be created with requirements, adding ``-d requires=pkg/0.1`` to this example would achieve this.

Export is no longer featured but remains a useful command with the same functionality

Create is unchanged but does implement the new reference syntax along with removing deprecated flags.

Conan create is unchanged in this example however, the “filling in the reference” has changes, the name, version, user, channel are now passed with arguments with the same name instead of the 1.x reference syntax that was removed. ``conan create . 1.0.0@frog`` would now be ``conan create . –version 1.0.0 –user frog``.

## Upload a Package

| Conan 1.x                          | Conan 2.0                           |
| ---------------------------------- | ----------------------------------- |
| conan upload zlib* -r remote –all | conan upload “zlib/*” -r my_remote |

There are a few subtle changes here, the reference used in the example previously matched any recipe starting with zlib, include zlib-ng which was not the intention, so now with the unified reference syntax it’s explicit matching only on the version since the ``/`` is present.  
Our example remote was renamed, style points, but not indicative of anything functional.

Lastly ``--all`` is no longer present, this is now the default in 2.0 and there is now a ``--only-recipe`` for the old behavior.

## Deploy outside the cache

| Conan 1.x                            | Conan 2.0                                                            |
| ------------------------------------ | -------------------------------------------------------------------- |
| conan install zlib/1.2.11@ -g deploy | conan install –requires=zlib/1.2.13 –deploy full_deploy -g CMakeDeps |

There are 2 new features in the one snippet.

- Deployers
- No cache workflow (see [last weeks blog](https://blog.conan.io/2023/05/23/Conan-agnostic-deploy-dependencies.html) to learn more)

Previously the [old deploy generator](https://docs.conan.io/1/reference/generators/deploy.html) only copied all the files to the local directory essentially unpacking the ``conan_package.tgz`` that would be on the remote. This has a few drawbacks and there were tons of requests for more specialized versions. This was replaced with [Deployers](https://docs.conan.io/2/reference/extensions/deployers.html). The new [built-in ``full_deploy``](https://docs.conan.io/2/reference/extensions/deployers.html#full-deploy) replaces the old one with the same functionality. It gained the support for other generators to be used in combination with deployers, such that the CMakeDeps will create files that use paths with the location inside the “full deploy” (i.e not reference the cache!). This is a long requested workflow that is now possible with 2.0.
