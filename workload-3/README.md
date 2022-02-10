# Problem 5 - Pod Classification


## Context

The pod spec provided in `problem.yaml` creates a pod running the Apache webserver that is meant to run with the
Guaranteed QOS Class. However, when the pod is created it is assigned the `Burstable` QoS class. Apply the manifest to
your cluster, identify the problem and repair it so that the pod runs with the `Guaranteed` QoS class.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/workload-3/problem.yaml
```


## Solution Conditions

The pod must be in the running state with all containers ready and have the `Guaranteed` QOS Class for this issue to be considered resolved.

<br>

_Copyright (c) 2020-2022 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
