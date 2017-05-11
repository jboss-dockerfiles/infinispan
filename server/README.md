# Infinispan server Docker image

## Configuring authentication

To be able to connect to any of the Infinispan server Docker images, authentication is necessary.
So, no matter how the image is started, `APP_USER` and `APP_PASS` environment variables need to be provided in order to interact with any application endpoints exposed by the image. 

Optionally, `APP_ROLES` environment variable can be passed in which provides specific security roles to be associated with the user.
The value of this environment variable is expected to be a comma-separated list of roles for the user.

The management console exposed by the Infinispan server Docker images also requires authentication.
In this case, to be able to access the console, `MGMT_USER` and `MGMT_PASS` environment variables need to be provided.
Even if not accessing the console, these environment properties are required if creating a cluster in the domain mode. 

Here are some examples on how environment variables can be provided depending on the chosen method to start the image.

Docker run example:

    docker run ... -e "APP_USER=user" -e "APP_PASS=changeme" jboss/infinispan-server 

Dockerfile example:

    ENV APP_USER user
    ENV APP_PASS changeme

Kubernetes yaml example:

    spec:
      containers:
      - args:
        image: jboss/infinispan-server:...
        ...
        env:
        - name: APP_USER
          value: \"user\"
        - name: APP_PASS
          value: \"changeme\"

OpenShift client example:

    oc new-app ... -e "APP_USER=user" -e "APP_PASS=changeme" ...

Finally, it's possible to add more fine grained credentials by invoking `add-user` command once the image has started up:

    docker exec -it $(docker ps -l -q) /opt/jboss/infinispan-server/bin/add-user.sh

## Starting in clustered mode

Run one or more:

    docker run -it jboss/infinispan-server

and the containers should be able to form a cluster.

#### Choosing the JGroups stack

To run with the ```tcp``` stack instead of ```udp```:

    docker run -it jboss/infinispan-server -Djboss.default.jgroups.stack=tcp

The run with the ```tcp-gossip``` stack, specifying the router location:

    docker run -it jboss/infinispan-server -Djboss.default.jgroups.stack=tcp-gossip -Djgroups.gossip.initial_hosts=172.17.0.2[12001]

## Starting in standalone mode

    docker run -it jboss/infinispan-server standalone

As it happens with clustered mode, it is possible to specify command line parameters to the server.

Examples:

To avoid exposing the management interface:

    docker run -it jboss/infinispan-server standalone -Djboss.bind.address.management=127.0.0.1

To print the version and exit:

    docker run -it jboss/infinispan-server standalone -v

Please consult the Infinispan user docs to find out about the available options.  

## Starting with a custom configuration

The first param to the container is the name of the desired configuration. For example, to start with the ```cloud.xml``` configuration:

    docker run -it jboss/infinispan-server cloud -Djboss.default.jgroups.stack=google -Djgroups.google.bucket=... -Djgroups.google.access_key=... 

## Running domain mode

Domain mode is composed of a lightweight managing process that does not hold data called domain controller plus one or more
host controllers co-located with the Infinispan Server nodes. To run the domain controller:

    docker run --name=dc -it jboss/infinispan-server domain-controller 

And then each host controller can be started as:

    docker run --link dc:dc -it jboss/infinispan-server host-controller

### Acessing the Server Management Console

The Server Management Console listens on the domain controller on port 9990.
To be able to access the console, credentials need to be provided (see above).

## Extending the image

    FROM jboss/infinispan-server
    # Do your stuff here

Then you can build the image:

    docker build .


## Source

The source is [available on GitHub](https://github.com/jboss-dockerfiles/infinispan).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).
