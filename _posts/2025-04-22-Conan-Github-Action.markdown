---
layout: post
comments: false
title: "Speeding Up Your GitHub Builds with the Official Conan Action"
meta_title: "A GitHub Action for Conan - Conan Blog"
description: "Integrate Conan into your GitHub Actions workflow with the new Conan Action."
keywords: "C++, C, GitHub, CI, CD, Workflow"
---

In modern software development, fast and reliable CI/CD pipelines are essential. However, configuring and maintaining CI scripts (especially for dependency management) can slow down your workflow and increase maintenance costs.

[GitHub Actions](https://github.com/features/actions) automates tasks like installing dependencies, running tests, and deploying applications. But setting up tool dependencies can be time-consuming. Fortunately, GitHub Actions supports reusable extensions from the [GitHub Marketplace](https://github.com/marketplace?type=actions), making it easier to manage tools like Conan.

This article shows how to use the official [Conan GitHub Action](https://github.com/marketplace/actions/setup-conan-client) to speed up your builds and streamline your CI/CD pipeline.

## Why Use the Conan GitHub Action?

The official Conan GitHub Action, maintained by the Conan team, setting up the Conan client. It’s available on the GitHub Marketplace and is designed for easy integration and efficient dependency management. Using the official action ensures you benefit from ongoing maintenance, security, and community support.

### Features of the Conan GitHub Action

The Conan GitHub Action offers some features to customize your workflow execution, including:

- **Caching Conan packages:** The action can cache Conan packages to speed up the installation process. This is particularly useful when building multiple times, as it reduces the time spent downloading and installing dependencies. The cache is restored automatically when the action is run, so you don't have to worry about managing it yourself. By default, the action will not cache the Conan packages.

- **Custom Conan home folder:** The action allows you to specify a custom Conan home folder, which can be used to store the Conan cache and other configuration files. This is useful when you want to share the cache between different jobs or workflows, or when you want to use a specific location for the Conan home folder. By default, the action will use the default Conan home folder, which is located in the workstation home directory.

- **Conan version:** Define what Conan version you want to use in your workflow. This is useful when you want to use a specific version of Conan or when you want to test a new version before upgrading your workflow. Only Conan 2.x is supported by this action, so if you are using Conan 1.x, you will need to upgrade your workflow to use Conan 2.x. By default, the action will use the latest stable version of Conan available in the `pypi.org` repository.

- **Conan Audit token:** The action allows you to specify a Conan Audit token, which can be used to authenticate with the Conan server. This is useful when you want to authenticate with a Audit server and scan your packages for vulnerabilities. Always use GitHub secrets to store your tokens and avoid exposing them in your workflow.
By default, the action will not use a Conan Audit token.

- **Configuration installation:** The action allows you to specify a list of URLs to be consumed by the command [conan config install/install-pkg](https://docs.conan.io/2/reference/commands/config.html). This is useful when you want to install profiles, settings, or other configuration files from a remote server. The action will download the files and install them in the Conan home folder, so you don't have to worry about managing them yourself. By default, the action will not install any configuration files.

- **Python version:** The action allows you to specify the Python version to use in your workflow. This is useful when you want share the same Python version between Conan and your workflow. By default, the action will use the Python version 3.10.

## How to Use the Conan Action in a Workflow

Let’s look at a practical example: a nightly workflow that builds your project and scans for vulnerabilities using Conan.
Besides the GitHub workflow yaml file, a `conanfile.py` is expected to be present in the same repository.

First, add the Conan Action to your workflow yaml file:

```yaml
- name: Setup Conan Client
  uses: conan-io/setup-conan@v1
```

The the full workflow file will look like this:

```yaml
# .github/workflows/nightly-conan-audit-scan.yml
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
        conan audit scan . --format=json > output/conan-audit-report.json

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

This workflow will run every night at 01:00 a.m. UTC and will install the latest version of Conan.
It will also scan the requirements and all the transitive dependencies listed in the `conanfile.py` for expected vulnerabilities and upload the report as an artifact.
Finally, the file `output/conan-audit-report.json` will be checked for any **high** severity vulnerabilities using the `jq` command. If any are found, the workflow will fail with an error message.

For reference, the Conan package `openssl/3.4.1` should contain the [CVE-2019-0190](https://www.cve.org/CVERecord?id=CVE-2019-0190). In that case, the produced output by `conan audit scan` should contain the following JSON:

```javascript
{
  "name": "CVE-2019-0190",
  "description": "A bug exists in the way mod_ssl handled client renegotiations. A remote attacker could send a carefully crafted request that would cause mod_ssl to enter a loop leading to a denial of service. This bug can be only triggered with Apache HTTP Server version 2.4.37 when using OpenSSL version 1.1.1 or later, due to an interaction in changes to handling of renegotiation attempts.",
  "severity": "High",
  "cvss": {
    "preferredBaseScore": 7.5
  },
  "aliases": [
    "CVE-2019-0190",
    "JFSA-2023-000317713"
  ],
  "advisories": [
    {
      "name": "CVE-2019-0190"
    }
  ],
  "references": [
    "https://httpd.apache.org/security/vulnerabilities_24.html"
  ]
}
```

Here, the `severity` field is set to **High**. The workflow will fail and print the error message.

## Conclusion

The Conan GitHub Action streamlines dependency management and security scanning in your CI/CD workflows. It helps you automate Conan installation and configuration, making your builds faster and more reliable.
For further documentation reading, please check the [Conan GitHub Action documentation](https://docs.conan.io/2/integrations/github.html). In case of any questions, bugs and feature requests, please file a [issue](https://github.com/conan-io/setup-conan/issues) to its official repository.
