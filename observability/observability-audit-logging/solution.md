![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)


# Audit Logging

## Solution

Let's start by following the set-up instructions in order to prepare our cluster for this challenge. The first step
is to get the Audit Policy file that we'll be troubleshooting locally in our cluster so that we can modify it if necessary:

```bash
$ sudo wget https://raw.githubusercontent.com/RX-M/bust-a-kube/master/observability/observability-audit-logging/problem.yaml -O /etc/kubernetes/audit-policy.yaml
```

Looking inside the policy:

```shell
$ cat $_
```

```yaml
apiVersion: audit.k8s.io/v1
kind: policy
omitStages:
  - "ResponseComplet"
rules:
  - level: Metadata
    verbs: ["get", "list", "watch"]
    namespaces: ["kube-system"]
      - group: ""
        resources: ["configmaps", "services"]
    omitStages:
      - "RequestReceived"
  - level: Request
    resources:
      - group: ""
        resources: ["secrets"]
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pod"]
  - level: none
```

there are might be a few issues that you could notice immediately, but lets focus on them in a moment. The next
setup from the setup instructions is to update the configuration of the kube-apiserver by adding audit policy command
line options and volumes through which the audit policy will be accessible inside the kube-apiserver container and the
produced audit file will be readable on the control plane node:

```shell
$ sudo nano  /etc/kubernetes/manifests/kube-apiserver.yaml && cat $_

apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 172.31.17.197:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=172.31.17.197
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=10.96.0.0/12
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    - --audit-policy=/etc/kubernetes/audit-policy.yaml                       # Added audit policy file option
    - --audit-log-path=/var/log/kubernetes/audit/audit.log                   # Added audit log file path option
    image: registry.k8s.io/kube-apiserver:v1.29.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 172.31.17.197
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-apiserver
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 172.31.17.197
        path: /readyz
        port: 6443
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 250m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 172.31.17.197
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/ca-certificates
      name: etc-ca-certificates
      readOnly: true
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /usr/local/share/ca-certificates
      name: usr-local-share-ca-certificates
      readOnly: true
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
    - mountPath: /etc/kubernetes/audit-policy.yaml                 # Added VolumeMount for the audit policy volume
      name: audit
      readOnly: true
    - mountPath: /var/log/kubernetes/audit/                        # Added VolumeMount for the audit log file volume
      name: audit-log
      readOnly: false
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/ca-certificates
      type: DirectoryOrCreate
    name: etc-ca-certificates
  - hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /usr/local/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-local-share-ca-certificates
  - hostPath:
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-share-ca-certificates
  - name: audit                                               # Added the Audit policy volume
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
  - name: audit-log                                          # Added the Audit log file volume
    hostPath:
      path: /var/log/kubernetes/audit/
      type: DirectoryOrCreate
status: {}
$
```

Done! The setup is complete and the changes has been applied to our cluster. Lets try to validate the change by checking
the state of kube-apiserver pod:

```shell
$ kubectl get po -n kube-system
The connection to the server 172.31.17.197:6443 was refused - did you specify the right host or port?
$
```

Ouch! Seems we've lost access to our kubernetes cluster. As all requests pass through the API server, it seems that there
is a problem with the configuration we've just applied, but what?

As we can't access the API server to check on the kube-apiserver mirror pod status, lets use crictl to check the sate of
the pod locally:

```shell
$ sudo crictl pods
POD ID              CREATED             STATE               NAME                                       NAMESPACE           ATTEMPT             RUNTIME
6a7f6e3fa28dc       9 minutes ago       Ready               kube-apiserver-ip-172-31-17-197            kube-system         0                   (default)
6df5eebb426e1       4 hours ago         Ready               coredns-76f75df574-7fsvg                   kube-system         1                   (default)
549c4088b5805       4 hours ago         Ready               coredns-76f75df574-h4rp7                   kube-system         1                   (default)
f602ba0454e56       4 hours ago         Ready               weave-net-zwx28                            kube-system         0                   (default)
4cd96eca569b5       4 hours ago         Ready               kube-proxy-7t4cg                           kube-system         0                   (default)
7a97edcac7d3d       4 hours ago         Ready               etcd-ip-172-31-17-197                      kube-system         0                   (default)
2ccda4a1b4cbc       4 hours ago         Ready               kube-scheduler-ip-172-31-17-197            kube-system         0                   (default)
4bf7e01627112       4 hours ago         Ready               kube-controller-manager-ip-172-31-17-197   kube-system         0                   (default)
```

