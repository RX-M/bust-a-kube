![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Persistent Storage


## Context

`problem.yaml` is a combined manifest describing a statically provisioned persistent volume, a persistent volume claim
meant to bind to that volume, and a pod which creates uses the persistent volume (through the claim) as a mount. When
applied, all resources are successfully created but the pod goes into a `Pending` state. Apply the manifest to your
cluster, identify the problem and repair it so that the pod schedules and runs as expected.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/config-storage/config-storage-persistent-storage/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- The pod must be in the running state with all containers ready

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_