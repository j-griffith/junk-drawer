#!/usr/bin/env bash
set +e
kubectl patch cdi cdi --type=json -p '[{ "op": "remove", "path": "/metadata/finalizers" }]'
set -e

labels=("operator.kubevirt.io" "operator.cdi.kubevirt.io" "kubevirt.io" "cdi.kubevirt.io")

namespaces=(default cdi)
managed_namespaces=(kubevirt cdi)

for i in ${namespaces[@]}; do
    for label in ${labels[@]}; do
        kubectl -n ${i} delete deployment -l ${label}
        kubectl -n ${i} delete ds -l ${label}
        kubectl -n ${i} delete rs -l ${label}
        kubectl -n ${i} delete pods -l ${label}
        kubectl -n ${i} delete services -l ${label}
        kubectl -n ${i} delete pvc -l ${label}
        kubectl -n ${i} delete rolebinding -l ${label}
        kubectl -n ${i} delete roles -l ${label}
        kubectl -n ${i} delete serviceaccounts -l ${label}
        kubectl -n ${i} delete configmaps -l ${label}
        kubectl -n ${i} delete secrets -l ${label}
        kubectl -n ${i} delete jobs -l ${label}
        kubectl -n ${i} delete replicaset -l ${label}
    done
  done

# Namespaced resources
for i in ${namespaces[@]}; do
    for label in ${labels[@]}; do
        kubectl -n ${i} delete deployment -l ${label}
        kubectl -n ${i} delete ds -l ${label}
        kubectl -n ${i} delete rs -l ${label}
        kubectl -n ${i} delete pods -l ${label}
        kubectl -n ${i} delete services -l ${label}
        kubectl -n ${i} delete pvc -l ${label}
        kubectl -n ${i} delete rolebinding -l ${label}
        kubectl -n ${i} delete roles -l ${label}
        kubectl -n ${i} delete serviceaccounts -l ${label}
        kubectl -n ${i} delete configmaps -l ${label}
        kubectl -n ${i} delete secrets -l ${label}
        kubectl -n ${i} delete jobs -l ${label}
    done
done

# Not namespaced resources
for label in ${labels[@]}; do
    kubectl delete validatingwebhookconfiguration -l ${label}
    kubectl delete pv -l ${label}
    kubectl delete clusterrolebinding -l ${label}
    kubectl delete clusterroles -l ${label}
    kubectl delete customresourcedefinitions -l ${label}
    kubectl get apiservices -l ${label} -o=custom-columns=NAME:.metadata.name,FINALIZERS:.metadata.finalizers --no-headers | grep foregroundDeletion | while read p; do
        arr=($p)
        name="${arr[0]}"
        kubectl -n ${i} patch apiservices $name --type=json -p '[{ "op": "remove", "path": "/metadata/finalizers" }]'
    done
done

for i in ${managed_namespaces[@]}; do
    if [ -n "$(kubectl get ns | grep "${i} ")" ]; then
        echo "Clean ${i} namespace"
        kubectl delete ns ${i}

        start_time=0
        sample=10
        timeout=120 
        echo "Waiting for ${i} namespace to disappear ..."
        while [ -n "$(kubectl get ns | grep "${i} ")" ]; do
            sleep $sample
            start_time=$((current_time + sample))
            if [[ $current_time -gt $timeout ]]; then
                exit 1
            fi
        done
    fi
done
sleep 2
echo "Done"
