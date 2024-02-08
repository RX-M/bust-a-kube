![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Services


## Context

`problem.yaml` creates a deployment named `app-frontend` that creates three pods running NGINX and exposes those pods
through a service named `client-access`. When applied to a cluster, the deployment, service, and pods are created
successfully but the pods are not accessible through the service. Apply the manifest to your cluster, identify the
problem and repair it so that the pods are accessible through the service as expected.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/service-networking/service-networking-broken-service/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- Requests made to the service DNS name or IP address must return the NGINX welcome page


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_