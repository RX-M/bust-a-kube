# Problem 3 - Services


## Context

`problem.yaml` creates a deployment named `app-frontend` that creates three pods running NGINX and exposes those pods
through a service named `client-access`. When applied to a cluster, the deployment, service, and pods are created
successfully but the pods are not accessible through the service:

```
kubectl run -it --rm bustakubeclient --image busybox --command -- /bin/sh

/ # wget -T5 client-access.default

Connecting to client-access.default (10.101.255.255:80)
wget: download timed out
```

Apply the manifest to your cluster, identify the problem and repair it so that the pods are accessible through the
service as expected.


## Setup

Apply the `problem.yaml` spec to your cluster using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/RX-M/bust-a-kube/master/svc-debug-1/problem.yaml
```


## Solution Conditions

The NGINX pods must be reachable through the DNS name (or service IP) from within the cluster for this problem to be
considered resolved:

```
kubectl run -it --rm bustakubeclient --image busybox --command -- /bin/sh

If you don't see a command prompt, try pressing enter.
/ # wget -qO - client-access.default

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
```

<br>

_Copyright (c) 2020 RX-M LLC, Cloud Native Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"
