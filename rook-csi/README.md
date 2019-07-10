Note as of June 27, 2019 changes to the ceph-csi plugin and Rook have broken this repo.

The saved manifests in this directory don't work correctly any longer; you can check out the latest version of the Rook repo and use the equivalent manifests from the source tree.  That will get the deploy working, the finalize script needs changed, so you'll have to use the docs and perform the finalize steps manually.

I'll get this updated shortly, plan is to:
1. Point install scripts to src repo instead of using a copy
   This is slightly annoying becuase I typically like to modify the deployment.  I don't want rook/ceph greedily consuming all my disks and i personally have zero interest in cephfs which is on by default.

2. Update the finalize script  


# July 9, 2019

Pushed quite a few updates, rook has changed considerably and things were very broken; there's still something not quite write with my admin_key it seems.. need to get to the bottom of that, but fetching on the operator pod with `ceph auth get client.admin 2>&1 |grep "key = " |awk '{print  $3'} |xargs echo -n > /tmp/key` and then create secrets with:  `kubectl create secret generic ceph-admin-secret --from-file=/tmp/key --namespace=kube-system --type=kubernetes.io/rbd`  seems to work.
