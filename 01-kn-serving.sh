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

serving_version="v1.1.0"
kourier_version="v1.1.0"

serving_url=https://github.com/knative/serving/releases/download/knative-${serving_version}
kourier_url=https://github.com/knative/net-kourier/releases/download/knative-${kourier_version}

while [[ $# -ne 0 ]]; do
   parameter=$1
   case ${parameter} in
     --nightly)
        nightly=1
        serving_version=nightly
        serving_url=https://knative-nightly.storage.googleapis.com/serving/latest
        kourier_version=nightly
        kourier_url=https://knative-nightly.storage.googleapis.com/net-kourier/latest
       ;;
     *) abort "unknown option ${parameter}" ;;
   esac
   shift
 done


function header_text {
  echo "$header$*$reset"
}

header_text "Using Knative Serving Version:          ${serving_version}"
header_text "Using Kourier Version:                  ${kourier_version}"

header_text "Setting up Knative Serving"

 n=0
   until [ $n -ge 2 ]
   do
      kubectl apply --filename $serving_url/serving-core.yaml && break
      n=$[$n+1]
      sleep 5
   done

header_text "Waiting for Knative Serving to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-serving

header_text "Setting up Kourier"
kubectl apply -f $kourier_url/kourier.yaml

header_text "Waiting for Kourier to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system

header_text "Configure Knative Serving to use the proper 'ingress.class' from Kourier"
kubectl patch configmap/config-network \
  -n knative-serving \
  --type merge \
  -p '{"data":{"clusteringress.class":"kourier.ingress.networking.knative.dev",
               "ingress.class":"kourier.ingress.networking.knative.dev"}}'
