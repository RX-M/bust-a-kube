# Problem 3 - Services


## Solution

After you apply the problem.yaml spec, a deployment and service are created. If you use `kubectl get pods,svc` you will
see that all of the pods and service are present in the current namespace:

```
ubuntu@labsys:~$ kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/services-networking-1/problem.yaml

deployment.apps/app-frontend created
service/client-access created

ubuntu@labsys:~$ kubectl get pods,svc

NAME                                READY   STATUS    RESTARTS   AGE
pod/app-frontend-6f4ffb95cd-prrp8   1/1     Running   0          7s
pod/app-frontend-6f4ffb95cd-qtgqx   1/1     Running   0          7s
pod/app-frontend-6f4ffb95cd-srbhm   1/1     Running   0          7s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/client-access   ClusterIP   10.101.255.255   <none>        80/TCP    7s
service/kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP   7h42m

ubuntu@labsys:~$
```

If you try to access the service, the request fails:

```
ubuntu@labsys:~$ kubectl get svc client-access

NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
client-access   ClusterIP   10.101.255.255   <none>        80/TCP    30m

ubuntu@labsys:~$ kubectl run -it --rm bustakubeclient --image busybox --command -- /bin/sh

If you don't see a command prompt, try pressing enter.
/ # wget -T5 10.101.255.255

Connecting to 10.101.255.255 (10.101.255.255:80)
wget: download timed out

/ # wget -T5 client-access.default

Connecting to client-access.default (10.101.255.255:80)
wget: download timed out

/ # exit

Session ended, resume using 'kubectl attach bustakubeclient -c bustakubeclient -i -t' command when the pod is running
pod "bustakubeclient" deleted

ubuntu@labsys:~$
```

The first thing you want to do is ensure that the pods are running. You know that the pods are running from the output
of the previous `kubectl get` command. If the pods were not running, you will need to debug and fix them so they are in
a ready state to ensure they are included in the Kubernetes service mesh.

Next, you will want to determine if the service has any endpoints. You can do this with `kubectl describe svc`:

```
ubuntu@labsys:~$ kubectl describe svc client-access

Name:              client-access
Namespace:         default
Labels:            app=app-frontend
Annotations:       <none>
Selector:          context=frontend
Type:              ClusterIP
IP:                10.101.255.255
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         <none>
Session Affinity:  None
Events:            <none>
```

Or `kubectl get endpoints`:

```
ubuntu@labsys:~$ kubectl get endpoints client-access

NAME            ENDPOINTS   AGE
client-access   <none>      4m14s

ubuntu@labsys:~$
```

In both commands, you see that the service does not have any endpoints. Remember that services select their endpoints
using the label in the service's `selector` field. Check if there are any pods that have the `context=frontend` label:

```
ubuntu@labsys:~$ kubectl get pods -l context=frontend

No resources found in default namespace.

ubuntu@labsys:~$
```

There are currently no pods that have the label `context=frontend`. Now check what labels are available on the pods
managed by the app-frontend deployment:

```
ubuntu@labsys:~$ kubectl get pods --show-labels

NAME                            READY   STATUS    RESTARTS   AGE   LABELS
app-frontend-6f4ffb95cd-prrp8   1/1     Running   0          13m   app=app-frontend,pod-template-hash=6f4ffb95cd
app-frontend-6f4ffb95cd-qtgqx   1/1     Running   0          13m   app=app-frontend,pod-template-hash=6f4ffb95cd
app-frontend-6f4ffb95cd-srbhm   1/1     Running   0          13m   app=app-frontend,pod-template-hash=6f4ffb95cd

ubuntu@labsys:~$
```

You have two options here:

1. Update the service selector

Download the problem.yaml file and edit it so the service's `selector` uses `app=app-frontnend`:

```
ubuntu@labsys:~$ wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/services-networking-1/problem.yaml > svc-debug-1.yaml

ubuntu@labsys:~$ nano svc-debug-1.yaml && cat svc-debug-1.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: app-frontend
  name: app-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-frontend
  template:
    metadata:
      labels:
        app: app-frontend
    spec:
      containers:
      - image: nginx
        name: nginx
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: app-frontend
  name: client-access
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app-frontend
  clusterIP: 10.101.255.255

ubuntu@labsys:~$
```

Apply the change and inspect the endpoints for the client-access service again. It will now return the necessary
endpoints:

```
ubuntu@labsys:~$ kubectl apply -f svc-debug-1.yaml

deployment.apps/app-frontend unchanged
service/client-access configured

ubuntu@labsys:~$ kubectl get endpoints client-access

NAME            ENDPOINTS                                AGE
client-access   10.32.0.4:80,10.36.0.1:80,10.44.0.1:80   17m

ubuntu@labsys:~$
```

2. Update the pod labels

Download the problem.yaml file and add `context=frontend` to the deployment's pod template:

```
ubuntu@labsys:~$ wget -qO - https://raw.githubusercontent.com/RX-M/bust-a-kube/master/services-networking-1/problem.yaml > svc-debug-1.yaml

ubuntu@labsys:~$ nano svc-debug-1.yaml && cat svc-debug-1.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: app-frontend
  name: app-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-frontend
  template:
    metadata:
      labels:
        app: app-frontend
        context: frontend
    spec:
      containers:
      - image: nginx
        name: nginx
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: app-frontend
  name: client-access
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    context: frontend
  clusterIP: 10.101.255.255

ubuntu@labsys:~$
```

```
ubuntu@labsys:~$ kubectl apply -f svc-debug-1.yaml

deployment.apps/app-frontend configured
service/client-access unchanged

ubuntu@labsys:~$ kubectl get pods -l context=frontend

NAME                            READY   STATUS    RESTARTS   AGE
app-frontend-7cbd879b7f-8z7vk   1/1     Running   0          23s
app-frontend-7cbd879b7f-d2ncq   1/1     Running   0          16s
app-frontend-7cbd879b7f-dpcsb   1/1     Running   0          20s

ubuntu@labsys:~$ kubectl get endpoints client-access

NAME            ENDPOINTS                                AGE
client-access   10.32.0.5:80,10.36.0.2:80,10.44.0.2:80   21m

ubuntu@labsys:~$
```

After applying the fix, retry your `curl` command. It will now show the NGINX welcome page!

```
ubuntu@labsys:~$ curl 10.101.255.255

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
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

ubuntu@labsys:~$
```


<br>

_Copyright (c) 2020-2023 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
