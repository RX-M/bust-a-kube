# Bust-a-Kube


## Problem 1 - A broken pod

### Solution

After you apply the pod, use `kubectl get pods` to view the status. You will see that the pod is not ready, and likely in the ImagePullBackOff status:

```
ubuntu@labsys:~$ kubectl get pods

NAME         READY   STATUS                  RESTARTS   AGE
debug-pod1   0/1     Init:ImagePullBackOff   0          43s

ubuntu@labsys:~$
```

Run `kubectl describe pod debug-pod1` and look at the events. you will see that the Kubelet was unable to instruct
Docker to pull the image:

```
ubuntu@labsys:~$ kubectl describe pods debug-pod1
Name:         debug-pod1
Namespace:    default
Priority:     0
Node:         sept-b/192.168.229.155
Start Time:   Thu, 10 Sep 2020 10:36:05 -0700
Labels:       app=debug-pod1
Annotations:  <none>
Status:       Pending

...

Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  83s                default-scheduler  Successfully assigned default/debug-pod1 to sept-b
  Normal   Pulling    42s (x3 over 82s)  kubelet, sept-b    Pulling image "alpinelatest"
  Warning  Failed     40s (x3 over 80s)  kubelet, sept-b    Failed to pull image "alpinelatest": rpc error: code = Unknown desc = Error response from daemon: pull access denied for alpinelatest, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  Warning  Failed     40s (x3 over 80s)  kubelet, sept-b    Error: ErrImagePull
  Normal   BackOff    12s (x4 over 79s)  kubelet, sept-b    Back-off pulling image "alpinelatest"
  Warning  Failed     12s (x4 over 79s)  kubelet, sept-b    Error: ImagePullBackOff
ubuntu@labsys:~$
```

The init container image name is incorrect due to bad formatting. Change the image name to `alpine` or `alpine:latest` to correct the issue. For other images that may not use the `latest` tag, look up the

```
ubuntu@labsys:~$ nano pod-debug-1.yaml && cat pod-debug-1.yaml

apiVersion: v1
kind: Pod
metadata:
  name: debug-pod1
  labels:
    app: debug-pod1
spec:
  initContainers:
  - name: init-container
    image: alpine:latest ### change to alpine:latesty

    command: ["/bin/sh", "-c"]
    args: ["echo hello"]
  containers:
  - name: myapp-container
    image: busybox
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]

ubuntu@labsys:~$
```

You cannot edit all of the fields for pods, so in order to apply the fix you will need to delete the pod and recreate it. If this pod were created by the deployment or another controller, update the pod spec in the parent resource and a rolling update will do the same thing.

```
ubuntu@labsys:~$ kubectl delete -f pod-debug-1.yaml

pod "debug-pod1" deleted

ubuntu@labsys:~$ kubectl apply -f pod-debug-1.yaml

pod/debug-pod1 created

ubuntu@labsys:~$
```

Now if you check the pod status with `kubectl get pods` you will see that it successfully completed:

```
ubuntu@labsys:~$ kubectl get pods debug-pod1

NAME         READY   STATUS    RESTARTS   AGE
debug-pod1   1/1     Running   0          36s

ubuntu@labsys:~$
```


<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
