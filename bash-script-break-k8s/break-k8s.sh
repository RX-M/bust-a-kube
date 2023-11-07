#!/bin/bash

# Deletes the CNI weave-net daemonset
kubectl delete daemonset.apps weave-net -n kube-system &> /dev/null

# Create a default deny-all ingress network policy
echo  "apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: debug-scenario
spec:
  podSelector: {}
  policyTypes:
  - Ingress" > /tmp/debug-scenario.yaml

# Run Deny All Ingress Network Policy
kubectl apply -f /tmp/debug-scenario.yaml &> /dev/null

# Delete Manifest for Deny All Ingress Network Policy
rm -f /tmp/debug-scenario.yaml

# Create manifest for failing Init Container
echo "apiVersion: v1
kind: Pod
metadata:
  name: debug-pod1
  labels:
    app: debug-pod1
spec:
  initContainers:
  - name: init-container
    image: ALPine
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c"]
    args: ["echo hello"]
  containers:
  - name: myapp-container
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]" > /tmp/debug-init.yaml

# Run Failing Init Container Manifest
kubectl apply -f /tmp/debug-init.yaml -n default &> /dev/null

# Delete Manifest for init-pod1
rm -f /tmp/debug-init.yaml
