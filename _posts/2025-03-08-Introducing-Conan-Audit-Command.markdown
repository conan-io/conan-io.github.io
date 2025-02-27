---
layout: post
comments: false
title: "Introducing the conan audit Command for Scanning C++ CVEs"
meta_title: "Secure Your C++ Builds with the New conan audit Command - Conan Blog"
description: "Learn how the new conan audit command helps you detect CVEs in your C++ dependencies, ensuring a more secure development workflow."
permalink: /introducing-conan-audit-command/
---

Maintaining a secure dependency graph and responding swiftly to security threats is
critical in modern software development. A recent example that underscores this need is
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
package available in Conan Center. This command connects to a service powered by [JFrog
Advanced Security](https://jfrog.com/devops-native-security), which provides detailed
vulnerability analysis reports.

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
$ conan audit provider auth --name=conancenter --token=<your_token>
Provider authentication added.
```  

Once this is done, you're ready to scan for vulnerabilities in your Conan packages. The
simplest way to check a specific package reference is by using `conan audit list` like
this:
 
```shell  
$ conan audit list openssl/1.1.1w
Requesting vulnerability info for: openssl/1.1.1w

******************
* openssl/1.1.1w *
******************

2 vulnerabilities found:

- CVE-2023-5678 (Severity: Medium, CVSS: 5.3)

  Issue summary: Generating excessively long X9.42 DH keys or checking
  excessively long X9.42 DH keys or parameters may be very slow.  Impact summary:
  Applications that use the functions DH_generate_key() to generate an X9.42 DH
  key may exper...
  url: https://git.openssl.org/gitweb/?p=openssl.git;a=commitdiff;h=db925ae2e65d0d925adef429afc37f75bd1c2017

- CVE-2024-0727 (Severity: Medium, CVSS: 5.5)

  Issue summary: Processing a maliciously formatted PKCS12 file may lead OpenSSL
  to crash leading to a potential Denial of Service attack  Impact summary:
  Applications loading files in the PKCS12 format from untrusted sources might
  terminate ...
  url: https://github.com/alexcrichton/openssl-src-rs/commit/add20f73b6b42be7451af2e1044d4e0e778992b2

Total vulnerabilities found: 2


Summary:

- openssl/1.1.1w 2 vulnerabilities found

Vulnerability information provided by JFrog. Please check https://jfrog.com/advanced-security/ for more information.

You can send questions and report issues about the returned vulnerabilities to conan-research@jfrog.com.
```

To scan the entire dependency graph of a Conan recipe, use the `conan audit scan` command
and provide the path to the `conanfile`, just as you would with other Conan commands. This
command calculates the graph based on the specified profiles, taking all transitive
dependencies into account. For instance, if a Conan recipe depends on `libpng/1.5.30` and
`openssl/1.1.1w`, running an audit on the recipe would produce a result similar to this:


```shell  
$ conan audit scan .
...
======== Computing dependency graph ========
libpng/1.5.30: Not found in local cache, looking in remotes...
libpng/1.5.30: Checking remote: conancenter
Connecting to remote 'conancenter' anonymously
libpng/1.5.30: Downloaded recipe revision efa4bfdf973993197dbaa85b8c320723
...
Resolved version ranges
    zlib/[>=1.2.11 <2]: zlib/1.3.1
Requesting vulnerability info for: libpng/1.5.30
Requesting vulnerability info for: openssl/1.1.1w
Requesting vulnerability info for: zlib/1.3.1

*****************
* libpng/1.5.30 *
*****************

3 vulnerabilities found:

- CVE-2017-12652 (Severity: Critical, CVSS: 9.8)

  libpng before 1.6.32 does not properly check the length of chunks against the
  user limit.
  url: https://github.com/glennrp/libpng/blob/df7e9dae0c4aac63d55361e35709c864fa1b8363/ANNOUNCE

...

******************
* openssl/1.1.1w *
******************

2 vulnerabilities found:

...

**************
* zlib/1.3.1 *
**************

No vulnerabilities found.

Total vulnerabilities found: 5


Summary:

- libpng/1.5.30 3 vulnerabilities found
- openssl/1.1.1w 2 vulnerabilities found

Vulnerability information provided by JFrog. 
Please check https://jfrog.com/advanced-security/ for more information.

You can send questions and report issues about the 
returned vulnerabilities to conan-research@jfrog.com.
```  
  
The `conan audit scan` command supports different output formats, allowing you to generate
results in JSON for programmatic analysis or in HTML for a more detailed visual report.

```shell  
$ conan audit scan . --format=html > report.html
```  

Now open `report.html` to view the detailed results of the vulnerabilities found,
presented in a searchable table.

![Animated GIF of audit output]

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
