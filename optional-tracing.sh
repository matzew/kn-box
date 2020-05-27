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

header_text "Setting Zipkin"

kubectl create namespace zipkin

kubectl apply -n zipkin -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: zipkin
spec:
  type: NodePort
  ports:
  - name: http
    port: 9411
  selector:
    app: zipkin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: zipkin
        image: docker.io/openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        resources:
          limits:
            memory: 1000Mi
          requests:
            memory: 256Mi
---
EOF

sleep 5; while echo && kubectl get pods -n zipkin | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done

header_text "Configuring Zipkin for eventing"

kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-tracing
  namespace: knative-eventing
data:
  enable: "true"
  zipkin-endpoint: "http://zipkin.zipkin.svc.cluster.local:9411/api/v2/spans"
  sample-rate: "1.0"
  debug: "true"
EOF

minikube service -n zipkin zipkin
