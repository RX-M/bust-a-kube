# Break K8s Bash Script


## Context

**Do not run on a production cluster**

The `break-k8s.sh` bash script that produces seven problems in your Kubernetes cluster.
The `fix-k8s.sh` bash script fixes all seven problems in your Kubernetes cluster.

## Setup

Run the bash script:

```
wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/bash-script-break-k8s/break-k8s.sh | sh
```


## Solution Conditions

All pods must be in the running state with all containers ready for this problem to be considered resolved.
Pod networking must be running and pods must be able to communicate to other pods.

To run the solution bash script:

```
wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/bash-script-break-k8s/fix-k8s.sh | sh
```


<br>

_Copyright (c) 2020-2022 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
