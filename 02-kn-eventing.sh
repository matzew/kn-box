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

eventing_version="v0.19.3"

function header_text {
  echo "$header$*$reset"
}

header_text "Using Knative Eventing Version:         ${eventing_version}"

header_text "Setting up Knative Eventing"
kubectl apply --filename https://github.com/knative/eventing/releases/download/${eventing_version}/eventing.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/${eventing_version}/eventing-sugar-controller.yaml

header_text "Waiting for Knative Eventing to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing
