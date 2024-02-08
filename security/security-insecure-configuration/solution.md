![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Application Access


## Solution

After checking `problem.yaml` we identify couple of security issues. The most important ones are:
- The container is running as root user
- The container is running in privileged mode
- The container has access to the entire host filesystem

Those are the things which are obvious from the yaml file.
```bash
~$ cat problem.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: insecured-workload
spec:
  # Bad host volume mount - allows access to the entire host filesystem
  volumes:
  - name: nicehost
    hostPath:
      path: /
  # Container have access to the process ID's of the host
  hostPID: true
  containers:
  - name: root-user
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: nicehost
      mountPath: /host
    securityContext:
      # priviliged enables all system calls
      privileged: true
      # Runnin as root user is not recommended
      runAsUser: 0
```

Lets run `kube-score` to see what other issues we can find.

```bash
~$ kube-score score problem.yaml
```

Here is the output from `kube-score`

```bash
~$ kube-score score problem.yaml
v1/Pod root-user                                                              💥
    [CRITICAL] Container Security Context ReadOnlyRootFilesystem
        · root-user -> The pod has a container with a writable root filesystem
            Set securityContext.readOnlyRootFilesystem to true
    [CRITICAL] Pod NetworkPolicy
        · The pod does not have a matching NetworkPolicy
            Create a NetworkPolicy that targets this pod to control who/what can communicate with this pod. Note, this
            feature needs to be supported by the CNI implementation used in the Kubernetes cluster to have an effect.
    [CRITICAL] Container Security Context User Group ID
        · root-user -> The container is running with a low user ID
            A userid above 10 000 is recommended to avoid conflicts with the host. Set securityContext.runAsUser to a value
            > 10000
        · root-user -> The container running with a low group ID
            A groupid above 10 000 is recommended to avoid conflicts with the host. Set securityContext.runAsGroup to a
            value > 10000
    [CRITICAL] Container Security Context Privileged
        · root-user -> The container is privileged
            Set securityContext.privileged to false. Privileged containers can access all devices on the host, and grants
            almost the same access as non-containerized processes on the host.
    [CRITICAL] Container Resources
        · root-user -> CPU limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.cpu
        · root-user -> Memory limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.memory
        · root-user -> CPU request is not set
            Resource requests are recommended to make sure that the application can start and run without crashing. Set
            resources.requests.cpu
        · root-user -> Memory request is not set
            Resource requests are recommended to make sure that the application can start and run without crashing. Set
            resources.requests.memory
    [CRITICAL] Container Ephemeral Storage Request and Limit
        · root-user -> Ephemeral Storage limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.ephemeral-storage
    [CRITICAL] Container Image Tag
        · root-user -> Image with latest tag
            Using a fixed tag is recommended to avoid accidental upgrades
```

Lets discuss the issues and how we can fix them:

- Set the `hostPID` to false, so the Pod won't share the host's PID namespace
- Remove `privileged` and change the value of `runAsUser` in the `securityContext` so the container will run as a
`non-root` user with the user ID and group ID of `10000`.
- Add `readOnlyRootFilesystem: true` to make the container's filesystem read-only
- Pull an image by FQIN ( fully qualified image name ) with a pinned version
`docker.io/busybox:1.36.1` instead of using the latest tag (commented out).
As example of image we will still use the cri-tools to show you what is the result of the changes.
- Set both resource requests and limits for CPU, memory, and ephemeral storage to mitigate potential resource
exhaustion.
- Set the `imagePullPolicy` to Always. This ensures that Kubernetes always pulls the image from the registry to make
sure it's using the correct version.
- Remove the `hostPath` volume and set ephemeral-storage ( or other volumes ) with a limit. This ensures that your
application has enough ephemeral storage to start and run without crashing.

Lets fix the issues by creating a new pod definition file called `good-pod.yaml`


```bash
~$ cat good-pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secured-workload
spec:
  hostPID: false
  volumes:
  - name: safer-volume
    emptyDir: {}
  containers:
  - name: safer-container
    image: busybox:1.36.1
    imagePullPolicy: Always
    command: ["sleep", "3600"]
    volumeMounts:
    - name: safer-volume
      mountPath: /host
    securityContext:
      privileged: false
      runAsUser: 10000
      runAsGroup: 10000
      readOnlyRootFilesystem: true
    resources:
      limits:
        cpu: "1"
        memory: "1Gi"
        ephemeral-storage: "1Gi"
      requests:
        cpu: "500m"
        memory: "500Mi"
        ephemeral-storage: "500Mi"
```


_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_