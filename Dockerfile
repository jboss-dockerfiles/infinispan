# Use latest jboss/base-jdk:7 image as the base
FROM jboss/base-jdk:7

# Set the INFINISPAN_SERVER_HOME env variable
ENV INFINISPAN_SERVER_HOME /opt/jboss/infinispan-server

# Set the INFINISPAN_SERVER_VERSION env variable
ENV INFINISPAN_SERVER_VERSION 7.0.0.CR1

# Download and unzip Infinispan server
RUN cd $HOME && curl http://downloads.jboss.org/infinispan/$INFINISPAN_SERVER_VERSION/infinispan-server-$INFINISPAN_SERVER_VERSION-bin.zip | bsdtar -xf - && mv $HOME/infinispan-server-$INFINISPAN_SERVER_VERSION $HOME/infinispan-server && chmod +x /opt/jboss/infinispan-server/bin/standalone.sh

# Expose Infinispan server  ports 
EXPOSE 8080 8181 9990 11211 11222 

# Run Infinispan server and bind to all interface
CMD ["/opt/jboss/infinispan-server/bin/standalone.sh", "-b", "0.0.0.0"]
