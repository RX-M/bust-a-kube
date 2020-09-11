# Problem 1 - Pods


## Solution

After you apply the pod, use `kubectl get pods` to view the status. You will see that the pod is not ready, 
and has a status of Init:ImagePullBackOff. Note that the "Init:" prefix implies that this is a failure with 
the init contianer not one of the normal contianers in the pod.

```
ubuntu@labsys:~$ kubectl get pods

NAME         READY   STATUS                  RESTARTS   AGE
debug-pod1   0/1     Init:ImagePullBackOff   0          43s

ubuntu@labsys:~$
```

Run `kubectl describe pod debug-pod1` and look at the events. You will see that the Kubelet was unable to pull 
the specified image using the contianer manager:

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

Take a close look at the init contianer image name. If you check docker hub you will see that no such image exists. The init 
container image name is incorrect/mis-formated. Change the image name to `alpine` or `alpine:latest` to correct the issue. 

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
    image: alpine:latest 

    command: ["/bin/sh", "-c"]
    args: ["echo hello"]
  containers:
  - name: myapp-container
    image: busybox
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]

ubuntu@labsys:~$
```

You can only edit some of the fields in running pods, and image is not one of them. To apply the fix you will need to 
delete the pod and recreate it. If this pod were created by a deployment or another controller, updating the pod spec 
in the parent resource would perform the update for you.

```
ubuntu@labsys:~$ kubectl delete -f pod-debug-1.yaml

pod "debug-pod1" deleted

ubuntu@labsys:~$ kubectl apply -f pod-debug-1.yaml

pod/debug-pod1 created

ubuntu@labsys:~$
```

Check the pod status with `kubectl get pods` and you should see the pod running:

```
ubuntu@labsys:~$ kubectl get pods debug-pod1

NAME         READY   STATUS    RESTARTS   AGE
debug-pod1   1/1     Running   0          36s

ubuntu@labsys:~$
```

You can display the pod logs with `kubectl logs` to verify the log output from the init contianer.


<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
