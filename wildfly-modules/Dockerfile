FROM jboss/wildfly:latest

# Set the INFINISPAN_VERSION env variable
ENV INFINISPAN_VERSION 7.1.1.Final

RUN cd $HOME && curl http://downloads.jboss.org/infinispan/$INFINISPAN_VERSION/infinispan-as-embedded-modules-$INFINISPAN_VERSION.zip | bsdtar -xf - -C $HOME/wildfly/modules/system/layers/base

# Set the default command to run on boot
# This will boot WildFly with Infinispan modules in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
