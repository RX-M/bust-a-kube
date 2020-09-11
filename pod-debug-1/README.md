# Bust-a-Kube


## Problem 1 - A broken pod


### Problem Context

The pod defined in `problem.yaml` creates a pod meant to run a perpetual tail command in the `busybox` image. The 
pod does not run as expected. Apply the manifest to your cluster, identify the problem and repair it so that the pod 
runs as expected.


### Problem Setup

Apply the `problem.yaml` manifest to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/pod-debug-1/problem.yaml > pod-debug-1.yaml
```


### Solution Conditions

The pod must be in the running state with all containers ready for this problem to be considered resolved.

<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
