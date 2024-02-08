![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# bust-a-kube

This repo houses various sets of problematic k8s resources, can you debug them?

Each "bug" lives in it's own subdirectory. The subdirectories are sorted into the following categories:

- `workload` - Covering containers, pods, and all controller types in Kubernetes
- `services-networking` - Covering services, discovery (DNS), network policies, and ingress
- `config-storage` - Covering configMaps, secrets, the downward API, and the elements of the persistent volume subsystem
- `observability` - Covering workload scaling, metrics, logs, and events
- `cluster` - Covering control plane components, kubelets, various plugins (Network, Storage and Container Runtimes)
- `security` - Covering Role-based access control, security contexts, ServiceAccounts, and various policies

The subdirectories contain the following files:

- `README.md` - explains the context of the problem the resources exhibit
- `problem.yaml` - the bug, apply this manifest to your cluster and see if you can debug it
- `solution.md` - an explanation of what is wrong, how to diagnose such a problem and how to fix it

Each problem is designed to be independent of one another and can be completed in any order.


> WARNING: **Do not run these manifests on a cluster you care about!!**


These problem resources can impact the functioning of you cluster and/or it's applications (they are problems after
all!). All of the problems are designed to be compatible with recent versions of Kubernetes (1.18+).