It seems to be running... Lets check the logs of the kubelet. As the kubelet is responsible for managing this pod it
should be able to give us a hint what is going on:

```shell
$ journalctl -u kubelet -n 10 --no-pager
Feb 12 16:04:12 ip-172-31-17-197 kubelet[12104]: I0212 16:04:12.926951   12104 scope.go:117] "RemoveContainer" containerID="a6e080d62a9da0ecdb12f7cd0930a2e024b611a843529f66c285eda5d6f6368f"
Feb 12 16:04:12 ip-172-31-17-197 kubelet[12104]: E0212 16:04:12.927526   12104 pod_workers.go:1298] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kube-apiserver\" with CrashLoopBackOff: \"back-off 5m0s restarting failed container=kube-apiserver pod=kube-apiserver-ip-172-31-17-197_kube-system(0332406a2c4a3de48df62d6a3422892b)\"" pod="kube-system/kube-apiserver-ip-172-31-17-197" podUID="0332406a2c4a3de48df62d6a3422892b"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.058279   12104 event.go:355] "Unable to write event (may retry after sleeping)" err="Post \"https://172.31.17.197:6443/api/v1/namespaces/kube-system/events\": dial tcp 172.31.17.197:6443: connect: connection refused" event="&Event{ObjectMeta:{kube-apiserver-ip-172-31-17-197.17b32862ee172ac1  kube-system    0 0001-01-01 00:00:00 +0000 UTC <nil> <nil> map[] map[] [] [] []},InvolvedObject:ObjectReference{Kind:Pod,Namespace:kube-system,Name:kube-apiserver-ip-172-31-17-197,UID:0332406a2c4a3de48df62d6a3422892b,APIVersion:v1,ResourceVersion:,FieldPath:spec.containers{kube-apiserver},},Reason:Created,Message:Created container kube-apiserver,Source:EventSource{Component:kubelet,Host:ip-172-31-17-197,},FirstTimestamp:2024-02-12 15:51:29.069951681 +0000 UTC m=+6187.241628779,LastTimestamp:2024-02-12 15:51:29.069951681 +0000 UTC m=+6187.241628779,Count:1,Type:Normal,EventTime:0001-01-01 00:00:00 +0000 UTC,Series:nil,Action:,Related:nil,ReportingController:kubelet,ReportingInstance:ip-172-31-17-197,}"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204019   12104 kubelet_node_status.go:544] "Error updating node status, will retry" err="error getting node \"ip-172-31-17-197\": Get \"https://172.31.17.197:6443/api/v1/nodes/ip-172-31-17-197?resourceVersion=0&timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204247   12104 kubelet_node_status.go:544] "Error updating node status, will retry" err="error getting node \"ip-172-31-17-197\": Get \"https://172.31.17.197:6443/api/v1/nodes/ip-172-31-17-197?timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204426   12104 kubelet_node_status.go:544] "Error updating node status, will retry" err="error getting node \"ip-172-31-17-197\": Get \"https://172.31.17.197:6443/api/v1/nodes/ip-172-31-17-197?timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204607   12104 kubelet_node_status.go:544] "Error updating node status, will retry" err="error getting node \"ip-172-31-17-197\": Get \"https://172.31.17.197:6443/api/v1/nodes/ip-172-31-17-197?timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204792   12104 kubelet_node_status.go:544] "Error updating node status, will retry" err="error getting node \"ip-172-31-17-197\": Get \"https://172.31.17.197:6443/api/v1/nodes/ip-172-31-17-197?timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused"
Feb 12 16:04:15 ip-172-31-17-197 kubelet[12104]: E0212 16:04:15.204812   12104 kubelet_node_status.go:531] "Unable to update node status" err="update node status exceeds retry count"
Feb 12 16:04:17 ip-172-31-17-197 kubelet[12104]: E0212 16:04:17.453884   12104 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://172.31.17.197:6443/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/ip-172-31-17-197?timeout=10s\": dial tcp 172.31.17.197:6443: connect: connection refused" interval="7s"
$
```


