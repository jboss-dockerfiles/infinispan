#!/bin/sh

JAVA_OPTS=-Xmx16m /opt/jboss/infinispan-server/bin/ispn-cli.sh -c --controller=$(hostname -i):9990 --controller=$(hostname -i):9990 '/:read-attribute(name=server-state)' | awk '/result/{gsub("\"", "", $3); print $3}' | grep running

exit $?
