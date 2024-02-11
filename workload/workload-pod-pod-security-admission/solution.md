# Problem 1 - Pod Security Admission


## Solution

When we run apply the `problem.yaml` file, we get the following error:

```
~$ kubectl apply -f problem.yaml
namespace/secure-workload created
Error from server (Forbidden): error when creating "problem.yaml": pods "pod-psa" is forbidden: violates PodSecurity "baseline:latest": privileged (container "secure-workload-container" must not set securityContext.privileged=true)
```

It seems we violate a `PodSecurityPolicy`. We can check the `PodSecurityPolicy` by describing the `secure-workload` namespace.

```
~$ kubectl describe ns secure-workload
Name:         secure-workload
Labels:       kubernetes.io/metadata.name=secure-workload
              pod-security.kubernetes.io/audit=restricted
              pod-security.kubernetes.io/enforce=baseline
              pod-security.kubernetes.io/warn=restricted
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

We can see that we `enforce` the  `baseline` Pod Security Standard. Here is the [official
documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/)where we can learn more about
`Privileged`, `Baseline` and `Restricted` Pod Security Standards. Scroll down to `baseline` and check the `Privileged
Containers` section. We can see that `Allowed Values` are `false` which means we cannot run pods which escalate
privileges. In our case we don't want to modify the policy ,so we will just fix the `problem.yaml` file. Let's change
the `securityContext` of the `secure-workload-container` to `privileged: false`:

```yaml
...
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-psa
  namespace: secure-workload
spec:
  containers:
  - name: secure-workload-container
    image: nginx
    securityContext:
      privileged: false # <--- change this line
```

Let's apply the `problem.yaml` file again:

```
~$ kubectl apply -f problem.yaml
namespace/secure-workload unchanged
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "secure-workload-container" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "secure-workload-container" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "secure-workload-container" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "secure-workload-container" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
pod/pod-psa created
kubectl get pods -n secure-workload
NAME      READY   STATUS    RESTARTS   AGE
pod-psa   1/1     Running   0          104s
```

As we can see the pod will run but we get a warning. We get that message because we violate the `restricted` policy
which is set to `audit` which will give the client ( our kubectl ) message and also will put it in `audit.log`.

<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_

[RX-M LLC]: https://rx-m.io/rxm-cnc.svg "RX-M LLC"

