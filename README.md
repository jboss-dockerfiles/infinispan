Infinispan Docker Images 
========================

[![Build Status](https://travis-ci.org/jboss-dockerfiles/infinispan.svg?branch=master)](https://travis-ci.org/jboss-dockerfiles/infinispan/)

[Infinispan](http://infinispan.org/) is an open source data grid platform. 

This repository contains Docker imgaes for different flavours of Infinispan:

* Infinispan server
* Embedded Infinispan

Infinispan can be used in two different ways: in client-server mode and in embedded mode.  In client-server mode Infinispan runs as standalone server in diferent JVM and application using Infinispan connects to the server as a client. On the other hand, in embedded mode Infinispan runs in the same JVM as application and application access it as a library. For more details see [Infinispan documentation](http://infinispan.org/docs/7.0.x/user_guide/user_guide.html#_server_modules).

## Branching strategy

[Master branch](https://github.com/jboss-dockerfiles/infinispan/tree/master) contains current development version (currently 9.0.x).

Each minor stable version has its own branch (e.g. [8.2.x](https://github.com/jboss-dockerfiles/infinispan/tree/8.2.x)). All micro versions are tagged from that branch (e.g. 8.2.1.Final, 8.2.2.final).

See [Docker Hub builds guide](https://docs.docker.com/docker-hub/builds/) for more information

## Source

The source is [available on GitHub](https://github.com/jboss-dockerfiles/infinispan).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).
