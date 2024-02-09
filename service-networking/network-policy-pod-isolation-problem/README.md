![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Network Policy - Pod Isolation Problem

> WARNING: **Do not apply the manifests referenced here on a cluster you care about!!**

# Prerequisites

To troubleshoot this problem scenario you'll need a Kubernetes cluster with a CNI plugin that support Network Policies.
For example:

- [Calico](https://github.com/projectcalico/calico)
- [Weave](https://github.com/weaveworks/weave)

If you don't have one, it is recommended to spin a new, disposable, single-node Kubernetes cluster using a vanilla Ubuntu x64
based virtual machine and the [k8s.sh](https://raw.githubusercontent.com/RX-M/classfiles/master/k8s.sh) setup script that automates the initial setup of a single node Kubernetes cluster
with Weave Net CNI.

Another options is to use [kind](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind) or [Minikube](https://docs.tigera.io/calico/latest/getting-started/kubernetes/minikube) and Container Runtime like [Podman](https://podman.io/) or [Docker](https://www.docker.com/).

Minikube offers are built-in calico implementation making it very convenient to create a new cluster:

```shell
$ minikube -p netpol-problem start --network-plugin=cni --cni=calico
```

To validate that the cluster was created successfully:

```shell
$ minikube profile list
|----------------|-----------|---------|--------------|------|---------|---------|-------|--------|
|    Profile     | VM Driver | Runtime |      IP      | Port | Version | Status  | Nodes | Active |
|----------------|-----------|---------|--------------|------|---------|---------|-------|--------|
| netpol-problem | docker    | docker  | 192.168.49.2 | 8443 | v1.28.3 | Running |     1 |        |
|----------------|-----------|---------|--------------|------|---------|---------|-------|--------|
$
```

```shell
$ kubectl get no -o wide
NAME             STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
netpol-problem   Ready    control-plane   4m31s   v1.28.3   192.168.49.2   <none>        Ubuntu 22.04.3 LTS   6.6.12-linuxkit   docker://24.0.7
$
```


## Context

When applied to the cluster, the `problem.yaml` will create:

- A new namespace named `netpol-problem`
- Two pods: One server pod based on NGINX and one client pod based on Alpine Linux
- A network policy

Both the pods and the Network Policy will be created in the `netpol-problem` namespace successfully but the NGINX
(server) pod will not be accessible from the client pod.

Apply the manifest to your cluster, identify the problem(s) and repair it so that the client pod will be able to access
the server pod.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/service-networking/network-policy-pod-isolation-problem/problem.yaml
```


## Solution Conditions

For this problem to be considered resolved:

- Requests made to the server pod DNS name or IP address must return the NGINX welcome page

Hint: Alpine linux images are very lightweight. They are based on busybox and don't contain `curl`. If you want to install
curl you can use the following commands within the container:

```shell
$ apk update
$ apk --no-cache add curl
```

Alternatively to test the connectivity you can use the build-in wget command from the client pod:

```shell
$ wget -O- <server-pod-ip-address>
```

## Cleanup

If you have created a new kubernetes cluster for this exercise using minikube, you can use the following command to
destroy it:

```shell
minikube -p netpol-problem delete
```

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
