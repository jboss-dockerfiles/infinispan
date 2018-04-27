#!/bin/bash



# S2I build scripts do not override Docker Entrypoints (see https://github.com/openshift/source-to-image/issues/475#issuecomment-215891632),
# thus we need to check whether or not we are running a build or a standard container.
# This line is commented intentionally, it is very useful for debugging.
# echo "Entry point arguments: $@"
if [[ $@ == *"/usr/local/s2i/bin/assemble"* ]]
then
    echo "---> Performing S2I build... Skipping server startup"
    exec "$@"
    exit $?
fi

set -e

is_not_empty() {
    local var=$1
    [[ -n $var ]]
}

generate_user_or_password() {
    echo $(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
}

addMgmtUser() {
  local usr=$MGMT_USER
  local pass=$MGMT_PASS

  if is_not_empty $usr && is_not_empty $pass; then
    $SERVER/bin/add-user.sh -u $usr -p $pass > /dev/null 2>&1 
  else
    usr=$(generate_user_or_password)
    pass=$(generate_user_or_password)
    printBorder
    printLine " No management user and/or password provided."
    printLine " Management user and password has been generated."
    printLine " Management user: $usr"
    printLine " Management password: $pass"
    printLine
    printLine " You can provide management user and password details via environment"
    printLine " variables."
    printLine
    printLine " Docker run example:"
    printLine "   docker run ... -e \"MGMT_USER=user\" -e \"MGMT_PASS=changeme\" ..."
    printLine
    printLine " Dockerfile example:"
    printLine "   ENV MGMT_USER admin"
    printLine "   ENV MGMT_PASS admin"
    printLine 
    printLine " Kubernetes Example:"
    printLine "   spec:"
    printLine "     containers:"
    printLine "     - args:"
    printLine "       image: jboss/infinispan-server:..."
    printLine "       ..."
    printLine "       env:"
    printLine "       - name: MGMT_USER"
    printLine "           value: admin"
    printLine "         - name: MGMT_PASS"
    printLine "           value: admin"
    printLine 
    printLine " OpenShift client example:"
    printLine "     oc new-app ... -e MGMT_USER=user -e MGMT_PASS=changeme ..."
    printBorder
    $SERVER/bin/add-user.sh -u $usr -p $pass > /dev/null 2>&1
  fi
}

printLine() {
  format='# %-76s #\n'
  printf "$format" "$1"
}

printBorder() {
  printf '#%.0s' {1..80}
  printf "\n"
}

addAppUser()  {
  local usr=$APP_USER
  local pass=$APP_PASS
  local roles=$APP_ROLES
  if is_not_empty $usr && is_not_empty $pass; then
    if is_not_empty $roles; then
      $SERVER/bin/add-user.sh -a -u $usr -p $pass -g $roles > /dev/null 2>&1
    else
      $SERVER/bin/add-user.sh -a -u $usr -p $pass > /dev/null 2>&1
    fi
  else
    usr=$(generate_user_or_password)
    pass=$(generate_user_or_password)
    printBorder
    printLine "No application user and/or password provided."
    printLine "Application user and password has been generated."
    printLine "Application user: $usr"
    printLine "Application password: $pass"
    printLine
    printLine "You can provide application user and password details via environment"
    printLine "variables."
    printLine
    printLine "Docker run example:"
    printLine "docker run ... -e \"APP_USER=user\" -e \"APP_PASS=changeme\"  ..."
    printLine
    printLine "Dockerfile example:"
    printLine " ENV APP_USER user"
    printLine " ENV APP_PASS changeme"
    printLine
    printLine "Kubernetes example:"
    printLine "     spec:"
    printLine "       containers:"
    printLine "       - args:"
    printLine "         image: jboss/infinispan-server:..."
    printLine "         ..."
    printLine "         env:"
    printLine "         - name: APP_USER"
    printLine "           value: user"
    printLine "         - name: APP_PASS"
    printLine "           value: changeme"
    printLine
    printLine " OpenShift client example:"
    printLine "     oc new-app ... -e APP_USER=user -e APP_PASS=changeme ..."
    printBorder
    $SERVER/bin/add-user.sh -a -u $usr -p $pass > /dev/null 2>&1
  fi
}

mgmtUserPassRequired()  {

 printBorder
 printLine "Specifying management user is required for domain mode"
 printLine  
 printLine "  docker run ... -e \"MGMT_USER=user\" -e \"MGMT_PASS=changeme\" ..."
 printBorder
 exit 1

}

checkIfUserExistsForDomainMode()  {
  local usr=$MGMT_USER
  local pass=$MGMT_PASS

  if [ "$RUN_TYPE" != "STANDALONE" ] && ([ "x$usr" = "x" ] || [ "x$pass" = "x" ]); 
   then
       mgmtUserPassRequired
   fi
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
JAVA_OPTS="-Djava.net.preferIPv4Stack=true -XX:+DisableExplicitGC -Djboss.modules.system.pkgs=org.jboss.byteman,org.jboss.logmanager.LogManager"
PERCENT_OF_MEMORY_FOR_MX=50

for i in "$@"
do
case $1 in
    domain-controller)
    RUN_TYPE='DOMAIN_CONTROLLER'
    shift
    ;;
    host-controller)
    RUN_TYPE='HOST_CONTROLLER'
    shift
    ;;
    -h|--help)
    printBorder
    printLine " This script is responsible for setting basic configuration for running "
    printLine " Infinispan Server in Docker"
    printLine " Usage: docker-entrypoint.sh [profile] [options]"
    printLine 
    printLine " Where [profile] is:"
    printLine "  domain-controller"
    printLine "    Creates managment user and starts a master controller process"
    printLine "  host-controller"
    printLine "    Starts a slave instance and connects to a domain controller"
    printLine "  standalone"
    printLine "    Starts a non-clustered server, based on standalone.xml configuration"
    printLine "  [clustered.xml|cloud.xml|file.xml|cloud|file|-c standalone.xml]"
    printLine "    Starts the server with another xml configuration"
    printLine
    printLine " Available [options]:"
    printLine "  [-n|--no-container-settings]"
    printLine "    Omits memory and CPU settings for the container"
    printLine " -ap pass -au user [-ar roles]"
    printLine "    Creates application user with specified password and roles"
    printLine " -mp pass -mu user [other options]"
    printLine "    Creates management user with specified password"
    printLine
    printLine "Examples:"
    printLine "docker-entrypoint.sh -c clustered.xml -Djboss.default.jgroups.stack=kubernetes"
    printLine "docker-entrypoint.sh clustered.xml -Djboss.default.jgroups.stack=kubernetes"
    printLine "docker-entrypoint.sh clustered -Djboss.default.jgroups.stack=kubernetes"
    printLine "docker-entrypoint.sh -n clustered -Djboss.default.jgroups.stack=kubernetes"
    printBorder
    exit 1
    ;;
    -n|--no-container-settings)
    CONTAINER_SETTINGS="false"
    shift
    ;;
    -au|--application-user)
    shift
    APP_USER="$1"
    shift
    ;;
    -ap|--application-password)
    shift
    APP_PASS="$1"
    shift
    ;;
    -ar|--application-roles)
    shift
    APP_ROLES="$1"
    shift
    ;;
    -mu|--management-user)
    shift
    MGMT_USER="$1"
    shift
    ;;
    -mp|--management-password)
    shift
    MGMT_PASS="$1"
    shift
    ;;
    -c)
    # -c configuration.xml, so we need to shift the -c
    shift
    SERVER_CONFIGURATION="$1"
    shift
    ;;
    *)
    if [ -z "$1" ]
    then
      break
    else
      if [ -f "$SERVER/standalone/configuration/$1.xml" ]
      then
        SERVER_CONFIGURATION="$1.xml"
      elif [ -f "$SERVER/standalone/configuration/$1" ]
      then
        SERVER_CONFIGURATION="$1"
      else
        SERVER_OPTIONS="$SERVER_OPTIONS $1"
      fi
    fi
    shift
    ;;
