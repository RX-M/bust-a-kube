# Bust-a-Kube


## Problem 1 - A broken pod


### Problem Context

The pod spec described in `problem.yaml` creates a pod meant to run the `alpine` image that will not immediately start
as expected.


### Problem Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```
ubuntu@labsys:~$ wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/pod-debug-1/problem.yaml > pod-debug-1.yaml

ubuntu@labsys:~$ kubectl apply -f pod-debug-1.yaml

pod/debug-pod1 created

ubuntu@labsys:~$
```


### Solution Conditions

The pod must be in the running state with all containers ready for this problem to be considered resolved.

<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
