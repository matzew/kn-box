# Source to Service 

One of the simplest uses cases of Knative eventing is to directly sink the events from the emitting source to a Knative Serving Service (`ksvc`).

## Deploy the consuming Knative Serving Service

The first step is the deployment of a Knative Serving service that later acts as the consumer of the events, emitted by the _Knative Eventing Source_:

```
k apply -f 000-ksvc.yaml
```

The above installs a new `ksvc`, called _service-one_, to the `default` namespace. After applying the file, we can check some details about our new `ksvc`, by running ` k get ksvc`:

```
NAME               URL                                           LATESTCREATED            LATESTREADY              READY   REASON
service-one   http://service-one.default.example.com   service-one-kfhpm   service-one-kfhpm   True
```

We now have a `ksvc` running in the background, waiting for some incoming HTTP requests.

## Connect the Source to the `ksvc`

To be able to have the `ksvc` consume events, we need to hook it up to a _Knative Eventing Source_. In our tutorial we are using the `ApiServerSource`, which will allows an integration of the Kubernetes API server events into Knative.

### ServiceAccount to run the `ApiServerSource`

Before we can apply the `ApiServerSource` itself, we need to create a `ServiceAccount` that the `ApiServerSource` runs as, since it does require some permissions in order to work with the Kubernetes API server events:

```
k apply -f 010-serviceaccount.yaml
```

### Kubernetes API server events

With the `ServiceAccount` in place we can finally connect our `ApiServerSource` to the `ksvc` so it can consume events. Let's take a look at the file:

```yaml
apiVersion: sources.knative.dev/v1alpha2
kind: ApiServerSource
metadata:
  name: testevents
  namespace: default
spec:
  serviceAccountName: events-sa
  mode: Resource
  resources:
  - apiVersion: v1
    kind: Event
  sink:
    apiVersion: serving.knative.dev/v1
    kind: Service
    name: k8s-display
```

The `spec` of the `ApiServerSource` is referencing the previously created `ServiceAccount`, but more importantly, the `sink` part does reference our `service-one` instance of the initially installed `ksvc`.

Now let's apply it:

```
k apply -f 020-k8s-events.yaml
```

We will now see that a new pod is up and running, representing the `ApiServerSource`, when we run `k get pods`:

```
NAME                                                              READY   STATUS    RESTARTS   AGE
apiserversource-testevents-91f06d1f-cfe6-11e9-9d67-70c21b48r9pt   1/1     Running   0          86m
service-one-kfhpm-deployment-747c97d7c5-x6hnl                    2/2     Running   0          85s
```

The `apiserversource` pod is now running the `ApiServerSource`, which directly sends its events to the hardwired `ksvc`, our `service-one` installation.

> NOTE: To retrieve an overview of all source that are currently deployed in your namespace, just run `k get sources`. In our case you get the following output:
>```
>NAME                                                      AGE
>apiserversource.sources.knative.dev/testevents   5m
>```

## Show the consumed events

Finally we can now see the consumed Kubernetes API server events in the log of the `service-one-kfhpm-deployment-747c97d7c5-x6hnl` pod, by running:

```
k logs -f service-one-kfhpm-deployment-747c97d7c5-x6hnl -c user-container
```

The pod does run two containers, but we are only interested in the `user-container`, running our application via Knative Serving. In the log we now see some Kubernetes API server events, wrapped as CloudEvents:

```
☁️  cloudevents.Event
Validation: valid
Context Attributes,
  specversion: 1.0
  type: dev.knative.apiserver.resource.update
  source: https://10.96.0.1:443
  subject: /apis/v1/namespaces/default/events/testevents.15f90c6b780aa5a1
  id: 6b92aaf2-a489-4adb-922b-8e60f05f15da
  time: 2020-03-04T08:31:14.007672126Z
  datacontenttype: application/json
Data,
  {
    "apiVersion": "v1",
    "count": 10,
    "eventTime": null,
    "firstTimestamp": "2020-03-04T08:26:39Z",
    "involvedObject": {
      "apiVersion": "sources.knative.dev/v1alpha1",
      "kind": "ApiServerSource",
      "name": "testevents",
      "namespace": "default",
      "resourceVersion": "2661",
      "uid": "a516feb0-dd6c-4168-ab19-dd2fb4c12e59"
    },
    "kind": "Event",
    "lastTimestamp": "2020-03-04T08:31:14Z",
    "message": "Deployment \"apiserversource-testevents-a516feb0-dd6c-4168-ab19-dd2fb4c12e59\" updated",
    "metadata": {
      "creationTimestamp": "2020-03-04T08:26:39Z",
      "name": "testevents.15f90c6b780aa5a1",
      "namespace": "default",
      "resourceVersion": "3560",
      "selfLink": "/api/v1/namespaces/default/events/testevents.15f90c6b780aa5a1",
      "uid": "07f5d445-606f-4b54-a6b6-fe226419f11e"
    },
    "reason": "ApiServerSourceDeploymentUpdated",
    "reportingComponent": "",
    "reportingInstance": "",
    "source": {
      "component": "apiserver-source-controller"
    },
    "type": "Normal"
  }
```

## Conclusion 

We now have seen that one can simply consume events using a _Knative Eventing Source_ that is directly wired to a Knative Serving Service.

While this use-case is simple and easy to implement, it has some limitations, that the _Knative Eventing Source_ is not able to distribute its events to multiple consumers.

NEXT: [Channel and multiple consumers](../02-source_channel)
