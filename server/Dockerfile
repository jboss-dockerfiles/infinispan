# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:11

# Set the INFINISPAN_SERVER_HOME env variable
ENV INFINISPAN_SERVER_HOME /opt/jboss/infinispan-server

# Set the INFINISPAN_VERSION env variable
ENV INFINISPAN_VERSION 10.0.0.Beta3

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Server download location
ENV DISTRIBUTION_URL https://downloads.jboss.org/infinispan/$INFINISPAN_VERSION/infinispan-server-$INFINISPAN_VERSION.zip

# Labels
LABEL name="Infinispan Server" \
      version="$INFINISPAN_VERSION" \
      release="$INFINISPAN_VERSION" \
      architecture="x86_64" \
      io.k8s.description="Provides a scalable in-memory distributed database designed for fast access to large volumes of data." \
      io.k8s.display-name="Infinispan Server" \
      io.openshift.expose-services="8080:http,11222:hotrod" \
      io.openshift.tags="datagrid,java,jboss" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i/bin"

# Download and extract the Infinispan Server
USER root

ENV HOME /opt/jboss/

RUN INFINISPAN_SHA=$(curl $DISTRIBUTION_URL.sha1); curl -o /tmp/server.zip $DISTRIBUTION_URL && sha1sum /tmp/server.zip | grep $INFINISPAN_SHA \
    && unzip -q /tmp/server.zip -d $HOME && mv $HOME/infinispan-server-* $HOME/infinispan-server && rm /tmp/server.zip \ 
    && chown -R 1000.0 /opt/jboss/infinispan-server/ \
    && chmod -R g+rw /opt/jboss/infinispan-server/ \
    && find /opt/jboss/infinispan-server/ -type d -exec chmod g+x {} +

USER 1000

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin
COPY is_healthy.sh /usr/local/bin
COPY is_running.sh /usr/local/bin
# S2I Scripts
COPY .s2i /usr/local/s2i

ENTRYPOINT ["docker-entrypoint.sh"]

# Expose Infinispan server  ports 
EXPOSE 7600 8080 8181 8888 9990 11211 11222 57600
