---
layout: post
comments: false
title: "Speeding Up Your GitHub Builds with the Official Conan Action"
meta_title: "A GitHub Action for Conan - Conan Blog"
description: "Integrate Conan into your GitHub Actions workflow with the new Conan Action."
keywords: "C++, C, GitHub, CI, CD, Workflow"
permalink: /conan-github-action/
---

In modern software development, continuous integration and delivery (CI/CD) pipelines are essential for maintaining fast, reliable, and efficient workflows. However, managing and configuring the CI script in these pipelines can often be a bottleneck.

Github Actions is a platform that helps automate software workflows, including installing dependencies, running tests, and deploying applications. However, the time it takes to setup tools dependencies can significantly increase the maintenance cost of the CI script.

To accelerate the setup of a GitHub Action, the platform supports extensions, which are reusable components that can be shared across different workflows and are exposed via GitHub Marketplace. These extensions can be used to speed up the setup of tools dependencies, such as Conan.

In this article, we will explore how to use Conan to speed up your GitHub Action and improve the efficiency of your CI/CD pipeline.

## Conan client in GitHub Actions

The GitHub Marketplace can have multiple non-official extensions for the same tool, creating a situation where users have to choose between them, checking the documentation, maintenance, security, community interaction, license, and other factors. In order to avoid this situation, Conan has its own official GitHub Action, which is maintained by the Conan team and is available in the GitHub Marketplace. This action is designed to be used in GitHub Actions workflows and provides a simple way to install and configure Conan in your CI/CD pipeline.

This new GitHub Action is designed to be used in GitHub Actions workflows and provides a simple way to install and configure Conan in your CI/CD pipeline. It is available in the GitHub Marketplace and can be easily integrated into your existing workflows. It also have some initial features to improve its usage and speed up the setup of Conan in the CI pipeline when building multiple times, including:

* Caching Conan packages: The action can cache Conan packages to speed up the installation process. This is particularly useful when building multiple times, as it reduces the time spent downloading and installing dependencies. The cache is restored automatically when the action is run, so you don't have to worry about managing it yourself. By default, the action will not cache the Conan packages.

* Custom Conan home folder: The action allows you to specify a custom Conan home folder, which can be used to store the Conan cache and other configuration files. This is useful when you want to share the cache between different jobs or workflows, or when you want to use a specific location for the Conan home folder. By default, the action will use the default Conan home folder, which is located in the workstation home directory.

* Conan version: Define what Conan version you want to use in your workflow. This is useful when you want to use a specific version of Conan or when you want to test a new version before upgrading your workflow. Only Conan 2.x is supported by this action, so if you are using Conan 1.x, you will need to upgrade your workflow to use Conan 2.x. By default, the action will use the latest version of Conan available in the `pypi.org`.

* Conan Audit token: The action allows you to specify a Conan Audit token, which can be used to authenticate with the Conan server. This is useful when you want to authenticate with a Audit server and scan your packages for vulnerabilities. Always use GitHub secrets to store your tokens and avoid exposing them in your workflow.
By default, the action will not use a Conan Audit token.

* Configuration installation: The action allows you to specify a list of URLs to install configuration files from. This is useful when you want to install profiles, settings, or other configuration files from a remote server. The action will download the files and install them in the Conan home folder, so you don't have to worry about managing them yourself. By default, the action will not install any configuration files.

* Python version: The action allows you to specify the Python version to use in your workflow. This is useful when you want share the same Python version between Conan and your workflow. By default, the action will use the Python version 3.10.

## Using the Conan GitHub Action in a workflow

As real example, we will use the Conan GitHub Action in a nightly build workflow.
This workflow will run every night and will build the latest version of the project using Conan.

First, to use the Conan GitHub Action in a workflow, it's just needed to add it to the workflow file using this simple syntax:

```yaml
- name: Setup Conan Client
  uses: conan-io/setup-conan@v1
```

This section will install the latest version of Conan available in the `pypi.org` and configure it in your workflow.

The the full workflow file will look like this:

```yaml
name: Nightly Conan Audit Scan
on:
  schedule:
    - cron: '0 1 * * *'
  workflow_dispatch:

jobs:
  conan:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Conan Client
      uses: conan-io/setup-conan@v1
      with:
        conan_audit_token: ${{ secrets.CONAN_AUDIT_TOKEN }}

    - name: Scan Conan packages
      run: |
        conan audit scan . --format=json --out-file=output/conan-audit-report.json

    - name: Archive Conan Audit report
      uses: actions/upload-artifact@v4
      with:
        name: conan-audit-report
        path: output/conan-audit-report.json

    - name: Check High severity vulnerabilities
      run: |
        if [ -n $(jq -r '.. | select(.severity? == "High") | .severity' output/conan-audit-report.json) ]
        then
          echo "ERROR: High severity vulnerabilities found. Please check the report file for details."
          exit 1
        fi
```

This workflow will run every night at 01:00 a.m. UTC and will install the latest version of the project using Conan.
It will also scan the Conan packages listed in the `conanfile.py` expected for vulnerabilities and upload the report as an artifact.
The `conanfile.py` is expected to be present in the same repository.
Finally, it will check if there are any **high** severity vulnerabilities and fail the workflow if any are found.

## Conclusion

In this article, we have explored how to use the Conan GitHub Action to speed up your GitHub workflow and improve the efficiency of your CI/CD pipeline. The Conan GitHub Action is a powerful tool that can help you automate the installation and configuration of Conan in your workflows, making it easier to manage dependencies and build your projects. For further documentation reading, please check the [Conan GitHub Action documentation](https://docs.conan.io/2/integrations/github.html). In case of any questions, bugs and feature requests, please file a [issue](https://github.com/conan-io/setup-conan/issues).
