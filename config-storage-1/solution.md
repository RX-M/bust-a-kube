# Problem 2 - Pod Scheduling


## Solution

After you apply `problem.yaml`, use `kubectl get pods` to view the status. You will see that the pod is in a Pending
state:

```
ubuntu@labsys:~$ kubectl get pods

NAME          READY   STATUS    RESTARTS   AGE
test-server   0/1     Pending   0          7s

ubuntu@labsys:~$
```

To get more information, use `kubectl describe pod` on `test-server` to see if there are any relevant events or other
information that could help debug the issue:

```
ubuntu@labsys:~$ kubectl describe pods test-server

Name:         test-server
Namespace:    default
Priority:     0
Node:         <none>
Labels:       <none>
Annotations:  <none>
Status:       Pending
IP:
IPs:          <none>
Containers:
  test-server:
    Image:        httpd
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-fqlsn (ro)
      /var/www/ from test-webpages (rw)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  test-webpages:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  bak-pvc
    ReadOnly:   false
  default-token-fqlsn:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-fqlsn
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From  Message
  ----     ------            ----  ----  -------
  Warning  FailedScheduling  12s         0/2 nodes are available: 2 pod has unbound immediate PersistentVolumeClaims.
  Warning  FailedScheduling  12s         0/2 nodes are available: 2 pod has unbound immediate PersistentVolumeClaims.

ubuntu@labsys:~$
```

According to the events, there is an unbound PersistentVolumeClaim. If you examine the describe output, you will see
that the pod is using a pvc named `bak-pvc`. Use `kubectl describe pvc` on it to see if there are any additional details
you can get:

```
ubuntu@labsys:~$ kubectl describe pvc bak-pvc

Name:          bak-pvc
Namespace:     default
StorageClass:
Status:        Pending
Volume:
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Mounted By:    test-server
Events:
  Type    Reason         Age               From                         Message
  ----    ------         ----              ----                         -------
  Normal  FailedBinding  9s (x2 over 22s)  persistentvolume-controller  no persistent volumes available for this claim and no storage class is set

ubuntu@labsys:~$
```

So according to the PVC, there are no persistent volumes available for the claim, and there is no storage class set. But
when you applied the problem, the PV was created. Use `kubectl get` or `kubectl describe` on the PV to get more
information:

```
ubuntu@labsys:~$ kubectl get pv

NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
bak-pv   100Mi      RWO            Retain           Available           static                  27s

ubuntu@labsys:~$
```

Based on this output, you can conclude that:

- The PVC storage request matches the PV's capacity
- The access mode, `ReadWriteOnce`, is consistent between the PV and the PVC
- The PV has a `StorageClass` attribute called `static` which the PVC is not using

The issue here is that the PVC is not declaring a storage class name, so it cannot bind to the `bak-pv` persistent
volume. This is where the issue is. To fix this, you will need to delete and recreate the PVC because the PVC spec is immutable while the PVC is unbound (and even when bound, only the requests.storage field can be changed).

Retrieve a YAML copy of the PVC from the cluster with `kubectl get` and the `-o yaml` flag. Once you save the file:

- Remove all of the metadata keys **except** `name`
- Add `storageClassName: static` to the `spec` section
- Remove the `status` section and any keys below it

```
ubuntu@labsys:~$ kubectl get pvc bak-pvc -o yaml > bak-pvc-fix.yaml

ubuntu@labsys:~$ nano bak-pvc-fix.yaml && cat bak-pvc-fix.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: bak-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  volumeMode: Filesystem
  storageClassName: static

ubuntu@labsys:~$
```

If you have any trouble, use the spec above as a reference for your changes. Once your YAML file is prepared, use
`kubectl` to `delete` and `apply` the file. Since the YAML file describes the same object (the PVC `bak-pvc`) it will
remove the existing instance of the object from your cluster:

```
ubuntu@labsys:~$ kubectl delete -f bak-pvc-fix.yaml

persistentvolumeclaim "bak-pvc" deleted

ubuntu@labsys:~$ kubectl apply -f bak-pvc-fix.yaml

persistentvolumeclaim/bak-pvc created

ubuntu@labsys:~$
```

Once you recreate the PVC, check its status. The `bak-pvc` is now `Bound` and the pod will eventually go into the
`Running` status.

```
ubuntu@labsys:~$ kubectl get pvc

NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
bak-pvc   Bound    bak-pv   100Mi      RWO            static         6s

ubuntu@labsys:~$ kubectl get pods

NAME          READY   STATUS    RESTARTS   AGE
test-server   1/1     Running   0          101s

ubuntu@labsys:~$
```

The pod is in the `Running` state with all containers Ready. Consider the issue resolved!


<br>

_Copyright (c) 2020-2022 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
