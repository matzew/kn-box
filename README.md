# Knative installation box

A collection of script to run Knative

## Installer

The installer gets you a minikube cluster, that runs:

* Knative Serving CORE
* Kourier Ingress
* Knative Eventing CORE

```shell
./installer.sh
```

### Accessing a service

To extract the host & port for accessing a Knative service via Minikube you can use the following expression:

```
$(minikube ip):$(kubectl get svc kourier --namespace kourier-system --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')
```

For example:

```
# Get host:port for acessing a service
ADDR=$(minikube ip):$(kubectl get svc kourier --namespace kourier-system --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')

# Create a sample service
kn service create random --image rhuss/random:1.0

# Access the Knative service
curl -sH "Host: random.default.example.com" http://$ADDR | jq .
```

_`kn` is the official CLI from the Knative project. Get it [here](https://github.com/knative/client/releases/latest)!_

## Apache Kafka

If you want to experiment with Apache Kafka, install it using [Strimzi](https://strimzi.io):

```shell
./strimzi.sh
```

## Knative components for Apache Kafka

To install the `KafkaSource` and the `KafkaChannel` CRDs, run:

```shell
./kn-kafka.sh
```

Have fun!
