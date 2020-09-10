# Bust-a-Kube


## Problem 1 - A broken pod

### Solution

The init container image name is incorrect due to bad formatting. Change the image name to `alpine` or `alpine:latest` to correct the issue.

```
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
```

Run `kubectl describe pod debug-pod1` and look at the events. you will see that the Kubelet was unable to instruct
Docker to pull the image.



<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
