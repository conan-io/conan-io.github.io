---
layout: post
comments: false
# other options
---

Conan is a free and open source (FOSS) project that implements a C and C++ package manager, consisting in a user side application and a server, that can be run anywhere, as the system is decentralized. We are running at **conan.io** a server instance as a convenience repository where users can read and write their own packages without having to run their own server.

Conan usage has quite increased in the last months and we were starting to have some issues with the conan.io server memory and processor. We were using a single machine where a conan-server, the conan.io web and the web-api applications were running. We had already scaled up the server adding resources to it.

The true problem was, whenever we needed to restart or do some maintenance to the server, we had to cut the service to all our users. That definitely had to be solved.

What have we done? We were already using docker to deploy our applications, and we had isolated running applications, so a lot a work was already done. 

<h2 class="section-heading">Scaling out</h2>

So, this is how we rolled out the new infrastructure, step by step:

- Prepared a server image (snapshot) with the minimal installed apps in the cloud provider (digital ocean in our case).
- Started 3 new droplets (servers in digital ocean): Two for the applications (balanced servers) and one for the load balancer. We kept the old instance working until all the process was complete to avoid conan.io downtime.
- Created a private network between the new servers, so the servers and the load balancer could communicate without encryption nor user/password safety.
- Installed nginx as a load balancer http://nginx.org/en/docs/http/load_balancing.html. This server handles the ssl certificate and balances the traffic to the new servers.
- We already had nginx in the servers to route the different domains (server.conan.io, webapi.conan.io and conan.io) to the right application docker container.  - We just kept the same configuration but removing the SSL management, this is now done by the load balancer.
- Tested that everything worked fine, using the local machine /etc/hosts file to emulate the DNS change pointing to the load balancer without changing the real DNS.
- Changed the DNS and point the domain to the new load balancer.

Now we are ready to easily scale conan.io just by creating a new droplet and adding it’s private IP to the load balancer configuration. Load balancer will automatically distribute the requests and, if a server is down it will pass the requests to the other available servers. It will also be easier to do maintenance tasks without interrupting the service.

<h2 class="section-heading">Why we started with just one server</h2>


Ok, nice post about devops…. hey, wait a minute! So, you were using just a single server for all conan.io? Well, yes, we were. We had several reasons:

- We are not funded, so keeping costs low was an important reason. We have already had some revenue, as a result of users wanting consultancy and help. So we are more confident that conan.io will find its way to be sustainable. 
- The simultaneity coefficient. Not every user connects and install packages from conan.io at the same time. In fact, the local conan cache has proven to be very useful for offline work, and requiring minimal server connections. So it is more about memory usage rather than the server couldn't attend so many requests per second. Actually, the most important reason is to provide a continuous and reliable service, not to attend a massive number of concurrent requests.
- It was very simple to start with and launch early, get feedback about the tool. You know, keep it lean, avoid premature optimization. Now, conan API calls have ramped in the last months, so we are more certain to be delivering some value, and conscious that not interrupting the service is taking more importance.
- We were able to run in one server because the bulk of downloads and uploads was being outsourced to Amazon Web Services S3 service. Obviously, should our server had to serve all that downloads and uploads, we would have had a problem much earlier.
- The central conan.io server was not necessary for reliable operation, as the server was already provided as open source, and can be easily launched, to run an in-house server instance. We knew from our experience that this server was something really wanted by companies willing to use this technology, so we took that into account at conan design, and this hypothesis seems to have been proved.

<h2 class="section-heading">Conclusion</h2>

This post might not be of high interest for many C and C++ developers or conan users, which might be interested in new features, libraries, etc. But it is something necessary, and as we are aware of some users already running their own server, we thought that this information could be useful for them too. Just remember, if you need help with your in-house conan server, we are here to help, write us an email.
