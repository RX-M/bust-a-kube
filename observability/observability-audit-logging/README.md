![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Audit Logging

> WARNING: **Do not apply the manifests referenced here on a cluster you care about!!**

# Prerequisites

To troubleshoot this problem scenario you'll need a Kubernetes cluster with access to the `kube-apiserver` service or
container in order to modify its configuration.

If you don't have one, it is recommended to spin a new, disposable, single-node Kubernetes cluster using a vanilla Ubuntu
x64 based virtual machine and the RX-M [k8s.sh](https://raw.githubusercontent.com/RX-M/classfiles/master/k8s.sh) setup
script that automates the initial setup of a single node Kubernetes cluster:

```shell
$ curl https://raw.githubusercontent.com/RX-M/classfiles/master/k8s.sh | sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3624  100  3624    0     0  13406      0 --:--:-- --:--:-- --:--:-- 13422
...
$
```

Another options is to use [kind](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind) or [Minikube](https://docs.tigera.io/calico/latest/getting-started/kubernetes/minikube) and Container Runtime like [Podman](https://podman.io/) or [Docker](https://www.docker.com/).

Both Kind and Minikube support Audit Policies but working with them is a bit harder:

- Minikube: The [audit policy](https://minikube.sigs.k8s.io/docs/tutorials/audit-policy/) guide shows how to define an
            audit policy and the [file sync](https://minikube.sigs.k8s.io/docs/handbook/filesync/) guide shows how to
            apply any policy changes by triggering file sync. Alternatively you could use "minikube ssh".
- kind: The [Auditing](https://kind.sigs.k8s.io/docs/user/auditing/) page provides details how to pass additional kubeadm
        configuration containing the audit policy during the cluster creation.


## Context

The `problem.yaml` is an audit policy file containing multiple rules. We've created it in order to audit `only events`
related to specific API requests against specific resources like configmaps, secrets, pods and services, but something
seems to be wrong...

Download the policy file and configure the `kube-apiserver` audit logging. Identify any problem(s) with the policy file
matching the solution conditions below and repair them!


## Setup

Download the `problem.yaml` audit policy file to your kubernetes cluster and store it as `/etc/kubernetes/audit-policy.yaml`
using the following command:

```bash
sudo wget https://raw.githubusercontent.com/RX-M/bust-a-kube/master/observability/observability-audit-logging/problem.yaml -O /etc/kubernetes/audit-policy.yaml
```

Next we have to configure the API server audit logging. Using a text editor open the `/etc/kubernetes/manifests/kube-apiserver.yaml`
and add:

- API server options:

```yaml
  - --audit-policy=/etc/kubernetes/audit-policy.yaml
  - --audit-log-path=/var/log/kubernetes/audit/audit.log
```

- Volume definitions:

```yaml
- name: audit
  hostPath:
    path: /etc/kubernetes/audit-policy.yaml
    type: File

- name: audit-log
  hostPath:
    path: /var/log/kubernetes/audit/
    type: DirectoryOrCreate
```

- volumeMounts for the `kube-apiserver` container:

```yaml
volumeMounts:
  - mountPath: /etc/kubernetes/audit-policy.yaml
    name: audit
    readOnly: true
  - mountPath: /var/log/kubernetes/audit/
    name: audit-log
    readOnly: false
```

> Note: For this exercise we are going to use the log backend that writes audit event into the filesystem underneath
> `/var/log/kubernetes/audit/`.

Once you save the changes to the kube-apiserver manifest, the kubelet will notice the change within a few seconds and
restart the kube-api server pod. The troubleshooting now begin!

> Note: Once you apply the changes, you'll lose access to the API server. That is part of the challenge.

## Solution Conditions

For this problem to be considered resolved:

- The kube-apiserver pod should be running normally and accepting user requests.
- The `/var/log/kubernetes/audit/audit.log` should be created and it should report only:

  - Metadata level events for requests using get, list, watch verbs against configmaps and services in the kube-system
    namespace. All stages.
  - Request level events against secrets. All stages
  - RequestResponse level events against pods. All stages.

> No other events should be present in the audit file!


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
