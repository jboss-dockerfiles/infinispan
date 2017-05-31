#!/bin/bash

SERVER_CONTAINER_ID=""

function pre_build_cleanup {
  echo "==== Pre build clean up (just in case some rubbish was left by the previous build) ===="
  sudo docker rmi -f infinispan-server infinispan-modules
}

function build_images {
  echo "==== Building images ===="
  sudo docker build --no-cache --force-rm -t infinispan-server ../server
  sudo docker build --no-cache --force-rm -t infinispan-modules ../wildfly-modules
}

function start_server {
  echo "==== Starting the server ===="
  SERVER_CONTAINER_ID=`sudo docker run -d --name infinispan-server-ci infinispan-server -Djboss.default.jgroups.stack=tcp`
  if [ -z "$SERVER_CONTAINER_ID" ]; then
    echo "Could not create the container"
    exit 1
  fi
}

function wait_for_server_start {
  echo "==== Waiting for server start ===="
  for i in `seq 1 120`;
  do
    sleep 1s
    echo "Checking logs..."
    sudo docker logs $SERVER_CONTAINER_ID | grep -i "started in"
    if [ $? -eq 0 ]; then
      echo "Server started successfully"
      return
    fi
  done
}

function stop_server {
  echo "==== Killing server ===="
  sudo docker kill infinispan-server-ci
}

function cleanup {
  echo "==== Deleting build results ===="
  sudo docker rm infinispan-server-ci
  sudo docker rmi infinispan-server
  sudo docker rmi infinispan-modules
}

pre_build_cleanup
build_images
start_server
wait_for_server_start
stop_server
cleanup
