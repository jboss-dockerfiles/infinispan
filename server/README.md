# Infinispan server Docker image

## Adjusting memory

Infinispan Docker image automatically scales Java heap (`Xmx` and `Xms`) to memory limitations defined
 CGroups. The default behavior sets it to 50% of the container memory. This is a safe minimum that allows to
 use Infinispan with different configuration.

This setting can be easily overridden by specifying `JAVA_OPTIONS` environmental variable with `Xmx` setting.
In that case the automatic scaling scripts will use value specified by the user.

## Configuring authentication

To be able to connect to any of the Infinispan server Docker images, authentication is necessary.
The easiest way to create a new user (with specified password) before starting the server is to specify `APP_USER`
and `APP_PASS` environment variables or pass `-au` (for user name) and `-ap` (for password) switches.

Optionally, `APP_ROLES` environment variable (or `-ar` switch) can be passed in which provides specific security roles 
to be associated with the user. The value of this environment variable is expected to be a comma-separated
list of roles for the user.

The management console exposed by the Infinispan server Docker images also requires authentication.
In this case, to be able to access the console, `MGMT_USER` and `MGMT_PASS` environment variables
(or `-mu` and `-mp` equivalents) need to be provided. Even if not accessing the console,
these environment properties are required if creating a cluster in the domain mode.

If no application and/or management user and password is specified, the image will generate a new one. A newly 
generated user/password pair will be displayed on the console before the starts up.

Here are some examples on how environment variables can be provided depending on the chosen method to start the image.

Docker run example with environmental variables:

    docker run ... -e "APP_USER=user" -e "APP_PASS=changeme" jboss/infinispan-server 

Docker run example with switches:

    docker run ... jboss/infinispan-server -au "user" -ap "changeme"

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
          value: "user"
        - name: APP_PASS
          value: "changeme"

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
    
    
#### Integrate with jboss/jgroups-gossip

If the gossip router comes from ```jboss/jgroups-gossip```, it's important to align the versions with the Infinispan Server.

So for Infinispan 9.1.0.Final, the correct way of starting the gossip container is:

```
docker run -p 12001:12001 -e "LogLevel=DEBUG" jboss/jgroups-gossip:4.0.4.Final
```

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

    docker run --name=dc -it jboss/infinispan-server domain-controller -mu user -mp password

And then each host controller can be started as:

    docker run --link dc:dc -it jboss/infinispan-server host-controller -mu user -mp password

Specifying management user and password is required for operating the domain mode.

### Acessing the Server Management Console

The Server Management Console listens on the domain controller on port 9990.
To be able to access the console, credentials need to be provided (see above).

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
