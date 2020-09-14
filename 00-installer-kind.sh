#!/usr/bin/env bash

set -e

# Turn colors in this script off by setting the NO_COLOR variable in your
# environment to any value:
#
# $ NO_COLOR=1 test.sh
NO_COLOR=${NO_COLOR:-""}
if [ -z "$NO_COLOR" ]; then
  header=$'\e[1;33m'
  reset=$'\e[0m'
else
  header=''
  reset=''
fi

function header_text {
  echo "$header$*$reset"
}

header_text "Starting Knative on kind!"

kind create cluster
header_text "Waiting for core k8s services to initialize"
sleep 5; while echo && kubectl get pods -n kube-system | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done

kubectl -n kube-system get configmap coredns -o yaml | sed 's/\/etc\/resolv.conf/8.8.8.8/gi' | kubectl apply -f -
PODNAMES=(`kubectl -n kube-system get pods -o jsonpath='{.items[*].metadata.name}'`)
for name in ${PODNAMES[@]}; do
    if echo "$name" | grep -q 'coredns-'; then
        kubectl -n kube-system delete pods "$name"
    fi
done
