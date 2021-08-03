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

header_text "Installing Kafka UI"

kubectl apply -n kafka -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: kafka-ui
  namespace: kafka
spec:
  type: NodePort
  ports:
  - name: http
    port: 8080
  selector:
    app: kafka-ui
---
apiVersion: v1
kind: Pod
metadata:
  name: kafka-ui
  namespace: kafka
  labels:
    app: kafka-ui
spec:
  containers:
    - env:
      - name: KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS
        value: my-cluster-kafka-bootstrap.kafka.svc:9092
      - name: KAFKA_CLUSTERS_0_NAME
        value: my-cluster
      image: quay.io/openshift-knative/kafka-ui:0.1.0
      name: user-container
---
EOF

minikube service -n kafka kafka-ui
