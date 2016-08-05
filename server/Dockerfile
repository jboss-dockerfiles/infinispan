# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

# Set the INFINISPAN_SERVER_HOME env variable
ENV INFINISPAN_SERVER_HOME /opt/jboss/infinispan-server

# Set the INFINISPAN_VERSION env variable
ENV INFINISPAN_VERSION 9.0.0.Alpha4

ENV MGMT_USER admin

ENV MGMT_PASS admin

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Server download location
ENV DISTRIBUTION_URL https://repo1.maven.org/maven2/org/infinispan/server/infinispan-server-build/$INFINISPAN_VERSION/infinispan-server-build-$INFINISPAN_VERSION.zip

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

ENTRYPOINT ["docker-entrypoint.sh"]

# Expose Infinispan server  ports 
EXPOSE 7600 8080 8181 8888 9990 11211 11222 57600
