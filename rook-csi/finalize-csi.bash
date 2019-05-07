#!/bin/bash
set -eux

PLATFORM=${1:-kubectl}  # Defaults to deploying on plain Kubernetes, specify `oc` for openshift >= 4.1
if [ $PLATFORM != "kubectl" ] && [ $PLATFORM != "oc" ] 
then
  echo "You specified an invalid platform ($PLATFORM), you can either use the default (kubectl, or specify \'oc\' for OpenShift)"
  exit
fi

cat << EOF | kubectl create -f -
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: rbd
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
EOF

(pod=$(kubectl get pod  -n rook-ceph -l app=rook-ceph-operator  -o jsonpath="{.items[0].metadata.name}"); kubectl exec -ti -n rook-ceph ${pod} -- bash -c "ceph -c /var/lib/rook/rook-ceph/rook-ceph.config auth get-or-create-key client.kubernetes mon \"allow profile rbd\" osd \"profile rbd pool=rbd\"")

admin_key=$(pod=$(kubectl get pod  -n rook-ceph -l app=rook-ceph-operator  -o jsonpath="{.items[0].metadata.name}"); kubectl exec -ti -n rook-ceph ${pod} -- bash -c "ceph auth get-key client.admin -c /var/lib/rook/rook-ceph/rook-ceph.config | base64")

kubernetes_key=$(pod=$(kubectl get pod  -n rook-ceph -l app=rook-ceph-operator  -o jsonpath="{.items[0].metadata.name}"); kubectl exec -ti -n rook-ceph ${pod} -- bash -c "ceph auth get-key client.kubernetes -c /var/lib/rook/rook-ceph/rook-ceph.config | base64")

cat << EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
data:
  # Key value corresponds to a user name defined in Ceph cluster
  admin: ${admin_key}
  # Key value corresponds to a user name defined in Ceph cluster
  kubernetes: ${kubernetes_key}
  # if monValueFromSecret is set to "monitors", uncomment the
  # following and set the mon there
  #monitors: BASE64-ENCODED-Comma-Delimited-Mons
EOF

OUT=$(kubectl get service -n rook-ceph |  grep rook-ceph-mon | awk '{ print $3;  }')
IFS='
'
count=0
for i in $OUT
do
        if [ $count == 0 ]; then
                MONA=$i
        elif [ $count  == 1 ]; then
                MONB=$i
        elif [ $count == 2 ]; then
                MONC=$i
        else
                echo "I only expect 3 mons for now"
        fi
        let count=count+1
done

cat << EOF | kubectl create -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd
provisioner: rbd.csi.ceph.com
parameters:
    # Comma separated list of Ceph monitors
    # if using FQDN, make sure csi plugin's dns policy is appropriate.
    monitors: $MONA:6789,$MONB:6789,$MONC:6789  

    # if "monitors" parameter is not set, driver to get monitors from same
    # secret as admin/user credentials. "monValueFromSecret" provides the
    # key in the secret whose value is the mons
    #monValueFromSecret: "monitors"
    
    # Ceph pool into which the RBD image shall be created
    pool: rbd

    # RBD image format. Defaults to "2".
    imageFormat: "2"

    # RBD image features. Available for imageFormat: "2". CSI RBD currently supports only `layering` feature.
    imageFeatures: layering
    
    # The secrets have to contain Ceph admin credentials.
    csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
    csi.storage.k8s.io/provisioner-secret-namespace: default
    csi.storage.k8s.io/node-publish-secret-name: csi-rbd-secret
    csi.storage.k8s.io/node-publish-secret-namespace: default

    # Ceph users for operating RBD
    adminid: admin
    userid: kubernetes
    # uncomment the following to use rbd-nbd as mounter on supported nodes
    #mounter: rbd-nbd
reclaimPolicy: Delete
EOF
