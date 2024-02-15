![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Pods


## Context

The pod specified in the `problem.yaml` here creates a container which should write a simple message to stdout using the `busybox` image. 
The pod fails. Your job is to discover why, fix the problem and ensure that the pod runs successfully. 


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
