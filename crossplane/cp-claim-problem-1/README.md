![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Crossplane Claims Problem 1


## Context

The claim in `problem.yaml` is supposed to create an XR (composite resource) but doesn't.


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

- The claim must create an S3 bucket

The solution file (`solution.md`) demonstrates deleting the bucket.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_