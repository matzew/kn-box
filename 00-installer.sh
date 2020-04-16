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

kube_version="v1.18.1"

MEMORY="$(minikube config view | awk '/memory/ { print $3 }')"
CPUS="$(minikube config view | awk '/cpus/ { print $3 }')"
DISKSIZE="$(minikube config view | awk '/disk-size/ { print $3 }')"
DRIVER="$(minikube config view | awk '/vm-driver/ { print $3 }')"

function header_text {
  echo "$header$*$reset"
}

header_text "Starting Knative on minikube!"
header_text "Using Kubernetes Version:               ${kube_version}"

minikube start --memory="${MEMORY:-12288}" --cpus="${CPUS:-8}" --kubernetes-version="${kube_version}" --vm-driver="${DRIVER:-kvm2}" --disk-size="${DISKSIZE:-30g}" --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"
header_text "Waiting for core k8s services to initialize"
sleep 5; while echo && kubectl get pods -n kube-system | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done
