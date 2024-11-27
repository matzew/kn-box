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

serving_version="v1.16.0"
kourier_version="v1.16.0"
istio_version="v1.16.0"
serving_url=https://github.com/knative/serving/releases/download/knative-${serving_version}
kourier_url=https://github.com/knative-extensions/net-kourier/releases/download/knative-${kourier_version}
istio_url=https://github.com/knative-extensions/net-istio/releases/download/knative-${istio_version}
mode="kourier"

while [[ $# -ne 0 ]]; do
   parameter=$1
   case ${parameter} in
     --nightly)
        nightly=1
        serving_version=nightly
        serving_url=https://knative-nightly.storage.googleapis.com/serving/latest
        kourier_version=nightly
        kourier_url=https://knative-nightly.storage.googleapis.com/net-kourier/latest/kourier.yaml
        ;;
     --istio)
        mode="istio"
        ;;
     *) abort "unknown option ${parameter}" ;;
   esac
   shift
 done


function header_text {
  echo "$header$*$reset"
}

header_text "Using Knative Serving Version:          ${serving_version}"

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

if [ $mode == "kourier" ]; then
  header_text "Using Kourier Version:                 ${kourier_version}"
  kubectl apply -f $kourier_url/kourier.yaml
  
  header_text "Waiting for Kourier to become ready" 
  kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system

  header_text "Configure Knative Serving to use the proper 'ingress.class' from Kourier"
  kubectl patch configmap/config-network \
    -n knative-serving \
    --type merge \
    -p '{"data":{"clusteringress.class":"kourier.ingress.networking.knative.dev",
               "ingress.class":"kourier.ingress.networking.knative.dev"}}'
fi

if [ $mode == "istio" ]; then
  header_text="Using Istio Version:               ${istio_version}"
  kubectl apply -l knative.dev/crd-install=true -f $istio_url/istio.yaml
  kubectl apply -f $istio_url/istio.yaml
  kubectl apply -f $istio_url/net-istio.yaml

  header_text "Waiting for Istio to become ready"
  kubectl wait deployment --all --timeout=-1s --for=condition=Available -n istio-system

  header_text "Scale Istio down to 1"
  kubectl scale deployment -n istio-system istiod --replicas=1
  kubectl patch hpa istiod -n istio-system --patch '{"spec":{"minReplicas":1}}'
  kubectl scale deployment -n istio-system istio-ingressgateway --replicas=1

  header_text "Install Cert Manager"
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$cert_manager_version/cert-manager.yaml
fi

