#!/bin/bash
set -eux

PLATFORM=${1:-kubectl}  # Defaults to deploying on plain Kubernetes, specify `oc` for openshift >= 4.1
if [ $PLATFORM != "kubectl" ] && [ $PLATFORM != "oc" ] 
then
  echo "You specified an invalid platform ($PLATFORM), you can either use the default (kubectl, or specify \'oc\' for OpenShift)"
  exit
fi

echo "Deploying CEPH Cluster using $PLATFORM..."
kubectl apply -f manifests/common.yaml
kubectl apply -f manifests/csi-rbac.yaml
kubectl apply -f manifests/operator-with-csi.yaml
kubectl apply -f manifests/cluster.yaml
kubectl create -f manifests/toolbox.yaml
