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

strimzi_version=`curl https://github.com/strimzi/strimzi-kafka-operator/releases/latest |  awk -F 'tag/' '{print $2}' | awk -F '"' '{print $1}' 2>/dev/null`
serving_version="v0.19.0"
kourier_version="v0.19.1"
eventing_version="v0.19.4"
eventing_kafka_version="v0.19.3"

function header_text {
  echo "$header$*$reset"
}

header_text "Using Strimzi Version:                      ${strimzi_version}"
header_text "Using Knative Serving Version:              ${serving_version}"
header_text "Using Kourier Version:                      ${kourier_version}"
header_text "Using Knative Eventing Version:             ${eventing_version}"
header_text "Using Knative Eventing Contrib Version:     ${eventing_kafka_version}"

header_text "Strimzi install"
kubectl create namespace kafka
kubectl -n kafka apply --selector strimzi.io/crd-install=true -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/${strimzi_version}/strimzi-cluster-operator-${strimzi_version}.yaml
curl -L "https://github.com/strimzi/strimzi-kafka-operator/releases/download/${strimzi_version}/strimzi-cluster-operator-${strimzi_version}.yaml" \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka apply -f -

# Wait for the CRD we need to actually be active
kubectl wait crd --timeout=-1s kafkas.kafka.strimzi.io --for=condition=Established

header_text "Applying Strimzi Cluster file"
kubectl -n kafka apply -f "https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/${strimzi_version}/examples/kafka/kafka-persistent-single.yaml"
header_text "Waiting for Strimzi to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kafka

header_text "Setting up Knative Serving"

 n=0
   until [ $n -ge 2 ]
   do
      kubectl apply --filename https://github.com/knative/serving/releases/download/${serving_version}/serving-core.yaml && break
      n=$[$n+1]
      sleep 5
   done

header_text "Waiting for Knative Serving to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-serving

header_text "Setting up Kourier"
kubectl apply -f "https://github.com/knative/net-kourier/releases/download/${kourier_version}/kourier.yaml"

header_text "Waiting for Kourier to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system

header_text "Configure Knative Serving to use the proper 'ingress.class' from Kourier"
kubectl patch configmap/config-network \
  -n knative-serving \
  --type merge \
  -p '{"data":{"clusteringress.class":"kourier.ingress.networking.knative.dev",
               "ingress.class":"kourier.ingress.networking.knative.dev"}}'

header_text "Setting up Knative Eventing"
kubectl apply --filename https://github.com/knative/eventing/releases/download/${eventing_version}/eventing-core.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/${eventing_version}/eventing-sugar-controller.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/${eventing_version}/mt-channel-broker.yaml

header_text "Waiting for Knative Eventing to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing

header_text "Setting up Knative Apache Kafka Source"
curl -L https://github.com/knative-sandbox/eventing-kafka/releases/download/${eventing_kafka_version}/source.yaml \
  | sed 's/namespace: .*/namespace: knative-eventing/' \
  | kubectl apply -f - -n knative-eventing

header_text "Waiting for Knative Apache Kafka Source to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing

header_text "Setting up Knative Apache Kafka Channel"
curl -L "https://github.com/knative-sandbox/eventing-kafka/releases/download/${eventing_kafka_version}/channel-consolidated.yaml" \
    | sed 's/REPLACE_WITH_CLUSTER_URL/my-cluster-kafka-bootstrap.kafka:9092/' \
    | kubectl apply --filename -

header_text "Waiting for Knative Apache Kafka Channel to become ready"
kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-eventing

cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-ch-webhook
  namespace: knative-eventing
data:
  # Configuration for defaulting channels that do not specify CRD implementations.
  default-ch-config: |
    clusterDefault:
      apiVersion: messaging.knative.dev/v1beta1
      kind: KafkaChannel
      spec:
        numPartitions: 3
        replicationFactor: 1
EOF

cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-br-default-channel
  namespace: knative-eventing
data:
  channelTemplateSpec: |
    apiVersion: messaging.knative.dev/v1beta1
    kind: KafkaChannel
EOF
