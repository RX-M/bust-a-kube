![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Application Access


## Context

`problem.yaml` is a combined manifest describing a simple busybox pod which attempts to list the pods in its namespace
in JSON. When applied all resources are successfully created and the pod goes into a `Completed` state, but the
developer is complaining that they are still facing issues when trying to use the pod and note that "the pod is
returning errors" with not other information.

Apply the manifest to your cluster, identify the problem and repair it so that the pod no longer reports any errors.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/security/security-application-access/problem.yaml
```


## Solution Conditions

For this problem to be considered solved:

- The pod logs must show a listing of pods inside its namespace (in JSON format)

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_