esac
done

checkIfUserExistsForDomainMode
addAppUser
addMgmtUser

if [ "$CONTAINER_SETTINGS" == "true" ]
then
  MEMORY_LIMIT="$(max_memory)"
  if [ "x$MEMORY_LIMIT" != x ]; then
      if echo "${JAVA_OPTIONS}" | grep -q -- "-Xmx"; then
        echo "Xmx explicitly set, skipping auto-correction"
      else
        # https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-default-options#L44
        MX=$(echo "${MEMORY_LIMIT} $PERCENT_OF_MEMORY_FOR_MX 1048576" | awk '{printf "%d\n" , ($1*$2)/(100*$3) + 0.5}')
        # Readiness/liveness probes
        MX=$((${MX}-32))
        JAVA_OPTS="$JAVA_OPTS -Xmx${MX}m -Xms${MX}m"
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
  LAUNCHER=$SERVER/bin/domain.sh
  exec $LAUNCHER --host-config host-master.xml $BIND_OPTS $SERVER_OPTIONS
elif [ "$RUN_TYPE" == "HOST_CONTROLLER" ]
then
  LAUNCHER=$SERVER/bin/domain.sh
  BASE=$(echo -n $MGMT_PASS | base64) && sed -i "s/\<secret value=.*/secret value=\"$BASE\" \/>/" $SERVER/domain/configuration/host-slave.xml
  SLAVE_FILE=$SERVER/domain/configuration/host-slave.xml
  sed -e "/<remote/ {/username/! s/remote/remote username=\"$MGMT_USER\"/}" -i $SLAVE_FILE
  sed -e "/<remote.*username/ s/\(username\)=\"[^\"]*\"/username=\"$MGMT_USER\"/" -i $SLAVE_FILE
  exec $LAUNCHER --host-config host-slave.xml -Djboss.domain.master.address=$DC_PORT_9990_TCP_ADDR $BIND_OPTS $SERVER_OPTIONS
else
  exec $LAUNCHER "-c" $SERVER_CONFIGURATION $BIND_OPTS $SERVER_OPTIONS
fi
