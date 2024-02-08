![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Pod Classification


## Context

The pod spec provided in `problem.yaml` creates a pod running the Apache webserver that is meant to run with the
Guaranteed QOS Class. However, when the pod is created it is assigned the `Burstable` QoS class. Apply the manifest to
your cluster, identify the problem and repair it so that the pod runs with the `Guaranteed` QoS class.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/workload/workload-pod-classification/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- The pod must be in the running state with all containers in a ready state
- The pod must have the `Guaranteed` QOS Class

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_