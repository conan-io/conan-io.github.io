---
layout: post
comments: false
title: "What’s Your C/C++ Code Made Of? The Importance of Software Bill of Materials"
meta_title: "Native use of CycloneDX SBOMs on you C/C++ projects"
description: "Discover the importance of SBOMs for your software and learn how to easily generate them using Conan"
keywords: "C++, C, CRA, SBOM, SBOMs, CycloneDX, SPDX, Cybersecurity"
---

In today’s world, software is woven into almost every aspect of our lives, making security a fundamental priority. This 
is where the Software Bill of Materials (SBOM) comes into play! Think of the SBOM as an ingredient list for software. 
Just as we want to know what’s in our food, we also need to be aware of what components are used in our applications. 
An **SBOM provides a detailed list of all the components and libraries that make up a piece of software**, allowing 
organizations to identify vulnerabilities and manage risks more effectively. 

As organizations prepare for the implementation of Cybersecurity Risk Assessment (CRA) frameworks, having an SBOM in 
place becomes even more crucial. Recently, a European initiative has been launched to enhance the security and 
transparency of software components across the continent. The CRA emphasizes the importance of understanding and 
managing the security of software components, making SBOMs a key asset in this effort.

To align with this initiative, organizations are encouraged to **adopt standards such as CycloneDX 1.4, or SPDX 2.3 or 
greater** for generating their SBOMs. These standards provide comprehensive guidelines for representing and sharing 
software component information effectively. With an SBOM, not only does transparency improve, but security is also 
strengthened by enabling quick responses to potential threats. Organizations that proactively embrace SBOMs will be 
better positioned to comply with CRA requirements and enhance their overall security posture.

## Is there a standard for SBOM?

As the need for a Software Bill of Materials has become more evident, several standards have emerged to help 
organizations implement it effectively. Here are some of the most commonly used:

