# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

# Set the INFINISPAN_SERVER_HOME env variable
ENV INFINISPAN_SERVER_HOME /opt/jboss/infinispan-server

# Set the INFINISPAN_VERSION env variable
ENV INFINISPAN_VERSION 9.0.0.Alpha3

ENV MGMT_USER admin

ENV MGMT_PASS admin

# Server download location
ENV DISTRIBUTION_URL https://repo1.maven.org/maven2/org/infinispan/server/infinispan-server-build/$INFINISPAN_VERSION/infinispan-server-build-$INFINISPAN_VERSION.zip

# Download and extract the Infinispan Server
RUN INFINISPAN_SHA=$(curl $DISTRIBUTION_URL.sha1); curl -o /tmp/server.zip $DISTRIBUTION_URL && sha1sum /tmp/server.zip | grep $INFINISPAN_SHA \
    && unzip -q /tmp/server.zip -d $HOME && mv $HOME/infinispan-server-* $HOME/infinispan-server && rm /tmp/server.zip

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin

ENTRYPOINT ["docker-entrypoint.sh"]

# Expose Infinispan server  ports 
EXPOSE 7600 8080 8181 9990 11211 11222 57600
