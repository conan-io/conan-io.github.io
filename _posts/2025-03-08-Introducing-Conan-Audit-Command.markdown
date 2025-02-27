---
layout: post
comments: false
title: "Introducing the conan audit Command for Scanning C++ CVEs"
meta_title: "Secure Your C++ Builds with the New conan audit Command - Conan Blog"
description: "Learn how the new conan audit command helps you detect CVEs in your C++ dependencies, ensuring a more secure development workflow."
permalink: /introducing-conan-audit-command/
---

Ensuring that we work with a secure dependency graph and can react quickly to security
threats is becoming increasingly important. A recent example that underscores this need is
[the vulnerability discovered in XZ
Utils](https://en.wikipedia.org/wiki/XZ_Utils_backdoor) (CVE-2024-3094). While this
vulnerability had the potential to affect many systems, it was detected before widespread
deployment, limiting its actual impact. This incident highlights the importance of
proactive security tools to help identify and mitigate vulnerabilities in dependencies.

At Conan, we have long considered build security a priority, continuously implementing
features to enhance it. Some examples include native support for [generating SBOMs with
CycloneDX](https://blog.conan.io/2025/02/05/What-is-your-code-made-of-sboms.html) and
[package signing](https://docs.conan.io/2/reference/extensions/package_signing.html).

Building on this security-focused approach, we are excited to introduce a new experimental
command in Conan: `conan audit`. Starting with Conan 2.14, this command allows you to
check for potential CVEs (Common Vulnerabilities and Exposures) within your dependency
graph.

## Scanning for Vulnerabilities with `conan audit`

The `conan audit` command enables users to scan for potential vulnerabilities in any Conan
package available in Conan Center. This command connects to a service powered by JFrog
Advanced Security, which provides detailed vulnerability analysis reports.

To use the command, users must register and obtain a token that grants access to a limited
number of scans per day.

### Registering for the Service

Before using `conan audit`, you need to sign up for the service. Upon registration, you
will receive a token that must be validated via email.

To register, go to [https://audit.conan.io/register](https://audit.conan.io/register) and
fill in your details.

![Registration screen]

After registration, you will receive a token. Please make sure to store it securely as it
will only be displayed once.

![Token screen]

Next, you will receive an email to validate your token. Once validated, you can start
using `conan audit`.

![Validation email]

### Using the `conan audit` Command

The first thing you need to do is update the security provider token for Conan Center. Do
this by running:

```shell  
conan audit provider auth --name=conancenter --token=<your_token>
```  

Once this is done, you're ready to scan for vulnerabilities in your Conan packages. The
simplest way to check a specific package reference is by using `conan audit list` like
this:

  
```shell  
conan audit list openssl/1.1.1w
```

If you want to scan the entire dependency graph of your Conan recipe, you can use the
`conan audit scan` command by providing the path to the `conanfile`, just like in other
Conan commands:

```shell  
conan audit scan .
```  
  
The `conan audit scan` command supports different output formats, allowing you to generate
results in JSON for programmatic analysis or in HTML for a more detailed visual report.

```shell  
conan audit scan . --format=json
```  
  
```shell  
conan audit scan . --format=html
```  

## Troubleshooting

If you run into any issues using `conan audit`, please don’t hesitate to reach out for
support—we're here to help!  

📧 **Service Support:** For issues related to the registration process or the usage
of the `conan audit` command, contact the Conan team at
[conan@jfrog.com](mailto:conan@jfrog.com).  

🔒 **CVE-related Issues:** If you encounter problems with the CVE data returned by the
command, please report them to the JFrog Security team at
[conan-research@jfrog.com](mailto:conan-research@jfrog.com).  

## Conclusion

Proactive vulnerability scanning is essential in today's fast-paced development
environment. By integrating `conan audit` into your workflow, you can detect and mitigate
potential security issues early, ensuring a more secure dependency graph for your
projects. We encourage you to try out this experimental tool and share your feedback with
the community.

Stay secure, and happy coding!
