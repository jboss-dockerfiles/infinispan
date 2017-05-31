# Infinispan server Docker image

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

## Configuring authentication
   
The 'default' and 'standalone' running modes don't not have credentials set. In order to define them, run after launching the container:

    docker exec -it $(docker ps -l -q) /opt/jboss/infinispan-server/bin/add-user.sh

and follow the instructions.

## Running domain mode

Domain mode is composed of a lightweight managing process that does not hold data called domain controller plus one or more
host controllers co-located with the Infinispan Server nodes. To run the domain controller:

    docker run --name=dc -it jboss/infinispan-server domain-controller 

And then each host controller can be started as:

    docker run --link dc:dc -it jboss/infinispan-server host-controller

### Acessing the Server Management Console

The Server Management Console listens on the domain controller on port 9990. Credentials are admin/admin.

## Source to image (S2I)

Infinispan Docker image uses S2I to supply configuration XML file to the server. The scripts copy content of user directory
into `/opt/jboss/infinispan-server/standalone/configuration`. The destination directory can be changed using `CONFIGURATION_PATH`
environmental variable.

The easiest way to run Infinispan with custom configuration inside OpenShift is to invoke the following command:

    oc new-app jboss/infinispan-server~https://github.com/<username or organization>/<repository with xml in its root>.git

There are special parameters to specify the context directory, branch or SHA1 of the repository. For more information
please refer to [OpenShift S2I manual](https://github.com/openshift/source-to-image).

Providing `clustered.xml` file is the simplest way to start (since this is the default configuration triggered by entrypoint scripts).
However it is advised to use custom file names and run them using using container args.

## Extending the image

    FROM jboss/infinispan-server
    # Do your stuff here

Then you can build the image:

    docker build .

## Source

The source is [available on GitHub](https://github.com/jboss-dockerfiles/infinispan).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/jboss-dockerfiles/infinispan/issues).
