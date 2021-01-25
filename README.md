# Knative installation box

A collection of script to run Knative

## Out of the Box: Apache Kafka and Knative

An opinionated package of Knative, Koruier, Apache Kafka and Strimzi can be found in [this](ootb_kafka) folder!

## Modular Installers

The root director contains a set of more fine-grained scripts, allowing you a modular setup.
The installer gets you a minikube/kind cluster:

```shell
./00-installer(kind).sh
```

You can specify the _Kubernetes_ version with the `K8S_IMAGE` environment variable, before call the `00-install-kind.sh`:
```shell
export K8S_IMAGE=kindest/node:v1.20.0
```

_**NOTE:** The scripts for the Knative components work against any Kubernetes cluster!_

### Knative Serving

To install the Knative Knative Serving with Kourier Ingress to the cluster invoke:

```shell
./01-kn-serving.sh
```

This installs the latest released version of Knative serving.
If you want to install the latest nightly build, use option `--nightly` (i.e. `./01-kn-serving.sh --nightly`)

### Knative Eventing

To install the Knative Eventing components to the cluster invoke:

```shell
./02-kn-eventing.sh
```

This installs the latest released version of Knative eventing.
If you want to install the latest nightly build, use option `--nightly` (i.e. `./02-kn-eventing.sh --nightly`)

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

This command installs the latest release of the Apache Kafka components.
If you instead want to install the latest nightly builds use the option `--nightly` (i.e. `./04-kn-kafka.sh --nightly`).

> The `KafkaChannel` in this version is currently not configured to run as a default channel!

## Enabling tracing

If you want, you can install zipkin and configure it for Knative Eventing to read event traces:

```shell
./optional-tracing.sh
```

> Be aware to configure tracing after you configured all the other components

Have fun!
