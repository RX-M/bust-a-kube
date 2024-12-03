![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Crossplane XR Problem 1


## Context

The `problem.yaml` is supposed to create a XR (Composite Resource) but doesn't correctly.


## Setup

Ensure that you have:

- A working Kubernetes cluster
- A local kubeconfig with admin perms
- Crossplane installed on the cluster
- A properly configured AWS CLI
- A properly configured s3.aws.crossplane.io Crossplane Provider (with working ProviderConfig)

**WARNING: This exercise should only be performed on disposable Kubernetes clusters and this particular exercise**
**will construct small randomly named resources in your AWS environment with a rx-m prefix.**

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/crossplane/cp-xr-problem-1/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- You must determine the XR created
- Ascertain why it is broken
- Fix it

The solution file (`solution.md`) provides answers and cleans up all created resources.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_