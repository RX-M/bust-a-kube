# Problem 3 - Services


## Context

`problem.yaml` creates a deployment named `app-frontend` that creates three pods running NGINX and exposes those pods
through a service named `client-access`. When applied to a cluster, the deployment, service, and pods are created
successfully but the pods are not accessible through the service. Apply the manifest to your cluster, identify the
problem and repair it so that the pods are accessible through the service as expected.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/svc-debug-1/problem.yaml
```


## Solution Conditions

Requests made to the service DNS name or IP address must return the NGINX welcome page for this problem to be considered
resolved.


<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
