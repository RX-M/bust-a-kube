# Delete Deny All Network Policy
kubectl delete networkpolicies.networking.k8s.io debug-scenario &> /dev/null

# Delete Debug Pod with Failing Init Container
kubectl delete pod debug-pod1 &> /dev/null

#Apply the Weave Net CNI
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" &> /dev/null