* **CycloneDX**: This is a lightweight and highly interoperable [SBOM standard](https://cyclonedx.org/docs/1.4/json/) that 
focuses on software security and integrity. It is designed to be readable by both humans and machines, using JSON or 
XML.  This makes it particularly useful in the context of DevSecOps, as it allows for continuous integration and 
vulnerability management.

* **SPDX** (Software Package Data Exchange): This open standard facilitates the exchange of information about software 
licenses and components. It enables organizations to effectively document the libraries and dependencies used in their 
projects, serving as a valuable tool for risk management.

## Can Conan generate the SBOM with my dependencies?

Yes, Conan can indeed generate a Software Bill of Materials (SBOM) and can do it using **CycloneDX 1.4 natively**. Conan 
tools feature a `from conan.tools.sbom` set of tools that allows the creation of SBOMs easily. These tools can be used 
in recipes, custom commands, deployers, or hooks. 
Let’s make an example using a [`post_package` hook](https://docs.conan.io/2/reference/extensions/hooks.html), here is the code:

```python
import json
import os
from conan.api.output import ConanOutput
from conan.tools.sbom import cyclonedx_1_4

def post_package(conanfile, **kwargs):
    sbom_cyclonedx_1_4 = cyclonedx_1_4(conanfile.subgraph)
    metadata_folder = conanfile.package_metadata_folder
    file_name = "sbom.cdx.json"
    with open(os.path.join(metadata_folder, file_name), 'w') as f:
        json.dump(sbom_cyclonedx_1_4, f, indent=4)
    ConanOutput().success(f"CYCLONEDX CREATED - {conanfile.package_metadata_folder}")
```

The hook calculates the subgraph using `conanfile.subgraph` and gives it to our new `cyclonedx_1_4` function, which returns
the SBOM in JSON format. So, we just have to save this content in a new file. We will put it inside the package metadata folder,
this is what you want if you want to upload it to your server for future analysis. 
This hook launches on `post_package`, it is perfect for generating our SBOM after every `conan create`. Here you can see
an example of a `openssl`  SBOM created with `Conan`:

```javascript
{
    "components": [
        {
            "author": "Conan",
            "bom-ref": "pkg:conan/openssl@3.0.15?rref=05e3fb00d6d340c1c241a7347f0a9ec9",
            "description": "A toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols",
            "externalReferences": [{"type": "website","url": "https://github.com/openssl/openssl"}],
            "licenses": [{"license": {"id": "Apache-2.0"}}],
            "name": "openssl",
            "purl": "pkg:conan/openssl@3.0.15",
            "type": "library",
            "version": "3.0.15"
        },
        {
            "author": "Conan",
            "bom-ref": "pkg:conan/zlib@1.3.1?rref=f52e03ae3d251dec704634230cd806a2",
            "description": "A Massively Spiffy Yet Delicately Unobtrusive Compression Library (Also Free, Not to Mention Unencumbered by Patents)",
            "externalReferences": [{"type": "website", "url": "https://zlib.net"}],
            "licenses": [{"license": {"id": "Zlib"}}],
            "name": "zlib",
            "purl": "pkg:conan/zlib@1.3.1",
            "type": "library",
            "version": "1.3.1"
        }
    ],
    "dependencies": [
        {
            "ref": "pkg:conan/openssl@3.0.15?rref=05e3fb00d6d340c1c241a7347f0a9ec9",
            "dependsOn": ["pkg:conan/zlib@1.3.1?rref=f52e03ae3d251dec704634230cd806a2"]
        },
        {
            "ref": "pkg:conan/zlib@1.3.1?rref=f52e03ae3d251dec704634230cd806a2"
        }
    ],
    "metadata": {
        "component": {
            "author": "Conan",
            "bom-ref": "pkg:conan/zlib@1.3.1?rref=f52e03ae3d251dec704634230cd806a2",
            "name": "openssl/3.0.15: [HOOK - hook_sbom_cyclone.py] post_package()",
            "type": "library"
        },
        "timestamp": "2025-02-04T10:52:09Z",
        "tools": [
            {
                "externalReferences": [{"type": "website","url": "https://github.com/conan-io/conan"}],
                "name": "Conan-io"
            }
        ]
    },
    "serialNumber": "urn:uuid:8ea61ad3-b6e2-44aa-97e3-f9614d670306",
    "bomFormat": "CycloneDX",
    "specVersion": "1.4",
    "version": 1
}
```

As you can see, this standard simplifies understanding our software's dependencies.

## I need a custom SBOM for my software. Can Conan help me?

Yes, Conan can certainly help you create a custom SBOM for your software! With the introduction of the new `subgraph` 
attribute in conanfiles, Conan provides a straightforward way to programmatically retrieve the dependencies of every individual 
package in a dependency graph.

Using this `subgraph` , you can access the complete dependency subgraph of the current package, which is essential for 
generating an accurate SBOM. The `subgraph` property features a `serialize()`  method that allows you to directly output its 
contents, making the process both efficient and easy.

Here you can see an easy example of a hook using the `serialize()` method. Also, we save the SBOM in the package metadata folder 
to upload it to the server and keep it safe for future analysis.

```python
import json
import os
from conan.api.output import ConanOutput

def post_package(conanfile, **kwargs):
    metadata_folder = conanfile.package_metadata_folder
    file_name = "sbom.conan.json"
    with open(os.path.join(metadata_folder, file_name), 'w') as f:
        json.dump(conanfile.subgraph.serialize(), f, indent=2)
    ConanOutput().success(f"CONAN SBOM CREATED - {conanfile.package_metadata_folder}")
```

By leveraging this interface, you can customize your SBOM according to your specific requirements, ensuring that it 
includes all relevant data related to your dependencies. This capability not only enhances the transparency of your 
software supply chain but also aids in better vulnerability management and compliance.

## Conclusion

SBOMs will become increasingly significant in the evolving landscape of software development. As vulnerabilities become 
more prevalent and regulatory requirements tighten, **SBOMs will be essential for enhancing transparency**, security, 
and compliance across the software supply chain.

To prepare for this future, organizations must adopt SBOM practices proactively. This includes integrating SBOM 
generation and management into development workflows. By doing so, companies can swiftly identify and address security 
risks associated with their software dependencies. 

For C and C++ projects, Conan can help generate SBOMs such as CycloneDX 1.4. Based on user feedback, other built-in 
formats will be prioritized. Please let us know about this or any other questions at our [GitHub webpage](https://github.com/conan-io/conan/issues).
