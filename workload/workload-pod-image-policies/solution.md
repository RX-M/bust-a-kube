# Problem 1 - Pods


## Solution

After you apply the pod, use `kubectl get pods` to view the status. You will see that the pod is completed,
and has a status of `ErrImageNeverPull`. It seems there is some issue with the image.

```
ubuntu@labsys:~$ kubectl get pods
NAME               READY   STATUS              RESTARTS      AGE
pod-debug-image   0/1     ErrImageNeverPull   0             10m
```

Run `kubectl events` and look at the events. You will see that the `kubelet` was unable to pull
the specified image using the container manager. You can also use `kubectl describe pod pod-debug-image` to get more details.

```
ubuntu@labsys:~$ kubectl events
LAST SEEN                TYPE      REASON              OBJECT                MESSAGE
7m31s                    Normal    Scheduled           Pod/pod-debug-image   Successfully assigned default/pod-debug-image to bust-a-cube-control-plane
5m40s (x10 over 7m31s)   Warning   ErrImageNeverPull   Pod/pod-debug-image   Container image "busybox:1.36.1" is not present with pull policy of Never
5m40s (x10 over 7m31s)   Warning   Failed              Pod/pod-debug-image   Error: ErrImageNeverPull
```


The `imagePullPolicy` determines when the kubelet should pull the image from the registry.

There are three possible values for `imagePullPolicy`:

- `Always`: This means the kubelet always attempts to pull the latest image. Use this policy to ensure you're always
running the latest version of the image.
- `IfNotPresent`: The kubelet pulls the image if it is not already present on the node. This is useful for using local
images that might not be present in a registry or to reduce network traffic.
- `Never`: This tells the kubelet to never pull the image; it assumes the image is already present on the node.


In our case the image is not presented on the worker node, so we have two options over here:

### Solution 1:

Change the `imagePullPolicy` to `Always` or `IfNotPresent` in the pod definition file and reapply the pod.


```yaml

apiVersion: v1
kind: Pod
metadata:
  name: pod-debug-image2
  labels:
    app: pod-debug-image2
spec:
  containers:
  - name: image-pull
    image: busybox:1.35.0
    imagePullPolicy: IfNotPresent # Change this to IfNotPresent or Always
    command: ["/bin/sh", "-c", "echo image is successfully pulled"]
```

We can use the `kubectl replace` command to update the pod definition file. This command will delete the existing pod
and will create a new pod with the updated definition file. We are doing that because we cannot change the `imagePullPolicy`
on the fly.

```
ubuntu@labsys:~$ kubectl replace --force -f problem.yaml
pod "pod-debug-image" deleted
pod/pod-debug-image replaced
```
Sometimes you cannot change the `imagePullPolicy` in the pod definition file because of a arch design, so you can use
the second solution.

### Solution 2:

Pull the image manually on the worker node using the `docker pull` or `crictl pull` command. Because we are not sure
what k8s setup you have we will assume that you can access the worker node shell.

Lets first identify the worker node where the pod is running we can use the `-o wide` option to get the node name.

```
ubuntu@labsys:~$ kubectl get pods
NAME              READY   STATUS              RESTARTS         AGE   IP           NODE                        NOMINATED NODE   READINESS GATES
pod-debug-image   0/1     ErrImageNeverPull   11 (3m50s ago)   37m   10.244.0.5   bust-a-cube-control-plane   <none>           <none>
```

You can also use the `kubectl describe pod pod-debug-image` command to get the node name.

```
ubuntu@labsys:~$ kubectl describe pod pod-debug-image| grep Node:
Node:             bust-a-cube-control-plane/172.18.0.2

```

From here we can see our worker node.

We assume that you can access your worker node shell, so you can pull the image.

```
root@bust-a-cube-control-plane:/# crictl pull busybox:1.36.1
Image is up to date for sha256:3e4fd538a9a0b729be05707cf805388be2fb701cfd5d44c6542f1988e8aef6e3
```

Now when we have the image on the worker node lets check the status of the pod. We will also check the logs to see if the image is successfully pulled.

```
ubuntu@labsys:~$ kubectl get pods
NAME              READY   STATUS      RESTARTS   AGE
pod-debug-image   0/1     Completed   0          15s
```

Here is the logs output from our pod ensuring the echo message is executed correctly.
```
ubuntu@labsys:~$ kubectl logs pod-debug-image
image is successfully pulled
```

Here is now the `events` output:

```
ubuntu@labsys:~$ kubectl events
7m31s                    Normal    Scheduled           Pod/pod-debug-image   Successfully assigned default/pod-debug-image to bust-a-cube-control-plane
5m40s (x10 over 7m31s)   Warning   ErrImageNeverPull   Pod/pod-debug-image   Container image "busybox:1.36.1" is not present with pull policy of Never
5m40s (x10 over 7m31s)   Warning   Failed              Pod/pod-debug-image   Error: ErrImageNeverPull
42s (x4 over 88s)        Normal    Created             Pod/pod-debug-image    Created container image-pull
42s (x4 over 88s)        Normal    Started             Pod/pod-debug-image    Started container image-pull
42s (x4 over 88s)        Normal    Pulled              Pod/pod-debug-image    Container image "busybox:1.36.1" already present on machine

```

You can see that the moment we pulled the image manually, the pod status changed to `Completed` and the logs show that the image is successfully pulled.

### Caution

Be aware that you manually pull the image on the worker node and if we have multiple worker nodes, you need to pull the
image on all the worker nodes. Because you don't know which worker node the pod will be scheduled on in case of failure
or other circumstances.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"

