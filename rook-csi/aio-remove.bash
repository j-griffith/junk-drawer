#!/bin/bash
set -eux

PLATFORM=${1:-kubectl}  # Defaults to deploying on plain Kubernetes, specify `oc` for openshift >= 4.1
if [ $PLATFORM != "kubectl" ] && [ $PLATFORM != "oc" ] 
then
  echo "You specified an invalid platform ($PLATFORM), you can either use the default (kubectl, or specify \'oc\' for OpenShift)"
  exit
fi

echo "Deploying CEPH Cluster using $PLATFORM..."
kubectl delete -f manifests/common.yaml
kubectl delete -f manifests/csi-rbac.yaml
kubectl delete -f manifests/operator-with-csi.yaml
kubectl delete -f manifests/cluster.yaml
kubectl delete -f manifests/toolbox.yaml
