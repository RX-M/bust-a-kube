# Insecure Configuration

## Context

In provided `problem.yaml` there are some security issues that need to be
addressed. The pod start successful but it configured with different security
issues. Some of the issues can be identified using `kube-score` a static code
analysis of your Kubernetes object definitions. Others are just bad
configurations for workloads and mostly are used for troubleshooting and
debugging purposes.

Create a new file `good-pod.yaml` with already fixed deffitiions

## Setup

Copy the `problem.yaml` to `good-pod.yaml`

```bash
~$ cp problem.yaml good-pod.yaml
```

Using `kube-score` perform static code analysis and fix the issues.

Apply the `good-pod.yaml` spec to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/security-2/problem.yaml
```

## Solution Conditions

The pod logs must show a listing of pods inside its namespace (in JSON format) for this problem to be considered solved.

<br>

_Copyright (c) 2020-2023 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
