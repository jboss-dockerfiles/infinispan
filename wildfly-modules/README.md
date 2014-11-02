# Infinispan WildFly modules Docker image

Infinispan Modules 
==================

This is an example Dockerfile with [Infinispan](http://infinispan.org/) in embedded mode, namely [WildFly application server](http://wildfly.org/) with Infinispan modules.

## Usage

    docker run -it jboss/infinispan-modules

## Extending the image

    FROM jboss/infinispan-modules
    # Do your stuff here

Then you can build the image:

    docker build .


## Source

The source is [available on GitHub](https://github.com/jboss-dockerfiles/infinispan).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).