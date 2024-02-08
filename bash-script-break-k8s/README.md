![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Break K8s Bash Script


## Context

> WARNING: **Do not run on a production cluster!**

- `break-k8s.sh` - bash script that produces seven problems in your Kubernetes cluster.
- `fix-k8s.sh` - bash script that fixes all seven problems in your Kubernetes cluster.

## Setup

Run the bash script:

```bash
wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/bash-script-break-k8s/break-k8s.sh | sh
```


## Solution Conditions

For this problem to be considered resolved:

- All pods must be in the running state with all containers in a ready state
- Pod networking must be running and pods must be able to communicate to other pods.

To run the solution bash script:

```bash
wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/bash-script-break-k8s/fix-k8s.sh | sh
```


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_