![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Pod Classification


## Solution

After you apply the pod, Run `kubectl describe pod frontend-stable` and confirm the issue. Next to QOS Class, you should see the classification Burstable:

```shell
$ kubectl describe pod frontend-stable
Name:         frontend-stable

...

QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From                     Message
  ----    ------     ----  ----                     -------
  Normal  Scheduled  6s                             Successfully assigned default/frontend-stable to ip-172-31-66-3
  Normal  Pulling    5s    kubelet, ip-172-31-66-3  Pulling image "httpd"
  Normal  Pulled     5s    kubelet, ip-172-31-66-3  Successfully pulled image "httpd" in 195.026047ms
  Normal  Created    5s    kubelet, ip-172-31-66-3  Created container frontend-stable
  Normal  Started    5s    kubelet, ip-172-31-66-3  Started container frontend-stable

$
```

To receive the `Guaranteed` QOS Class from Kubernetes, the following conditions must be met:

- Every container in the pod must be configured with a resource request and resource limit
- The resource request and limit values must be the same

Check the `kubectl describe` output again, and look at the container configuration and its resource requests:

```shell
Containers:
  frontend-stable:
    Container ID:   docker://4eada74472910436e65619d950c68618abca3f6923194436b9597d6fbc1cc1a6
    Image:          httpd
    Image ID:       docker-pullable://httpd@sha256:5ce7c20e45b407607f30b8f8ba435671c2ff80440d12645527be670eb8ce1961
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Fri, 18 Sep 2020 13:54:22 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     300
      memory:  512Mi
    Requests:
      cpu:        300m
      memory:     512Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-fqlsn (ro)
```

You will see that the pod's container has both a resource limit and request specified, but the limit is much higher
(limiting the container to use up to 300 CPUs!) than the request. Given that the memory requests on both are the same
and the cpu in the request is the same number (but omits the _m_ unit), it looks like the request should be `300m`
rather than `300`.

To correct this, you need to make the resource request and limits match by adjusting the CPU limit to `300m`.

> Raising the CPU request to 300 is not an option because the pod will never schedule unless you have a grossly
> overprovisioned host or supercomputer as a worker node in your cluster.

Retrieve the YAML spec from the cluster by using `kubectl get` and the `-o yaml` flag.

```shell
$ kubectl get pods -o yaml frontend-stable > frontend-fix.yaml
```

After you retrieve the YAML spec, make the following changes:

- Remove all of the metadata subkeys aside from `name` and `labels` arrays
- Remove the `status` key and all of its subkeys
- Set the value of spec.containers[].resources.limits.cpu to `300m`

```shell
$ nano frontend-fix.yaml && cat frontend-fix.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    role: frontend
  name: frontend-stable
spec:
  containers:
  - image: httpd
    imagePullPolicy: Always
    name: frontend-stable
    ports:
    - containerPort: 80
      protocol: TCP
    resources:
      limits:
        cpu: 300m                ### Set to 300m
        memory: 512Mi
      requests:
        cpu: 300m
        memory: 512Mi
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-fqlsn
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: ip-172-31-66-3
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: OnFailure
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-fqlsn
    secret:
      defaultMode: 420
      secretName: default-token-fqlsn

$
```

Resources cannot be edited on a pod that is already running, so to implement the fix you need to remove the existing instance of the pod and recreate it:

```shell
$ kubectl delete -f frontend-fix.yaml

pod "frontend-stable" deleted

$ kubectl apply -f frontend-fix.yaml

pod/frontend-stable created

$
```

Now check the pod with `kubectl get` and inspect its QoS Class with `kubectl describe`:

```shell
$ kubectl get pods

NAME              READY   STATUS    RESTARTS   AGE
frontend-stable   1/1     Running   0          83s
$ kubectl describe pod frontend-stable
Name:         frontend-stable
Namespace:    default
Priority:     0
Node:         ip-172-31-66-3/172.31.66.3
Start Time:   Fri, 18 Sep 2020 14:33:42 +0000
Labels:       role=frontend
Annotations:  <none>
Status:       Running
IP:           10.44.0.1
IPs:
  IP:  10.44.0.1
Containers:
  frontend-stable:
    Container ID:   docker://39bd065b7464ce229185b16331974aa4317818f962f8b075cba91b525f41f625
    Image:          httpd
    Image ID:       docker-pullable://httpd@sha256:5ce7c20e45b407607f30b8f8ba435671c2ff80440d12645527be670eb8ce1961
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Fri, 18 Sep 2020 14:33:43 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     300m
      memory:  512Mi
    Requests:
      cpu:        300m
      memory:     512Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-fqlsn (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-fqlsn:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-fqlsn
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason   Age   From                     Message
  ----    ------   ----  ----                     -------
  Normal  Pulling  84s   kubelet, ip-172-31-66-3  Pulling image "httpd"
  Normal  Pulled   84s   kubelet, ip-172-31-66-3  Successfully pulled image "httpd" in 142.813207ms
  Normal  Created  84s   kubelet, ip-172-31-66-3  Created container frontend-stable
  Normal  Started  83s   kubelet, ip-172-31-66-3  Started container frontend-stable

$
```

With the pod running with all of its containers ready and the QoS Class of `Guaranteed` assigned to the pod, the issue
is now resolved!


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_