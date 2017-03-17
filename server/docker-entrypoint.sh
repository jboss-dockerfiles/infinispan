#!/bin/bash

set -e

addMgmtUser() {
  $SERVER/bin/add-user.sh -u $MGMT_USER -p $MGMT_PASS
}

addAppUser()  {
  $SERVER/bin/add-user.sh -a -u $APP_USER -p $APP_PASS
}

# Based on https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/container-limits
ceiling() {
  awk -vnumber="$1" -vdiv="$2" '
    function ceiling(x){
      return x%1 ? int(x)+1 : x
    }
    BEGIN{
      print ceiling(number/div)
    }
  '
}

core_limit() {
  local cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"
  local cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
  if [ -r "${cpu_period_file}" ]; then
    local cpu_period="$(cat ${cpu_period_file})"

    if [ -r "${cpu_quota_file}" ]; then
      local cpu_quota="$(cat ${cpu_quota_file})"
      # cfs_quota_us == -1 --> no restrictions
      if [ "x$cpu_quota" != "x-1" ]; then
        ceiling "$cpu_quota" "$cpu_period"
      fi
    fi
  fi
}

max_memory() {
  local max_mem_unbounded="562949953421312"
  local mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
  if [ -r "${mem_file}" ]; then
    local max_mem="$(cat ${mem_file})"
    if [ ${max_mem} -lt ${max_mem_unbounded} ]; then
      echo "${max_mem}"
    fi
  fi
}

BIND=$(hostname -i)
SERVER=/opt/jboss/infinispan-server
LAUNCHER=$SERVER/bin/standalone.sh
CONFIG=clustered
BIND_OPTS="-Djboss.bind.address.management=0.0.0.0 -Djgroups.join_timeout=1000 -Djgroups.bind_addr=$BIND -Djboss.bind.address=$BIND"
RUN_TYPE='STANDALONE'
CONTAINER_SETTINGS="true"
SERVER_OPTIONS=""
SERVER_CONFIGURATION="clustered.xml"
# Xms should always be set: https://developers.redhat.com/blog/2014/07/15/dude-wheres-my-paas-memory-tuning-javas-footprint-in-openshift-part-1/
JAVA_OPTS="-Xms64m -Djava.net.preferIPv4Stack=true"
PERCENT_OF_MEMORY_FOR_MX=70

addAppUser

for i in "$@"
do
case $i in
    domain-controller)
    RUN_TYPE='DOMAIN_CONTROLLER'
    shift
    ;;
    host-controller)
    RUN_TYPE='HOST_CONTROLLER'
    shift
    ;;
    -h|--help)
    echo "######################################################################################"
    echo "# This script is responsible for setting basic                                       #"
    echo "# configuration for running Infinispan Server in Docker                              #"
    echo "#                                                                                    #"
    echo "# Parameters:                                                                        #"
    echo "# docker-entrypoint.sh domain-controller [other options]                             #"
    echo "#     Creates managment user and starts a master controller process                  #"
    echo "# docker-entrypoint.sh host-controller [other options]                               #"
    echo "#     Starts a slave instance and connects to a domain controller                    #"
    echo "# docker-entrypoint.sh host-controller [-n|--no-container-settings] [other options]  #"
    echo "#     Starts a default standalone Server                                             #"
    echo "#     -n|--no-container-settings omits memory and CPU settings for container mode    #"
    echo "#                                                                                    #"
    echo "# Examples:                                                                          #"
    echo "#     docker-entrypoint.sh -c clustered.xml -Djboss.default.jgroups.stack=kubernetes #"
    echo "#     docker-entrypoint.sh clustered.xml -Djboss.default.jgroups.stack=kubernetes    #"
    echo "#     docker-entrypoint.sh clustered -Djboss.default.jgroups.stack=kubernetes        #"
    echo "#     docker-entrypoint.sh -n clustered -Djboss.default.jgroups.stack=kubernetes     #"
    echo "######################################################################################"
    exit 1
    ;;
    -n|--no-container-settings)
    CONTAINER_SETTINGS="false"
    shift
    ;;
    -c)
      # -c configuration.xml, so we need to shift the -c
      shift
      SERVER_OPTIONS="-c $1"
    shift
    ;;
    *)
    if [ -f $SERVER/standalone/configuration/$i.xml ]
    then
      SERVER_CONFIGURATION="$i.xml"
    elif [ -f $SERVER/standalone/configuration/$i ]
    then
      SERVER_CONFIGURATION="$i"
    else
      SERVER_OPTIONS="$SERVER_OPTIONS $i"
    fi
    shift
    ;;
esac
done


if [ "$CONTAINER_SETTINGS" == "true" ]
then
  MEMORY_LIMIT="$(max_memory)"
  if [ "x$MEMORY_LIMIT" != x ]; then
      if echo "${JAVA_OPTIONS}" | grep -q -- "-Xmx"; then
        echo "Xmx explicitly set, skipping auto-correction"
      else
        # https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-default-options#L44
        # Use up to 70% for Xmx. In case of any problems, lower this to 50%.
        MX=$(echo "${MEMORY_LIMIT} $PERCENT_OF_MEMORY_FOR_MX 1048576" | awk '{printf "%d\n" , ($1*$2)/(100*$3) + 0.5}')
        JAVA_OPTS="$JAVA_OPTS -Xmx${MX}m"
        export JAVA_OPTS
      fi
  fi

  CPU_LIMIT="$(core_limit)"
  if [ "x$CPU_LIMIT" != x ]; then
      JAVA_OPTS="$JAVA_OPTS -XX:ParallelGCThreads=$CPU_LIMIT -XX:ConcGCThreads=$CPU_LIMIT -Djava.util.concurrent.ForkJoinPool.common.parallelism=$CPU_LIMIT"         
      export JAVA_OPTS
  fi
fi

if [ "$RUN_TYPE" = "DOMAIN_CONTROLLER" ]
then
  addMgmtUser
  LAUNCHER=$SERVER/bin/domain.sh
  exec $LAUNCHER --host-config host-master.xml $BIND_OPTS $SERVER_OPTIONS
elif [ "$RUN_TYPE" == "HOST_CONTROLLER" ]
then
  LAUNCHER=$SERVER/bin/domain.sh
  BASE=$(echo -n $MGMT_USER | base64) && sed -i "s/\<secret value=.*/secret value=\"$BASE\" \/>/" $SERVER/domain/configuration/host-slave.xml
  SLAVE_FILE=$SERVER/domain/configuration/host-slave.xml
  sed -e "/<remote/ {/username/! s/remote/remote username=\"$MGMT_USER\"/}" -i $SLAVE_FILE
  sed -e "/<remote.*username/ s/\(username\)=\"[^\"]*\"/username=\"$MGMT_USER\"/" -i $SLAVE_FILE
  exec $LAUNCHER --host-config host-slave.xml -Djboss.domain.master.address=$DC_PORT_9990_TCP_ADDR $BIND_OPTS $SERVER_OPTIONS
else
  exec $LAUNCHER "-c" $SERVER_CONFIGURATION $BIND_OPTS $SERVER_OPTIONS
fi
