# bust-a-kube

This repo houses various sets of problematic k8s resources, can you debug them?

Each "bug" lives in it's own subdirectory. The subdirectories contain the following files:

- README.md - explains the context of the problem the resources exhibit
- problem.yaml - the bug, apply this manifest to your cluster and see if you can debug it
- solution.md - an explanation of what is wrong, how to diagnose such a problem and how to fix it

**Do not run these manifests on a cluster you care about!!**

These problem resources can impact the functioning of you cluster and/or it's applications (they are problems after
all!). All of the problems are designed to be compatible with recent versions of Kubernetes (1.18+).
