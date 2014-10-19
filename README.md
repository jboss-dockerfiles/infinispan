# Infinispan server Docker image

Infinispan
==========

This is an example Dockerfile with [Infinispan server](http://infinispan.org/).

## Usage

    docker run -it jboss/infinispan-server

## Extending the image

    FROM jboss/infinispan-server
    # Do your stuff here

Then you can build the image:

    docker build .


## Source

The source is [available on GitHub](https://github.com/jboss-dockerfiles/infinispan).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).
