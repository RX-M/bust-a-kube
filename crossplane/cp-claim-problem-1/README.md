![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Crossplane Claims Problem 1


## Context

The `problem.yaml` is supposed to create a MR (managed resource) but doesn't.


## Setup

Ensure that you have:

- A working Kubernetes cluster
- A local kubeconfig with admin perms
- Crossplane installed on the cluster
- A properly configured AWS CLI
- A properly configured AWS S3 Crossplane Provider (with working ProviderConfig)

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/crossplane/cp-claim-problem-1/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- You must determine the resource created
- Ascertain why it is broken
- Fix it

The solution file (`solution.md`) provides answers and cleans up all created resources.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_