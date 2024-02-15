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

kube_version="v1.29.1"

if [ -z "$MEMORY" ]; then
  MEMORY="$(minikube config view | awk '/memory/ { print $3 }')"
fi
if [ -z "$CPUS" ]; then
  CPUS="$(minikube config view | awk '/cpus/ { print $3 }')"
fi
if [ -z "$DISKSIZE" ]; then
  DISKSIZE="$(minikube config view | awk '/disk-size/ { print $3 }')"
fi
if [ -z "$DRIVER" ]; then
  DRIVER="$(minikube config view | awk '/driver/ { print $3 }')"
fi

function header_text {
  echo "$header$*$reset"
}

header_text "Starting minikube with Kubernetes Version:               ${kube_version}"

minikube start --memory="${MEMORY:-15986}" --cpus="${CPUS:-10}" --kubernetes-version="${kube_version}" --driver="${DRIVER:-kvm2}" --disk-size="${DISKSIZE:-30g}" --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook" --addons registry
header_text "Waiting for core k8s services to initialize"
sleep 5; while echo && kubectl get pods -n kube-system | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done
