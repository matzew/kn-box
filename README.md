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
