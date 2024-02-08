![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Application Access - Solution


## Solution

After applying the `problem.yaml`, check the pod status and logs. The pod is in a completed state, but when checking the
pod logs an error is present:

```shell
$ kubectl get pods -n security-1

NAME                READY   STATUS      RESTARTS   AGE
security-1-client   0/1     Completed   0          40s

$ kubectl -n security-1 logs security-1-client

fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/community/x86_64/APKINDEX.tar.gz
(1/4) Installing ca-certificates (20191127-r4)
(2/4) Installing nghttp2-libs (1.41.0-r0)
(3/4) Installing libcurl (7.69.1-r1)
(4/4) Installing curl (7.69.1-r1)
Executing busybox-1.31.1-r19.trigger
Executing ca-certificates-20191127-r4.trigger
OK: 7 MiB in 18 packages
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:security-1:pod-op\" cannot list resource \"pods\" in API group \"\" in the namespace \"security-1\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
100   336  100   336    0     0  56000      0 --:--:-- --:--:-- --:--:-- 56000
}

$
```

It looks like the permissions are not allowing the pod, which needs the `GET` and `LIST` rest permissions to properly
request a list of pods in its namespace.

Identify the role in the pod's namespace and view its yaml spec:

```shell
$ kubectl get role -n security-1

NAME       CREATED AT
pod-crud   2020-12-09T00:24:44Z

$ kubectl get role -n security-1 -o yaml

apiVersion: v1
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"annotations":{},"name":"pod-crud","namespace":"security-1"},"rules":[{"apiGroups":[""],"resources":["pods"],"verbs":["create"]}]}
    creationTimestamp: "2020-12-09T00:24:44Z"
    managedFields:
    - apiVersion: rbac.authorization.k8s.io/v1
      fieldsType: FieldsV1
      fieldsV1:
        f:metadata:
          f:annotations:
            .: {}
            f:kubectl.kubernetes.io/last-applied-configuration: {}
        f:rules: {}
      manager: kubectl-client-side-apply
      operation: Update
      time: "2020-12-09T00:24:44Z"
    name: pod-crud
    namespace: security-1
    resourceVersion: "859104"
    selfLink: /apis/rbac.authorization.k8s.io/v1/namespaces/security-1/roles/pod-crud
    uid: de14107d-bda6-48fe-89d6-8950165b8f65
  rules:
  - apiGroups:
    - ""
    resources:
    - pods
    verbs:
    - create
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""

$
```

The role only has the `CREATE` verb associated with it. You need to add the `GET` and `LIST` verbs to this role.

Edit the role using `kubectl edit`:

```shell
$ kubectl edit role -n security-1 pod-crud

role.rbac.authorization.k8s.io/pod-crud edited

$
```

While you make your edits, add `get` and `list` in the verbs for the pod permissions:

```yaml
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - create
  - get
  - list
```

Now take a backup of the running pod, delete it, and reapply.

```shell
$ kubectl get pod -n security-1 security-1-client -o yaml > security-1-client.yaml

$ kubectl delete -f security-1-client.yaml

pod "security-1-client" deleted

$ kubectl apply -f security-1-client.yaml

pod/security-1-client created

$ kubectl get pods -n security-1 security-1-client
NAME                READY   STATUS      RESTARTS   AGE
security-1-client   0/1     Completed   0          10s

$
```

If you check the log, you will see the full printout of the pod listing, as intended:

```shell
$ kubectl -n security-1 logs security-1-client
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/community/x86_64/APKINDEX.tar.gz
(1/4) Installing ca-certificates (20191127-r4)
(2/4) Installing nghttp2-libs (1.41.0-r0)
(3/4) Installing libcurl (7.69.1-r1)
(4/4) Installing curl (7.69.1-r1)
Executing busybox-1.31.1-r19.trigger
Executing ca-certificates-20191127-r4.trigger
OK: 7 MiB in 18 packages
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11093    0 11093    0     0  1354k      0 --:--:-- --:--:-- --:--:-- 1354k
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/security-1/pods/",
    "resourceVersion": "859876"
  },
  "items": [

...

}

$
```

The pod is in the compeleted status, and the logs are clear of any errors, which was the condition for the fix.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_