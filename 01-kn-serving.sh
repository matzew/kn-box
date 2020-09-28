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

serving_version="v0.17.3"
kourier_version="v0.17.2"

function header_text {
  echo "$header$*$reset"
}

header_text "Using Knative Serving Version:          ${serving_version}"
header_text "Using Kourier Version:                  ${kourier_version}"

header_text "Setting up Knative Serving"

 n=0
   until [ $n -ge 2 ]
   do
      kubectl apply --filename https://github.com/knative/serving/releases/download/${serving_version}/serving-core.yaml && break
      n=$[$n+1]
      sleep 5
   done

header_text "Waiting for Knative Serving to become ready"
sleep 5; while echo && kubectl get pods -n knative-serving | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done

header_text "Setting up Kourier"
kubectl apply -f "https://github.com/knative/net-kourier/releases/download/${kourier_version}/kourier.yaml"

header_text "Waiting for Kourier to become ready"
sleep 5; while echo && kubectl get pods -n kourier-system | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done

header_text "Configure Knative Serving to use the proper 'ingress.class' from Kourier"
kubectl patch configmap/config-network \
  -n knative-serving \
  --type merge \
  -p '{"data":{"clusteringress.class":"kourier.ingress.networking.knative.dev",
               "ingress.class":"kourier.ingress.networking.knative.dev"}}'