Based on the output, it seems that the `kube-apiserver` container is in CrashLoopBackOff state. Lets check it directly
by using the crictl tool:

```shell
$ sudo crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
0b657398536c8       406945b511542       14 minutes ago      Running             kube-scheduler            3                   2ccda4a1b4cbc       kube-scheduler-ip-172-31-17-197
b32c9f520e1b1       79d451ca186a6       14 minutes ago      Running             kube-controller-manager   3                   4bf7e01627112       kube-controller-manager-ip-172-31-17-197
ea1ea4a7f439f       cbb01a7bd410d       4 hours ago         Running             coredns                   0                   6df5eebb426e1       coredns-76f75df574-7fsvg
de50f8d0dc069       cbb01a7bd410d       4 hours ago         Running             coredns                   0                   549c4088b5805       coredns-76f75df574-h4rp7
c6ac18d5e6532       df29c0a4002c0       4 hours ago         Running             weave                     1                   f602ba0454e56       weave-net-zwx28
0234fbb8aacde       7f92d556d4ffe       4 hours ago         Running             weave-npc                 0                   f602ba0454e56       weave-net-zwx28
1e199444826b1       43c6c10396b89       4 hours ago         Running             kube-proxy                0                   4cd96eca569b5       kube-proxy-7t4cg
60f275dcf3635       a0eed15eed449       4 hours ago         Running             etcd                      0                   7a97edcac7d3d       etcd-ip-172-31-17-197
$
```

Indeed the container is not listed as running. We can list the containers in non-running state using:

```shell
$ sudo crictl ps -a --no-trunc
CONTAINER                                                          IMAGE                                                                     CREATED             STATE               NAME                      ATTEMPT             POD ID                                                             POD
5c3bf127fef16bb7c5b9aadc696cccaf6ee5d9882b29c1635cff86f0aa828489   sha256:53b148a9d1963417e1060268355fad12d3a4386aa166355222bbfe1577b794eb   2 minutes ago       Exited              kube-apiserver            8                   6a7f6e3fa28dc4e6adc391c3f420a9230c99e3640f05205f73ce644897bbc6d9   kube-apiserver-ip-172-31-17-197
0b657398536c8cd126b82ee4de299d70943a1d53f6d5a9fe12d2091aa8a5e82d   sha256:406945b5115423a8c1d1e5cd53222ef2ff0ce9d279ed85badbc4793beebebc6c   18 minutes ago      Running             kube-scheduler            3                   2ccda4a1b4cbc523091814bf0928eb3118ad31478a24e81240109fca7ee744b3   kube-scheduler-ip-172-31-17-197
...
$
```

with the `--no-trunc`  we can get the complete ID for each container which we can use to get the container logs:

```shell
$ sudo crictl logs 5c3bf127fef16bb7c5b9aadc696cccaf6ee5d9882b29c1635cff86f0aa828489
Error: unknown flag: --audit-policy
$
```

Seems that we've given the kube-apiserver a wrong command line option.... After a quick look at the [kube-apiserver](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
documentation, we can see the correct name of the options is:

```text
--audit-policy-file string
```

Lets modify the kube-apiserver.yaml file and fix this!

```shell
$ sudo nano  /etc/kubernetes/manifests/kube-apiserver.yaml && cat $_
...
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml                       # Added audit policy file option
...
$
```

After the manifest is changed it might take a few seconds for the container to be restarted. Lets validate:

