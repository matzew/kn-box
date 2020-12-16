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

eventing_kafka_version="v0.19.3"
eventing_kafka_url=https://github.com/knative-sandbox/eventing-kafka/releases/download/${eventing_kafka_version}

while [[ $# -ne 0 ]]; do
   parameter=$1
   case ${parameter} in
     --nightly)
        nightly=1
        eventing_kafka_version=nightly
        eventing_kafka_url=https://knative-nightly.storage.googleapis.com/eventing-kafka/latest
       ;;
     *) abort "unknown option ${parameter}" ;;
   esac
   shift
 done

function header_text {
  echo "$header$*$reset"
}

header_text "Using Knative Kafka Eventing Version:         ${eventing_kafka_version}"

header_text "Setting up Knative Apache Kafka Source"
curl -L ${eventing_kafka_url}/source.yaml \
  | sed 's/namespace: .*/namespace: knative-eventing/' \
  | kubectl apply -f - -n knative-eventing

header_text "Waiting for Knative Apache Kafka Source to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing

header_text "Setting up Knative Apache Kafka Channel"
curl -L "${eventing_kafka_url}/channel-consolidated.yaml" \
    | sed 's/REPLACE_WITH_CLUSTER_URL/my-cluster-kafka-bootstrap.kafka:9092/' \
    | kubectl apply --filename -

header_text "Waiting for Knative Apache Kafka Channel to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing
