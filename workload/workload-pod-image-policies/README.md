![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Pods


## Context

The pod defined in the `problem.yaml` below creates a pod meant to run a simple echo message in the `busybox` image. The
pod cannot start. Apply the manifest to your cluster, identify the problem and repair it so that the pod completes as
expected.


## Setup

Apply the `problem.yaml` manifest to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/workload/workload-pod-image-policies/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- The pod must be in the `complete` state.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