```shell
$ sudo crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
0b657398536c8       406945b511542       2 hours ago         Running             kube-scheduler            3                   2ccda4a1b4cbc       kube-scheduler-ip-172-31-17-197
b32c9f520e1b1       79d451ca186a6       2 hours ago         Running             kube-controller-manager   3                   4bf7e01627112       kube-controller-manager-ip-172-31-17-197
ea1ea4a7f439f       cbb01a7bd410d       5 hours ago         Running             coredns                   0                   6df5eebb426e1       coredns-76f75df574-7fsvg
de50f8d0dc069       cbb01a7bd410d       5 hours ago         Running             coredns                   0                   549c4088b5805       coredns-76f75df574-h4rp7
c6ac18d5e6532       df29c0a4002c0       5 hours ago         Running             weave                     1                   f602ba0454e56       weave-net-zwx28
0234fbb8aacde       7f92d556d4ffe       5 hours ago         Running             weave-npc                 0                   f602ba0454e56       weave-net-zwx28
1e199444826b1       43c6c10396b89       5 hours ago         Running             kube-proxy                0                   4cd96eca569b5       kube-proxy-7t4cg
60f275dcf3635       a0eed15eed449       5 hours ago         Running             etcd                      0                   7a97edcac7d3d       etcd-ip-172-31-17-197
$
```

No luck. Lets keep looking. Lets check again the container logs:

```shell
$ sudo crictl ps -a --no-trunc
CONTAINER                                                          IMAGE                                                                     CREATED             STATE               NAME                      ATTEMPT             POD ID                                                             POD
346b7ce54f958765ba4f2e6ed539ab60cd58d48e575c7a5722825530cbe90e47   sha256:53b148a9d1963417e1060268355fad12d3a4386aa166355222bbfe1577b794eb   46 seconds ago      Exited              kube-apiserver            4                   d382230c638dd91851e85cb3007bcfbfbb4ae417e78c679df15029892ea54bff   kube-apiserver-ip-172-31-17-197
...
$
```

```shell
$ sudo crictl logs 346b7ce54f958765ba4f2e6ed539ab60cd58d48e575c7a5722825530cbe90e47
I0212 17:31:24.101774       1 options.go:222] external host was not specified, using 172.31.17.197
I0212 17:31:24.102891       1 server.go:148] Version: v1.29.1
I0212 17:31:24.102913       1 server.go:150] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
E0212 17:31:24.474189       1 run.go:74] "command failed" err="loading audit policy file: failed decoding: yaml: line 8: did not find expected key: from file /etc/kubernetes/audit-policy.yaml"
$
```

Ok, so it seems that there is a problem with the syntax of the audit-policy file on line 8. Lets review the content of the
policy file:

```shell
$ cat audit-policy.yaml
```

```yaml
apiVersion: audit.k8s.io/v1
kind: policy
omitStages:
  - "ResponseComplet"
rules:
  - level: Metadata
    verbs: ["get", "list", "watch"]
    namespaces: ["kube-system"]
      - group: ""
        resources: ["configmaps", "services"]
    omitStages:
      - "RequestReceived"
  - level: Request
    resources:
      - group: ""
        resources: ["secrets"]
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pod"]
  - level: none
```

```shell
$
```

It seems that there is a problem with this policy rule:

```yaml
  - level: Metadata
    verbs: ["get", "list", "watch"]
    namespaces: ["kube-system"]
      - group: ""
        resources: ["configmaps", "services"]
```

