![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Network Policy - Pod Isolation Problem


## Solution

After you apply the `problem.yaml` spec, a number of resources will be created:

```shell
$ kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/service-networking/network-policy-pod-isolation-problem/problem.yaml
namespace/netpolicy-problem created
pod/server created
pod/client created
networkpolicy.networking.k8s.io/restrict-server-access created
$
```

Use the command `kubectl get ns --show-labels` to validate that the Namespace has been created as expected:

```shell
$ kubectl get ns --show-labels
NAME                STATUS   AGE    LABELS
default             Active   108m   kubernetes.io/metadata.name=default
kube-node-lease     Active   108m   kubernetes.io/metadata.name=kube-node-lease
kube-public         Active   108m   kubernetes.io/metadata.name=kube-public
kube-system         Active   108m   kubernetes.io/metadata.name=kube-system
netpolicy-problem   Active   21m    kubernetes.io/metadata.name=netpolicy-problem,problem=netpolicy
$
```

You can use the `kubectl -n netpolicy-problem get pods,netpol --show-labels -o wide` command to get more details about
the created pods and network policies in the `netpolicy-problem` namespace, including labels and IP addresses:

```shell
$ kubectl -n netpolicy-problem get pods,netpol --show-labels -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP               NODE             NOMINATED NODE   READINESS GATES   LABELS
pod/client   1/1     Running   0          18m   10.244.147.207   netpol-problem   <none>           <none>            role=client
pod/server   1/1     Running   0          18m   10.244.147.208   netpol-problem   <none>           <none>            role=server

NAME                                                     POD-SELECTOR   AGE   LABELS
networkpolicy.networking.k8s.io/restrict-server-access   role=server    18m   <none>
```

On a first sight everything looks good, so lets try to connect to the client pod and test the connectivity by first
connecting to the client pod:

```shell
 kubectl -n netpolicy-problem exec -it client -- /bin/sh
/ #
```

Lets use wget to test the connectivity to the server pod. We'll use the IP address of the server we've seen earlier:

```shell
/ # wget -O- 10.244.147.208
Connecting to 10.244.147.208 (10.244.147.208:80)
wget: can't connect to remote host (10.244.147.208): Operation timed out
/ #
```

The wget command seems to get stuck for a while before output the `Operation timed out` error.

> Note: it might be intuitive to attempt testing connectivity using ping instead of wget, but according to the documentation
> the behavior of the network policies when protocols like ICMP are used is CNI plugin specific:

```text
NetworkPolicy is defined for layer 4 connections (TCP, UDP, and optionally SCTP). For all the other protocols, the behaviour may vary across network plugins.

...

When a deny all network policy is defined, it is only guaranteed to deny TCP, UDP and SCTP connections. For other protocols,
such as ARP or ICMP, the behavior is undefined.
```


So what we do next ?

We already know that pods are in a running state. By default any pod in the kubernetes cluster should be able to reach any
other pod directly. The only think that might be blocking the connectivity in our setup seems to be the NetworkPolicy.

Lets check the network policy definition:

```shell
$ kubectl -n netpolicy-problem describe netpol
Name:         restrict-server-access
Namespace:    netpolicy-problem
Created on:   2024-02-09 17:37:41 +0200 EET
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     role=server
  Allowing ingress traffic:
    To Port: 8080/TCP
    From:
      NamespaceSelector: problem=netproblem
      PodSelector: role=clint
  Not affecting egress traffic
  Policy Types: Ingress
$
```

Network Policies are namespaced objects. We've seen that network policy was already created in the correct namespace
`netpolicy-problem`, so that looks ok. For the network policy rules to be associated with specific pods the namespace,
we use the `PodSelector` field:

```shell
 PodSelector:     role=server
```

Based on the value of the PodSelector, the policy will be attached to pods labeled with a key named `role` having a value
`server`.

Lets check the labels of the pods again:

```shell
$ kubectl -n netpolicy-problem get po --show-labels
NAME     READY   STATUS    RESTARTS   AGE   LABELS
client   1/1     Running   0          63m   role=client
server   1/1     Running   0          63m   role=server
$
```

It seems that the server pod has a label matching the policy PodSelector. So far so good!
Lets focus next on the second part of the output from describe policy:

```shell
  Allowing ingress traffic:
    To Port: 8080/TCP
    From:
      NamespaceSelector: problem=netproblem
      PodSelector: role=clint
  Not affecting egress traffic
  Policy Types: Ingress
```

From the output we see that:

- the network policy is not affecting any egress traffic (not relevant for our problem scenario anyway):

```shell
Not affecting egress traffic
```

- the policy defines only `Ingress` type of restriction and as the network policy is matching only the server pod,
  only the incoming connections to the server pod are impacted.

- The `To` field indicates that the network policy allow only ingress traffic to port 8080/tcp. So far we've not seen
  on which port the container in the server pod listens. Lets take a look:

```shell
$ kubectl -n netpolicy-problem describe po server
Name:             server
Namespace:        netpolicy-problem
Priority:         0
Service Account:  default
...
Containers:
  server:
    Container ID:   docker://5f6e10b6a306130fff362bbccfd556991c5ddb51f0c2ad7f4740c49fe2faa80c
    Image:          nginx
    Image ID:       docker-pullable://nginx@sha256:84c52dfd55c467e12ef85cad6a252c0990564f03c4850799bf41dd738738691f
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
```

Based on the output, the pod in the container listens on port 80/tcp, but the network policy allows only connections on port
8080/tcp. This is something that we should definitely address but first lets review the rest of the policy!

- The next section of the output from describe policy contain a single `From` field narrowing down the allowed sources of
  ingress connections:

```shell
    From:
      NamespaceSelector: problem=netproblem
      PodSelector: role=clint
```

This field contains both `NamespaceSelector` and a `PodSelector`. For an ingress connection to the pod to be allowed,
both selectors must the be satisfied i.e they enable only ingress connections from pods having a label: `role=clint`
located in a namespace labeled with: `problem=netproblem`

Lets validate that!

First lets check whether a namespace with such label exists:

```shell
$ kubectl get ns -l problem=netproblem
No resources found
$
```

Seems that there is a problem with the label of the netpolicy-problem namespace. Lets check the actual set of labels
assigned to it:

```shell
$ kubectl get ns netpolicy-problem --show-labels
NAME                STATUS   AGE    LABELS
netpolicy-problem   Active   102m   kubernetes.io/metadata.name=netpolicy-problem,problem=netpolicy
$
```

Oh, the namespace does have a label with key `problem` but the value `netpolicy` doesn't actually match the value expected
by the network policy! This is also something we should address, but before that, lets also check the labels assigned
to the client pod:

```shell
$ kubectl -n netpolicy-problem get po --show-labels
NAME     READY   STATUS    RESTARTS   AGE    LABELS
client   1/1     Running   0          104m   role=client
server   1/1     Running   0          104m   role=server
$
```

The client pod have a label assigned: `role=client` which seems to match the PodSelector: `role=clint`, but on a second
look there seems to be a typo! Value `client` of the pod label doesn't match the `clint` value of the PodSelector!

Lets summarize our findings so far:

- The port section of the ingress rule reference port 8080/tcp while the server pod listens on port 80/tcp
- The NamespaceSelector of the ingress rule has a wrong value for the key problem - `netproblem`, instead of `netpolicy`
- The PodSelector of the ingress rule has a typo for the value of the key role - `clint`, instead of `client`

As there are no-other network policies in the same namespace and as we've carefully checked all network policy sections,
lets now try to fix the problems we've identified and validate the connectivity between the client and the server pods.

There are multiple techniques that we can use to modify Kubernetes resources:

- use kubectl edit, patch, set, etc. ( i.e `kubectl -n netpolicy-problem edit netpol restrict-server-access`) to modify
  the object in place
- modify the original resource definition in yaml format that we've used to initially create the objects and re-apply it.

As the recommended approach for managing kubernetes resources in production is the declarative one, i.e using yaml/json
documents, we are going to modify the original yaml manifest and re-apply it.

> Note: Modifying resources-in place have both advantages and disadvantages. It is handy if you simply want to test
> a quick change in a staging/dev environment, or when there is a time pressure - for example during a certification exam.
> Modifying resources in place without having a backup poses the risk to make unintended changes which could be hard to
> identify.
> A good practice is to preserve the original resource definition in yaml format using for example:
> kubectl get <resource_name> -o yaml > resource_name_back.yml
> and then modify the resource either in place inside the k8s cluster or modify a copy of the yaml file. Having a backup
> of the original resource definition will allow you to undo easily any changes made.


> Challenge: Try to modify the network policy using both approaches.

As we have access to the original yaml manifest lets download it and modify it:

```shell
$ wget https://raw.githubusercontent.com/RX-M/bust-a-kube/master/service-networking/network-policy-pod-isolation-problem/problem.yaml
...
problem.yaml                                                    100%[======================================================================================================================================================>]     403  --.-KB/s    in 0s

2024-02-09 19:58:22 (6.99 MB/s) - ‘problem.yaml’ saved [403/403]

$
```

Next we are going to modify the yaml manifest:

```shell
$ nano problem.yaml && cat $_
```

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: netpolicy-problem
  labels:
    problem: netpolicy
---
apiVersion: v1
kind: Pod
metadata:
  name: server
  namespace: netpolicy-problem
  labels:
    role: server
spec:
  containers:
  - image: nginx
    name: server
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: netpolicy-problem
  labels:
    role: client
spec:
  containers:
  - image: alpine
    name: client
    command: ["/bin/sh","-c","sleep infinity"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-server-access
  namespace: netpolicy-problem
spec:
  podSelector:
    matchLabels:
      role: server
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          problem: netpolicy
      podSelector:
        matchLabels:
          role: client
    ports:
    - protocol: TCP
      port: 80

```

Finally, lets apply it back to the K8s cluster:

```shell
$ kubectl apply -f solution.yml
namespace/netpolicy-problem unchanged
pod/server unchanged
pod/client unchanged
networkpolicy.networking.k8s.io/restrict-server-access configured
$
```

To test whether our changes has solved all the problems, lets connect again to the client pod and try to connect to the
server:

```shell
$ kubectl -n netpolicy-problem exec -it client -- /bin/sh
/ #
/ # wget -O- 10.244.147.208
Connecting to 10.244.147.208 (10.244.147.208:80)
writing to stdout
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
-                    100% |***************************************************************************************************************************************************************************************************************|   615  0:00:00 ETA
written to stdout
/ #
```

Success! The client pod can now establish a connection to the server pod and the server pod will not accept any connection
requests from other sources.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_
