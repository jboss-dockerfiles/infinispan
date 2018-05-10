#!/bin/bash

SERVER_CONTAINER_ID=""
TEST_MGMT_USER=user1
TEST_MGMT_PASS=pass1

function pre_build_cleanup {
  echo "==== Pre build clean up (just in case some rubbish was left by the previous build) ===="
  sudo docker rm -f hc dc infinispan-server-ci
  sudo docker rmi -f infinispan-server
}

function build_images {
  echo "==== Building images ===="
  sudo docker build --no-cache --force-rm -t infinispan-server ../server || die "Error building the image"
}

function start_server {
  echo "==== Starting the server ===="
  SERVER_CONTAINER_ID=`sudo docker run -d --name infinispan-server-ci -e "APP_USER=user" -e "APP_PASS=changeme" infinispan-server -Djboss.default.jgroups.stack=tcp`
  [[ -z "$SERVER_CONTAINER_ID" ]] && die "Could not create the container"
}

function start_domain_controller {
  echo "==== Starting domain controller ===="
  SERVER_CONTAINER_ID=`sudo docker run -d --name dc -e "MGMT_USER=$TEST_MGMT_USER" -e "MGMT_PASS=$TEST_MGMT_PASS" infinispan-server domain-controller`
  [[ -z "$SERVER_CONTAINER_ID" ]] && die "Could not create the container"
}

function start_host_controller {
  echo "==== Starting host controller ===="
  SERVER_CONTAINER_ID=`sudo docker run -d --name hc -e "MGMT_USER=$TEST_MGMT_USER" -e "MGMT_PASS=$TEST_MGMT_PASS" --link dc:dc -it infinispan-server host-controller`
  [[ -z "$SERVER_CONTAINER_ID" ]] && die "Could not create the container"
}

function die () {
    echo $1
    exit 1
}

function check_domain {
  echo "==== Checking domain cluster ===="
  MEMBERS=$(docker exec -t dc /opt/jboss/infinispan-server/bin/ispn-cli.sh -c ":read-children-names(child-type=host)")
  HOST_CONTROLLER=$(docker exec hc hostname)
  [[ ${MEMBERS} =~ "master" ]] || die  "master not found in domain"
  [[ ${MEMBERS} =~ $HOST_CONTROLLER ]] || die "Host controller not found in domain"
  echo "==== Domain OK ===="
}

function wait_for_server_start {
  echo "==== Waiting for server start ===="
  for i in `seq 1 120`;
  do
    sleep 1s
    echo "Checking logs..."
    sudo docker logs ${SERVER_CONTAINER_ID} | grep -i "started in"
    if [ $? -eq 0 ]; then
      echo "Server started successfully"
      return
    fi
  done
  echo "Server failed to start"
  exit 1
}

function stop_server {
  echo "==== Killing server ===="
  sudo docker kill infinispan-server-ci
}

function stop_domain_cluster {
  sudo docker kill dc
  sudo docker kill hc
}

function cleanup {
  echo "==== Deleting build results ===="
  sudo docker rm infinispan-server-ci
  sudo docker rmi infinispan-server
  sudo docker rm dc
  sudo docker rm hc
}

pre_build_cleanup
build_images
start_server
wait_for_server_start
stop_server
start_domain_controller
wait_for_server_start
start_host_controller
wait_for_server_start
check_domain
stop_domain_cluster
cleanup