Can you spot the problem? Looking at the [PolicyRule](https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/#audit-k8s-io-v1-PolicyRule) documentation
we can see that the `namespaces` field is a []string type. The resources that the policy rule matches against should be
listed underneath the `resources` field. Based on that, the corrected version of this rule looks like this:

```yaml
  - level: Metadata
    verbs: ["get", "list", "watch"]
    namespaces: ["kube-system"]
    resources:
      - group: ""
        resources: ["configmaps", "services"]
```

Before we apply the changes lets compare the policy file with the expected outcome:

  - Metadata level events for requests using get, list, watch verbs against configmaps and services in the kube-system
    namespace. All stages.
  - Request level events against secrets. All stages
  - RequestResponse level events against pods. All stages.

> No other events should be present in the audit file!

The description clearly states that this policy file should match all stages of request execution. In our policy file
however we have the fields `omitStages`, which actually which acts as filter. For the stages listed underneath that field
no events will be generated! Lets remove those:

```yaml
apiVersion: audit.k8s.io/v1
kind: policy
rules:
  - level: Metadata
    verbs: ["get", "list", "watch"]
    namespaces: ["kube-system"]
    resources:
      - group: ""
        resources: ["configmaps", "services"]
  - level: Request
    resources:
      - group: ""
        resources: ["secrets"]
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pod"]
  - level: none
```

Looks much better now! Can you spot any remaining issues? Lets apply the changes to our audit-policy.yaml file and test:

```shell
$ sudo nano /etc/kubernetes/audit-policy.yaml
$
```

once the file is updated, lets force restart the kube-apiserver:

```shell
$ sudo systemctl restart kubelet
$
```

Will the API service now be operational? Lets check the container once more:

```shell
$ sudo crictl logs ad5e420681e84e5c66d6ddc3e50b523df93f8a1942d19cd51bf8b8b21e5e361d
I0212 19:07:47.821564       1 options.go:222] external host was not specified, using 172.31.17.197
I0212 19:07:47.822666       1 server.go:148] Version: v1.29.1
I0212 19:07:47.822758       1 server.go:150] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
E0212 19:07:48.196374       1 run.go:74] "command failed" err="loading audit policy file: failed decoding: no kind \"policy\" is registered for version \"audit.k8s.io/v1\" in scheme \"pkg/audit/scheme.go:30\": from file /etc/kubernetes/audit-policy.yaml"
$
```

ok, not quite. The error now states `no kind \"policy\"`.

Duh.. seems there is a typo in the value of the kind field.. It is `policy` instead of `Policy`.  While checking the
capitalization, lets check the audit level names used. There are four valid audit levels:

- None
- Metadata
- Request
- RequestResponse

Capitalization matters! In our audit policy file we've referenced the audit level `none` instead of `None` in the
catch-all section.

> Note: More resources about the API object capitalization you can find in the [sig-architecture](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#types-kinds) git repo.
> Resource collections should be all lowercase and plural, whereas kinds are CamelCase and singular. Group names must be
> lower case and be valid DNS subdomains.

Lets quickly fix those two issues:

```shell
$ sudo nano /etc/kubernetes/audit-policy.yaml && cat $_
```

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    verbs: ["get","list","watch"]
    namespaces: ["kube-system"]
    resources:
    - group: ""
      resources: ["configmaps","services"]
  - level: Request
    resources:
    - group: ""
      resources: ["secrets"]
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["pods"]
  - level: None
```

and try to apply the configuration one more time by restarting the kubelet:

```shell
$ sudo systemctl restart kubelet
$
```

Will it work this time ?

```shell
$ kubectl get no
NAME               STATUS   ROLES           AGE     VERSION
ip-172-31-17-197   Ready    control-plane   7h28m   v1.29.1
```

Yes! Lets now validate the audit.log file:

```shell
$ sudo tail -10  /var/log/kubernetes/audit/audit.log
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"RequestResponse","auditID":"71c9b507-91af-4072-b6f0-929bdde00bae","stage":"RequestReceived","requestURI":"/api/v1/pods?allowWatchBookmarks=true\u0026resourceVersion=15242\u0026timeoutSeconds=561\u0026watch=true","verb":"watch","user":{"username":"system:serviceaccount:kube-system:weave-net","uid":"5e63987d-fe80-402e-ba14-6fe59f328cda","groups":["system:serviceaccounts","system:serviceaccounts:kube-system","system:authenticated"],"extra":{"authentication.kubernetes.io/pod-name":["weave-net-zwx28"],"authentication.kubernetes.io/pod-uid":["6690fa75-2767-4cdf-ae44-68c1be6aebc3"]}},"sourceIPs":["172.31.17.197"],"userAgent":"weave-npc/v0.0.0 (linux/amd64) kubernetes/$Format","objectRef":{"resource":"pods","apiVersion":"v1"},"requestReceivedTimestamp":"2024-02-12T19:41:15.851367Z","stageTimestamp":"2024-02-12T19:41:15.851367Z"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"RequestResponse","auditID":"71c9b507-91af-4072-b6f0-929bdde00bae","stage":"ResponseStarted","requestURI":"/api/v1/pods?allowWatchBookmarks=true\u0026resourceVersion=15242\u0026timeoutSeconds=561\u0026watch=true","verb":"watch","user":{"username":"system:serviceaccount:kube-system:weave-net","uid":"5e63987d-fe80-402e-ba14-6fe59f328cda","groups":["system:serviceaccounts","system:serviceaccounts:kube-system","system:authenticated"],"extra":{"authentication.kubernetes.io/pod-name":["weave-net-zwx28"],"authentication.kubernetes.io/pod-uid":["6690fa75-2767-4cdf-ae44-68c1be6aebc3"]}},"sourceIPs":["172.31.17.197"],"userAgent":"weave-npc/v0.0.0 (linux/amd64) kubernetes/$Format","objectRef":{"resource":"pods","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"2024-02-12T19:41:15.851367Z","stageTimestamp":"2024-02-12T19:41:15.851941Z","annotations":{"authorization.k8s.io/decision":"allow","authorization.k8s.io/reason":"RBAC: allowed by ClusterRoleBinding \"weave-net\" of ClusterRole \"weave-net\" to ServiceAccount \"weave-net/kube-system\""}}
...
$
```

On a first sight it seems that our policy work as expected. We can do a bit of validation. Lets observe the content
of the audit log in one window:

```shell
$ sudo tail -f  /var/log/kubernetes/audit/audit.log
...



```

and in another window list some kubernetes api objects:

```shell
$ kubectl get secrets -A
NAMESPACE     NAME                     TYPE                            DATA   AGE
kube-system   bootstrap-token-79lnd8   bootstrap.kubernetes.io/token   7      7h34m
$
```

In the window where we monitor the audit.log, we'll notice one event being generated:

```shell
...
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"f1ded4f9-98d7-45ed-88a9-d92c3e12fa0b","stage":"RequestReceived","requestURI":"/api/v1/secrets?limit=500","verb":"list","user":{"username":"kubernetes-admin","groups":["kubeadm:cluster-admins","system:authenticated"]},"sourceIPs":["172.31.17.197"],"userAgent":"kubectl/v1.29.1 (linux/amd64) kubernetes/bc401b9","objectRef":{"resource":"secrets","apiVersion":"v1"},"requestReceivedTimestamp":"2024-02-12T19:45:43.830253Z","stageTimestamp":"2024-02-12T19:45:43.830253Z"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"f1ded4f9-98d7-45ed-88a9-d92c3e12fa0b","stage":"ResponseComplete","requestURI":"/api/v1/secrets?limit=500","verb":"list","user":{"username":"kubernetes-admin","groups":["kubeadm:cluster-admins","system:authenticated"]},"sourceIPs":["172.31.17.197"],"userAgent":"kubectl/v1.29.1 (linux/amd64) kubernetes/bc401b9","objectRef":{"resource":"secrets","apiVersion":"v1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"2024-02-12T19:45:43.830253Z","stageTimestamp":"2024-02-12T19:45:43.832204Z","annotations":{"authorization.k8s.io/decision":"allow","authorization.k8s.io/reason":"RBAC: allowed by ClusterRoleBinding \"kubeadm:cluster-admins\" of ClusterRole \"cluster-admin\" to Group \"kubeadm:cluster-admins\""}}

```

The "requestURI" is "/api/v1/secrets?limit=500", the "verb" is "list", the level is "Request", the "stage" is: "RequestReceived"
and "ResponseComplete" respectively for each of the events as we don't impose any limits on the event stages.


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
