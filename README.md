Infinispan Docker Image 
=======================

[![Build Status](https://travis-ci.org/jboss-dockerfiles/infinispan.svg?branch=master)](https://travis-ci.org/jboss-dockerfiles/infinispan/)

[Infinispan](http://infinispan.org/) is an open source data grid platform. 

This repository contains the Docker image for Infinispan Server. For detailed instructions, see the [user manual](https://github.com/jboss-dockerfiles/infinispan/blob/master/server/README.md).

## Branching strategy

[Master branch](https://github.com/jboss-dockerfiles/infinispan/tree/master) contains current development version (currently 10.0.x).

Each minor stable version has its own branch (e.g. [9.4.x](https://github.com/jboss-dockerfiles/infinispan/tree/9.4.x)). All micro versions are tagged from that branch (e.g. 9.4.1.Final, 9.4.2.final).

See [Docker Hub builds guide](https://docs.docker.com/docker-hub/builds/) for more information

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).

## Running tests

Tests can be run locally going to the ```ci``` folder.
* Docker tests: ```./ci_check.sh```
* Openshift tests: ```./ci_openshift.sh```

In order to run the Openshift tests, make sure to have a recent version of docker (> 1.15) configured with ```--insecure-registry 172.30.0.0/16```
