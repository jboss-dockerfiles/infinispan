#!/bin/bash

set -x

TEST_RESULT=0
IMAGE_INSIDE_OPENSHIFT=""
OPENSHIFT_COMPONENT_NAME=infinispan-ci-test

OSE_MAIN_VERSION=v3.6.0
OSE_SHA1_VERSION=c4dd4cf

function download_oc_client {
  echo "==== Installing OC Client ===="
  if [ -f ./oc ]; then
    echo "oc client installed"
  else
    wget -q -N https://github.com/openshift/origin/releases/download/$OSE_MAIN_VERSION/openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
    tar -zxf openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
    cp openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit/oc .
    rm -rf openshift-origin-client-tools-$OSE_MAIN_VERSION+$OSE_SHA1_VERSION-linux-64bit
    rm -rf openshift-origin-client-tools-$OSE_MAIN_VERSION-$OSE_SHA1_VERSION-linux-64bit.tar.gz
  fi
}

function start_cluster {
  echo "==== Starting up cluster ===="
  ./oc cluster up
}

function wait_for_ispn() {
  until `./oc exec -t $(get_pod) -- /opt/jboss/infinispan-server/bin/ispn-cli.sh -c ':read-attribute(name=server-state)' | grep -q running`; do
    sleep 3
    echo "Waiting for the server to start..."
  done
}

function get_pod {
 local pod=$(./oc get pods --selector=app=$OPENSHIFT_COMPONENT_NAME | grep Running | tail -n 1 | awk '{print $1}')
 echo $pod
}

function add_building_permission {
  echo "==== Adding image push permissions ===="
  ./oc adm policy add-role-to-user system:registry developer
  ./oc adm policy add-role-to-user admin developer -n myproject
  ./oc adm policy add-role-to-user system:image-builder developer
}

function create_application {
  echo "==== Creating Infinispan application ===="
  ./oc new-app $OPENSHIFT_COMPONENT_NAME \
      --docker-image="$IMAGE_INSIDE_OPENSHIFT" \
      -e "APP_USER=user" \
      -e "APP_PASS=changeme"
  wait_for_ispn
}

function expose_route {
  echo "==== Exposing route to local application ===="
  ./oc expose svc/$OPENSHIFT_COMPONENT_NAME
  sleep 10s
}

function perform_test_via_rest {
  echo "==== Performing REST test ===="
  ISPN_IP=`./oc describe svc/$OPENSHIFT_COMPONENT_NAME | grep IP: | awk '{print $2}'`
  curl -v -u user:changeme -X POST -H 'Content-type: text/plain' -d 'test' http://$ISPN_IP:8080/rest/default/1
  VALUE_RETURNED=$(curl -v -u user:changeme -X GET -H 'Accept: text/plain' http://$ISPN_IP:8080/rest/default/1)
  if [ $VALUE_RETURNED == 'test' ]; then
    echo "REST test Passed"
    TEST_RESULT=0
  else
    echo "REST test Failed"
    TEST_RESULT=1
  fi
}

function perform_negative_test_via_rest {
  echo "==== Performing negative REST test ===="
  ISPN_IP=`./oc describe svc/$OPENSHIFT_COMPONENT_NAME | grep IP: | awk '{print $2}'`
  CODE_RETURNED=$(curl -s -o /dev/null -H 'Accept: text/plain' -w "%{http_code}" http://$ISPN_IP:8080/rest/default/1)
  if [ $CODE_RETURNED == '401' ]; then
    echo "REST test Passed"
    TEST_RESULT=0
  else
    echo "REST test Failed. REST server returned $CODE_RETURNED but was expected 401"
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
  if [ ! -z "$IMAGE_INSIDE_OPENSHIFT" ]; then
    sudo docker rmi $IMAGE_INSIDE_OPENSHIFT
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
  sudo docker login -u $(./oc whoami) -p $(./oc whoami -t) ${REGISTRY_IP}:5000
  sudo docker push ${IMAGE}
  IMAGE_INSIDE_OPENSHIFT=$IMAGE
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
perform_negative_test_via_rest

exit $TEST_RESULT
