# Problem 2 - Pod Scheduling


## Solution

After you apply the pod, use `kubectl get pods` to view the status. You will see that the pod is not ready, and likely
in the ImagePullBackOff status:

```
ubuntu@labsys:~$ kubectl get pods pod-debug-2

NAME          READY   STATUS    RESTARTS   AGE
pod-debug-2   0/2     Pending   0          67s

ubuntu@labsys:~$
```

Run `kubectl describe pod debug-pod1` and look at the events. you will see that the pod is still in a Pending state
because the scheduler could not find a node that matched the desired node selector:

```
ubuntu@labsys:~$ kubectl describe pods pod-debug-2

Name:         pod-debug-2
Namespace:    default
Priority:     0
Node:         <none>
Labels:       run=pod-debug-2
Annotations:  <none>
Status:       Pending

...

Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  55s (x3 over 2m13s)  default-scheduler  0/3 nodes are available: 3 node(s) didn't match node selector.

ubuntu@labsys:~$
```

There are two possible solutions depending on your level of access to the cluster:

1. Label one or more of your worker nodes with the label sought by the nodeSelector

If you have permissions to view and label the nodes, then you can resolve this issue by adding the label
`context=frontend` to one or more of your worker nodes.

First, check the pod spec and see if there are any nodeSelectors with `cat` and `grep`:

```
ubuntu@labsys:~$ cat pod-debug-2.yaml | grep nodeSelector -A5

  nodeSelector:
    context: frontend
  volumes:
  - emptyDir: {}
    name: share

ubuntu@labsys:~$
```

Then, use `kubectl label` to label apply the `context=frontend` label to one or more of your nodes:

```
ubuntu@labsys:~$ kubectl label node sept-b context=frontend

node/sept-b labeled

ubuntu@labsys:~$
```

When the scheduler attempts to schedule the pod, it will now find a valid node and the pod will create and run its
containers:

```
ubuntu@labsys:~$ kubectl describe pods pod-debug-2 | grep Events -A15

Events:
  Type     Reason            Age                    From               Message
  ----     ------            ----                   ----               -------
  Warning  FailedScheduling  3m40s (x6 over 9m28s)  default-scheduler  0/3 nodes are available: 3 node(s) didn't match node selector.
  Normal   Scheduled         2m35s                  default-scheduler  Successfully assigned default/pod-debug-2 to sept-b
  Normal   Pulling           2m34s                  kubelet, sept-b    Pulling image "centos/httpd"
  Normal   Pulled            2m17s                  kubelet, sept-b    Successfully pulled image "centos/httpd" in 17.601537202s
  Normal   Created           2m16s                  kubelet, sept-b    Created container httpd
  Normal   Started           2m16s                  kubelet, sept-b    Started container httpd
  Normal   Pulling           2m16s                  kubelet, sept-b    Pulling image "fluent/fluent-bit"
  Normal   Pulled            2m5s                   kubelet, sept-b    Successfully pulled image "fluent/fluent-bit" in 11.62322163s
  Normal   Created           2m5s                   kubelet, sept-b    Created container sidecar-logger
  Normal   Started           2m5s                   kubelet, sept-b    Started container sidecar-logger

ubuntu@labsys:~$ kubectl get pods pod-debug-2

NAME          READY   STATUS    RESTARTS   AGE
pod-debug-2   2/2     Running   0          10m

ubuntu@labsys:~$
```

2. Remove (or adjust) the nodeSelector from the pod spec

If you do not have permissions to view nodes in your cluster, then your only option is to change the pod spec by either
removing the nodeSelector key all together or using a known label. In this solution, we will simply remove the key:

```
ubuntu@labsys:~$ nano pod-debug-2.yaml && cat pod-debug-2.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod-debug-2
  name: pod-debug-2
spec:
  containers:
  - image: centos/httpd
    name: httpd
    volumeMounts:
    - name: share
      mountPath: /var/log/httpd
  - command:
    - /fluent-bit/bin/fluent-bit
    - -i
    - tail
    - -p
    - path=/httpd/access_log
    - -o
    - stdout
    image: fluent/fluent-bit
    name: sidecar-logger
    volumeMounts:
    - name: share
      mountPath: /httpd
  restartPolicy: Never
  volumes:
  - emptyDir: {}
    name: share

ubuntu@labsys:~$
```

Then delete and recreate the pod using the updated spec:

```
ubuntu@labsys:~$ kubectl delete pod pod-debug-2

pod "pod-debug-2" deleted

ubuntu@labsys:~$ kubectl apply -f pod-debug-2.yaml

pod/pod-debug-2 created

ubuntu@labsys:~$
```

If your cluster has no other labels or tainted nodes, your pod will schedule without issue:

```
ubuntu@labsys:~$ kubectl get pods pod-debug-2

NAME          READY   STATUS    RESTARTS   AGE
pod-debug-2   2/2     Running   0          2m2s

ubuntu@labsys:~$
```

<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
