---
layout: post
comments: false
title: "From Zero to Package in Seconds: the new Conan MCP"
description: "The integration of Conan with the MCP server offers several compelling advantages, particularly for developers working with C and C++ dependencies"
meta_title: "From Zero to Package in Seconds: the new Conan MCP"
categories: [MCP, AI, GPT, conan, conan-mcp]
---

MCP (Model Context Protocol) is an [open-source standard](https://modelcontextprotocol.io/docs/getting-started/intro) that allows language models and AI applications like ChatGPT, 
Claude, or Grok to connect with other systems, enabling them to access data sources such as local files or databases, 
workflows like specific prompts, and tools, such as, in our case, the Conan client.

This standard allows all these resources to be grouped together and provides the AI with a way to use them to complete 
tasks in an **agentic way**.

## Why should I use it?
The integration of Conan with MCP offers several compelling advantages, particularly for developers working 
with C and C++ dependencies and AI development tools:

### Enhanced Automation and Efficiency
* **Easier Packaging Workflow**: The MCP server allows AI agents to interact with the Conan client seamlessly. This means you 
can simply describe the package you need, and the AI agent, using Conan via the MCP, can automatically handle the 
entire process: checking the last version of your dependencies, creating the whole structure of the project, installing 
your dependencies, checking your licenses and auditing your dependencies in order to find vulnerabilities. All from a 
natural language prompt.
* **Reduced Context Switching**: Developers no longer need to jump between their development environment, command line, 
and documentation to manage dependencies. The AI acts as an intelligent intermediary, handling complex Conan tasks 
in the background.

### Easy Dependency Management and Auditing
* **Advanced Package Search**: Thanks to the Conan MCP Server, you can search for the exact package you need from your 
remotes by specifying the operating system, architecture, compiled binary options, or even complex version range 
filters, all without resorting to command line syntax.
* **Simplified Dependency Definition**: Leveraging the power of natural language processing through MCP, developers can 
define their required C/C++ dependencies without needing to memorize specific Conan syntax for creating recipe files.
For instance, a simple request like "I need the latest version of Boost for my project, 
compiled with C++17 support" is translated by the AI agent into the necessary Conan commands and configuration.
* **Proactive Auditing and Security**: The AI agent can proactively audit dependencies as they are installed, automatically
checking for known vulnerabilities (CVEs) and verifying license compliance against project policies, giving immediate 
feedback in natural language.

## Let’s dive into real examples
### Listing packages
Let’s start with a simple one: we’re going to try to search for the compiled packages on ConanCenter for a library, 
such as zlib, with some options, including the architecture being armv8 and the shared option set to false, and have it tell 
us which versions we have packages for.
{% highlight bash %}
tell me which versions of zlib packages are available with architecture and statically linked
{% endhighlight %}
<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-12-01/gif1-List-versions-x6.gif"
       alt="List versions gif example"/>
</div>
<br>

### Manage existing profiles
The MCP can also access the list of profiles and is able to query it, so that, for example, if you want to check which 
C++ version my Windows profile with MSVC 193 is configured for, you can simply ask:
{% highlight bash %}
Check my Conan profiles and tell me which cppstd is configured in the Windows profile that uses compiler version 193.
{% endhighlight %}
<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-12-01/gif2-profile-x6.gif"
       alt="Search profile gif example"/>
</div>
<br>
It will list the profiles using a `conan profile list` command and then use `conan profile show` with the selected profile 
to obtain the required information. For this type of functionality to work correctly, we recommend maintaining a proper 
order when naming your Conan profiles.

### Create new packages
Let’s move on to one of the highlights of the MCP: **package creation**. Suppose we want to start a project of a library 
that uses CMake, with dependencies on fmt and OpenSSL. We can let Conan MCP create the entire project scaffolding and 
install the dependencies.
{% highlight bash %}
Create a project for a CMake library using Conan, with dependencies on the 
latest versions of fmt and OpenSSL. Install the dependencies of the project.
{% endhighlight %}
<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-12-01/gif3-Create-project-x6.gif"
       alt="Create project gif example"/>
</div>
<br>

### Auditing project and checking licenses
The crown jewel of this Conan MCP is **library auditing and license listing**, just a simple prompt away. Using the previous 
project as a base, let’s ask the language model to ensure that the resolved versions have no vulnerabilities and that 
all the licenses used by our dependencies are suitable for commercial use.
{% highlight bash %}
Ensure my project’s third-party libraries are secure and licensed for commercial use.
{% endhighlight %}
<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-12-01/gif4-Verify-x10.gif"
       alt="Verify project gif example"/>
</div>
<br>

## Installing Conan MCP
To install it, the first thing you need is an MCP client. You can use for example LibreChat or 
Cursor. Then, simply add to your MCP configuration:
{% highlight bash %}
{
  "mcpServers": {
    "conan": {
      "command": "uvx",
      "args": ["conan-mcp"]
    }
  }
}
{% endhighlight %}

## What is next?
Conan MCP is still in an early stage, with a strong focus on the most critical developer workflows, and we are gradually
expanding support for more Conan features. We would love to hear your feedback about what you are missing or which 
workflows you would like to see supported next.

We have prioritized the features most critical for the developer workflow: powerful **package search** and filtering, 
seamless **project creation** and dependency installation, profile checking, and the most essential: **vulnerability 
scanning and license listing**. 

We would love to hear your ideas. Feel free to share your thoughts in our [repository](https://github.com/conan-io/conan-mcp)!
If you have any suggestions for new features you would like to see addressed by the Conan MCP, or even if you wish to 
contribute code to the project, don't hesitate to do so! 
Your feedback and contributions are invaluable in shaping the future of this tool.

Happy prompting with Conan MCP!

