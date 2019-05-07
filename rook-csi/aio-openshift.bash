#!/bin/bash
set -eux
#export KUBECONFIG=/home/jgriffith/go/src/github.com/openshift/installer/auth/kubeconfig
#oc login -u system:admin
oc apply -f manifests/common.yaml
oc apply -f manifests/csi-rbac.yaml
oc apply -f manifests/operator-openshift-with-csi.yaml
oc apply -f manifests/cluster.yaml
oc create -f manifests/toolbox.yaml
