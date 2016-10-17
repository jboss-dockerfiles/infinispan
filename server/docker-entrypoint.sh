#!/bin/bash

set -e

BIND=$(hostname -i)
SERVER=/opt/jboss/infinispan-server
LAUNCHER=$SERVER/bin/standalone.sh
CONFIG=clustered
BIND_OPTS="-Djboss.bind.address.management=0.0.0.0 -Djgroups.join_timeout=1000 -Djgroups.bind_addr=$BIND -Djboss.bind.address=$BIND"

if [ "$1" = 'domain-controller' ]
then
  shift;
  $SERVER/bin/add-user.sh -u $MGMT_USER -p $MGMT_PASS
  LAUNCHER=$SERVER/bin/domain.sh
  exec $LAUNCHER --host-config host-master.xml $BIND_OPTS "$@"
elif [ "$1" = 'host-controller' ]
then
  shift;
  LAUNCHER=$SERVER/bin/domain.sh
  BASE=$(echo -n $MGMT_USER | base64) && sed -i "s/\<secret value=.*/secret value=\"$BASE\" \/>/" $SERVER/domain/configuration/host-slave.xml
  SLAVE_FILE=$SERVER/domain/configuration/host-slave.xml
  sed -e "/<remote/ {/username/! s/remote/remote username=\"$MGMT_USER\"/}" -i $SLAVE_FILE
  sed -e "/<remote.*username/ s/\(username\)=\"[^\"]*\"/username=\"$MGMT_USER\"/" -i $SLAVE_FILE
  exec $LAUNCHER --host-config host-slave.xml -Djboss.domain.master.address=$DC_PORT_9990_TCP_ADDR $BIND_OPTS "$@"
else
  if [ $# -ne 0 ] && [ -f $SERVER/standalone/configuration/$1.xml ]; then CONFIG=$1; shift; fi
  exec $LAUNCHER -c $CONFIG.xml $BIND_OPTS "$@"
fi

