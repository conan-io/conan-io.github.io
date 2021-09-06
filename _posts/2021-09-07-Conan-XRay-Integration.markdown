---
layout: post 
comments: false 
title: "Safer C/C++ builds using Conan's Xray integration in Artifactory"
meta_title: "Safer C/C++ builds using Conan's Xray integration in Artifactory"
meta_description: "Using Conan's Xray integration in Artifactory you can make your C and C++ builds more secure"
---

[Xray](https://www.jfrog.com/confluence/display/JFROG/JFrog+Xray) is a DevSecOps tool that works
together with Artifactory to check potential security issues between the application dependencies. It's connected to private and public vulnerability data providers including
[NVD](https://nvd.nist.gov/) and [VulnDB](https://vulndb.cyberriskanalytics.com/) databases. It has
support for [multiple package types and different
technologies](https://www.jfrog.com/confluence/display/JFROG/JFrog+Xray) (such as Docker images, npm,
or PyPI), and since [version
3.21.2](https://www.jfrog.com/confluence/display/JFROG/Xray+Release+Notes) it also supports Conan
packages.

In this post, we explain how to make your C/C++ builds secure using Xray with Artifactory. We will go
through the setup process using a JFrog free-tier instance that comes with cloud-hosted Artifactory
and Xray instances ready for use with Conan. If you still don't know the JFrog free-tier, you can
[open an account](https://jfrog.com/start-free/) (it's completely free) to follow the steps in this
post. The Artifactory instance has some limitations like a limit of 10GB of transfer a month and 2GB
storage but will be more than enough for personal use or get an idea of how the experience with the
JFrog platform is.

## Setting up Artifactory: creating a Conan repository

After logging in to the free-tier instance, the first thing is creating a new Conan repository in
Artifactory. There's a getting started button in the free-tier that guides through the process of
doing it. For this post, we have created a local repository called *test-repo*. Once we configure our
new repository, we will add it to the Conan local client using [conan remote
add](https://docs.conan.io/en/latest/reference/commands/misc/remote.html) and [conan
user](https://docs.conan.io/en/latest/reference/commands/misc/user.html) commands (you will find
detailed instructions in the free-tier getting started guide and in [Artifactory
documentation](https://www.jfrog.com/confluence/display/JFROG/Conan+Repositories)).

## Setting up Xray: adding policies, rules and watches

The first thing we have to define to start working with Xray is a **policy**. A **policy** is just a
set of **rules**, and each of these **rules** defines a security/license criteria (the licenses
option is not available with the free-tier) that will trigger a corresponding set of actions when
met. We can create a new policy using the *Getting Started* button in the free-tier or just going to
*Administration > Xray > Watches & Policies* and creating a new **policy**.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-09-07/create_new_xray_policy.gif" align="center" alt="Creating a new Xray policy"/>
</p>

We will create a security **policy** named *mycompany-policy* and add one rule to it. Click in *New
Rule* and set *low-severity-warning* as the rule name. This rule will adjust the minimal severity to
low (severity score under 4.0/10.0). You can set the severity warning based on predefined ranges
(low, medium, high or critical) or [set up a custom CVSS Score
range](https://www.jfrog.com/confluence/display/JFROG/CVSS+Scoring+in+Xray). Multiple actions can be
triggered when the rule conditions are satisfied. We will add the *Notify Email* action for this rule
and check what happens when uploading a package with known security issues.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-09-07/xray_rules_options.png" align="center" width="50%" alt="Creating a new Xray rule"/>
</p>

The next thing is adding a **watch**. **Watches** connect the **resources** (such as repositories or
builds) with the **policies**. To create the watch, you could use the *Getting Started* button or go
to *Administration > Xray > Watches & Policies* and selecting the *Watches* tab. We will create a
watch named *test-watch* that will add our *test-repo* as a resource (you could also use patterns for
repository inclusion or add all the repositories to the watch). Then click on *Manage Policies* to
connect the *mycompany-policy* **policy** to the *test-repo* **resource**.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-09-07/create_new_xray_watch.png" align="center" alt="Creating a new Xray watch"/>
</p>

Please check the Xray documentation about [policies,
rules](https://www.jfrog.com/confluence/display/JFROG/Creating+Xray+Policies+and+Rules) [and
watches](https://www.jfrog.com/confluence/display/JFROG/Configuring+Xray+Watches) for more
information.

## Testing with the Conan client

Now that we added the **policy** and connected the Conan repository to that **policy** with a
**watch**, it is time to test it with the Conan client. We upload a Conan package that's affected by
some vulnerability to the *test-repo* repository, and we should receive an email warning us about
that vulnerability. Let's try, for example, with
[openssl/1.1.1h](https://conan.io/center/openssl?version=1.1.1h) that should be affected by
[CVE-2020-1971](https://nvd.nist.gov/vuln/detail/CVE-2020-1971).

```bash
$ conan install openssl/1.1.1h@ -r conancenter
$ conan upload openssl/1.1.1h@ --all -c -r test-repo
```

Just right after this package is uploaded, you should receive an e-mail warning about the policy
violation.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-09-07/xray_warning_email.png" align="center" alt="Xray policy break warning email"/>
</p>

Clicking on the link will take you to your Artifactory instance. Selecting the *Xray Data* tab will
show all the details about the vulnerabilities present in the package.

<p class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2021-09-07/xray_openssl_report.png" align="center" alt="Vulnerabilities report"/>
</p>

Warning about vulnerabilities in uploaded packages is helpful, but you also probably want to prevent
anyone from downloading those packages. We will modify the rule we previously added and also check
the *Block Download* option. If we try to install any binary affected by security issues, Xray should
block the download.

```bash
$ conan remove openssl/1.1.1h@ -f # to force downloading from the server
$ conan install openssl/1.1.1h@ -r test-repo
Configuration:
[settings]
arch=x86_64
arch_build=x86_64
build_type=Release
compiler=apple-clang
compiler.libcxx=libc++
compiler.version=12.0
os=Macos
os_build=Macos
[options]
[build_requires]
[env]

openssl/1.1.1h: Retrieving from server 'test-repo' 
openssl/1.1.1h: Trying with 'test-repo'...
ERROR: Permission denied for user: 'test-user@jfrog.com'. [Remote: test-repo]
```

We showed just a simple example of what you can do to make your C/C++ builds more secure using Conan
together with Artifactory and Xray. You could also experiment with other options like using the
[conan_build_info
v2](https://docs.conan.io/en/latest/reference/commands/misc/conan_build_info.html#conan-build-info-v2)
to scan all the packages belonging to one build. Also, you could try setting a webhook in the *rules*
to make more complex actions such as automatically creating a JIRA ticket or sending alerts to a
Slack channel.

## Conclusions

Making your C/C++ builds more secure with Xray and Artifactory is just a matter of minutes. You can
configure the rules that fit your company's security policies and trigger complex actions using
features such as webhooks. If you want to try and run a cloud-hosted Artifactory instance with Xray
support, you can [create a new Artifactory free-tier account](https://jfrog.com/start-free/).
