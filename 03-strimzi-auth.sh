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

function header_text {
  echo "$header$*$reset"
}

header_text "Using Strimzi Version:                  ${strimzi_version}"

header_text "Strimzi install"
kubectl create namespace kafka
kubectl -n kafka apply --selector strimzi.io/crd-install=true -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/${strimzi_version}/strimzi-cluster-operator-${strimzi_version}.yaml
curl -L "https://github.com/strimzi/strimzi-kafka-operator/releases/download/${strimzi_version}/strimzi-cluster-operator-${strimzi_version}.yaml" \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka apply -f -

# Wait for the CRD we need to actually be active
kubectl wait crd --timeout=-1s kafkas.kafka.strimzi.io --for=condition=Established

header_text "Applying Strimzi Cluster file"
# kubectl -n kafka apply -f "https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/${strimzi_version}/examples/kafka/kafka-persistent-single.yaml"
cat <<-EOF | kubectl -n kafka apply -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 2.6.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: tls
      - name: sasl
        port: 9094
        type: internal
        tls: true
        authentication:
          type: scram-sha-512
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.message.format.version: "2.6"
      auto.create.topics.enable: "false"
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 100Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

header_text "Waiting for Strimzi to become ready"
kubectl wait kafka --all --timeout=-1s --for=condition=Ready -n kafka

header_text "Applying Strimzi TLS Admin User"
cat <<-EOF | kubectl -n kafka apply -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaUser
metadata:
  name: my-tls-user
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: tls
  authorization:
    type: simple
    acls:
      # Example ACL rules for consuming from knative-messaging-kafka using consumer group my-group
      - resource:
          type: topic
          name: "*"
        operation: Read
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Describe
        host: "*"
      - resource:
          type: group
          name: "*"
        operation: Read
        host: "*"
      # Example ACL rules for producing to topic knative-messaging-kafka
      - resource:
          type: topic
          name: "*"
        operation: Write
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Create
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Describe
        host: "*"
EOF

header_text "Applying Strimzi SASL Admin User"
cat <<-EOF | kubectl -n kafka apply -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaUser
metadata:
  name: my-sasl-user
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      # Example ACL rules for consuming from knative-messaging-kafka using consumer group my-group
      - resource:
          type: topic
          name: "*"
        operation: Read
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Describe
        host: "*"
      - resource:
          type: group
          name: "*"
        operation: Read
        host: "*"
      # Example ACL rules for producing to topic knative-messaging-kafka
      - resource:
          type: topic
          name: "*"
        operation: Write
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Create
        host: "*"
      - resource:
          type: topic
          name: "*"
        operation: Describe
        host: "*"
EOF

header_text "Waiting for Strimzi Users to become ready"
sleep 10

header_text "Creating a Secret, containing TLS from Strimzi"
STRIMZI_CRT=$(k -n kafka get secret my-cluster-cluster-ca-cert --template='{{index .data "ca.crt"}}' | base64 --decode )
TLSUSER_CRT=$(k -n kafka get secret my-tls-user --template='{{index .data "user.crt"}}' | base64 --decode )
TLSUSER_KEY=$(k -n kafka get secret my-tls-user --template='{{index .data "user.key"}}' | base64 --decode )

kubectl create secret --namespace default generic my-tls-secret \
    --from-literal=ca.crt="$STRIMZI_CRT" \
    --from-literal=user.crt="$TLSUSER_CRT" \
    --from-literal=user.key="$TLSUSER_KEY"

header_text "Creating a Secret, containing SASL from Strimzi"
SASL_PASSWD=$(k -n kafka get secret my-sasl-user --template='{{index .data "password"}}' | base64 --decode )
kubectl create secret --namespace default generic my-sasl-secret \
    --from-literal=password="$SASL_PASSWD" \
    --from-literal=ca.crt="$STRIMZI_CRT" \
    --from-literal=saslType="SCRAM-SHA-512" \
    --from-literal=user="my-sasl-user"
