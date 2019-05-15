#!/bin/bash -e
WORKER_NODES=$(oc describe no -l node-role.kubernetes.io/worker | grep hostname)
IPS=()

for w in ${WORKER_NODES[@]}; do
	IPS+=" $(echo $w | cut -d'=' -f2)"
done

for i in ${IPS[@]}; do
	echo "IP: $i"
done
echo "Length of 'Fruits' = ${#IPS[@]}"
