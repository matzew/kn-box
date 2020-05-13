# Knative installation box

A collection of script to run Knative

## Out of the Box: Apache Kafka and Knative

An opinionated package of Knative, Koruier, Apache Kafka and Strimzi can be found in `[this](ootb_kafka)` folder!

## Modular Installers

The root director contains a set of more fine-grained scripts, allowing you a modular setup.
The installer gets you a minikube cluster, that runs:

* Knative Serving CORE
* Kourier Ingress

```shell
./01-installer.sh
```

### Knative Eventing

To install the Knative Eventing components to the cluster invoke:

```shell
./02-kn-eventing.sh
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
./03-strimzi.sh
```

## Knative components for Apache Kafka

To install the `KafkaSource` and the `KafkaChannel` CRDs, run:

```shell
./04-kn-kafka.sh
```

> The `KafkaChannel` in this version is currently not configured to run as a default channel!

## Enabling tracing

If you want, you can install zipkin and configure it for Knative Eventing to read event traces:

```shell
./optional-tracing.sh
```

> Be aware to configure tracing after you configured all the other components

Have fun!
