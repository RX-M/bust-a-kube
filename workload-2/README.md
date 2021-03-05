# Problem 2 - Pod Scheduling


## Context

The pod spec provided in `problem.yaml` creates a pod running the Apache webserver that immediately goes into the
`Pending` state. Apply the manifest to your cluster, identify the problem and repair it so that the pod schedules and
runs as expected.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/workload-2/problem.yaml
```


## Solution Conditions

The pod must be in the running state with all containers ready for this problem to be considered resolved.

<br>

_Copyright (c) 2020-2021 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
