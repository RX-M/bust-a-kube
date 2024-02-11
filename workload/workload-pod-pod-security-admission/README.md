![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Pod Security Admission

## Context

When you run the `problem.yaml` manifest, a new namespace will be create with specific `Pod Security Standards`. We will
run a pod in that secured namespace but there is a problem and the pod cannot be created. Identify the problem and fix it.

## Setup

Apply the `problem.yaml` manifest to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/workload/workload-pod-pod-security-admission/problem.yaml
```

## Solution Conditions

For this problem to be considered resolved:

- The pod must run in specific secured namespace

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
