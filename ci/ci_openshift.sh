#!/bin/bash

TEST_RESULT=0
IMAGE_TO_DELETE=""
OPENSHIFT_COMPONENT_NAME=infinispan-ci-test

OSE_MAIN_VERSION=v1.3.0-alpha.3
OSE_SHA1_VERSION=7998ae4

function download_oc_client {
  echo "==== Installing OC Client ===="
  if [ -f ./oc ]; then
    echo "oc client installed"
  else
    wget -q -N https://github.com/openshift/origin/releases/download/$OSE_MAIN_VERSION/openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
    tar -zxf openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
    cp openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit/oc .
    rm -rf openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit
    rm -rf openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
  fi
}

function start_cluster {
  echo "==== Starting up cluster ===="
  ./oc cluster up
}

function add_building_permission {
  echo "==== Adding image push permissions ===="
  ./oc adm policy add-role-to-user system:registry developer
  ./oc adm policy add-role-to-user admin developer -n myproject
  ./oc adm policy add-role-to-user system:image-builder developer
}

function create_application {
  echo "==== Creating Infinispan application ===="
  ./oc new-app $OPENSHIFT_COMPONENT_NAME
  for i in `seq 1 180`;
  do
    sleep 1s
    echo "Checking logs..."
    ./oc get pods --selector=app=$OPENSHIFT_COMPONENT_NAME | tail -n 1 | grep Running
    if [ $? -eq 0 ]; then
      echo "Server started successfully"
      return
    fi
  done
}

function expose_route {
  echo "==== Exposing route to local application ===="
  ./oc expose svc/$OPENSHIFT_COMPONENT_NAME
  sleep 10s
}

function perform_test_via_rest {
  echo "==== Performing REST test ===="
  ISPN_IP=`./oc describe svc/$OPENSHIFT_COMPONENT_NAME | grep IP: | awk '{print $2}'`
  curl -X POST -H 'Content-type: text/plain' -d 'test' http://$ISPN_IP:8080/rest/default/1
  VALUE_RETURNED=$(curl -X GET -H 'Content-type: text/plain' http://$ISPN_IP:8080/rest/default/1)
  if [ $VALUE_RETURNED == 'test' ]; then
    echo "REST test Passed"
    TEST_RESULT=0
  else
    echo "REST test Failed"
    TEST_RESULT=1
  fi
}

function login_as_admin {
  echo "==== Logging in as admin ===="
  ./oc login -u system:admin
}

function login_as_developer {
  echo "==== Logging in as developer ===="
  ./oc login -u developer -p developer
}

function stop_cluster {
  echo "==== Killing the cluster ===="
  ./oc cluster down
  if [ ! -z "$IMAGE_TO_DELETE" ]; then
    sudo docker rmi $IMAGE_TO_DELETE
  fi
}

function build_images {
  echo "==== Building images ===="
  login_as_admin
  ./oc project default
  REGISTRY_IP=`./oc get svc/docker-registry -o yaml | grep clusterIP: | awk '{print $2}'`
  IMAGE="${REGISTRY_IP}:5000/myproject/$OPENSHIFT_COMPONENT_NAME"
  login_as_developer
  sudo docker build --no-cache --force-rm -t $IMAGE ../server
  sudo docker login -u $(./oc whoami) -e nobody@redhat.com -p $(./oc whoami -t) ${REGISTRY_IP}:5000
  sudo docker push ${IMAGE}
  IMAGE_TO_DELETE=$IMAGE
}

trap stop_cluster EXIT SIGTERM

download_oc_client
start_cluster
login_as_admin
add_building_permission
login_as_developer
build_images
create_application
expose_route
perform_test_via_rest

exit $TEST_RESULT