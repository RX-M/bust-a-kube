![RX-M, llc.](https://rx-m.com/rxm-cnc.svg)

# Crossplane MR Problem 1


## Solution

Create the resource in teh cluster:

```
kubectl create -f bust-a-kube/crossplane/cp-mr-problem-1/problem.yaml

bucket.s3.aws.upbound.io/rx-m-crossplane-bad-bucket-t46b4 created
```

Verify that the MR is correctly created:

```
kubectl get bucket rx-m-crossplane-bad-bucket-t46b4

NAME                               SYNCED   READY   EXTERNAL-NAME                      AGE
rx-m-crossplane-bad-bucket-t46b4   False            rx-m-crossplane-bad-bucket-t46b4   31m
```

Describe the bucket to ascertain the sync problem:

```
kubectl describe bucket rx-m-crossplane-bad-bucket-t46b4

Name:         rx-m-crossplane-bad-bucket-t46b4
Namespace:
Labels:       <none>
Annotations:  crossplane.io/external-name: rx-m-crossplane-bad-bucket-t46b4
API Version:  s3.aws.upbound.io/v1beta2
Kind:         Bucket

...

Status:
  At Provider:
  Conditions:
    Last Transition Time:  2024-12-02T22:07:41Z
    Message:               connect failed: cannot initialize the Terraform plugin SDK async external client: cannot get terraform setup: could not configure the no-fork AWS client: cannot construct TF AWS Client from TF AWS Config, [{0 invalid AWS Region: us-west-6  []}]
    Reason:                ReconcileError
    Status:                False
    Type:                  Synced
Events:
  Type     Reason                   Age                   From                                            Message
  ----     ------                   ----                  ----                                            -------
  Warning  CannotConnectToProvider  4m51s (x46 over 44m)  managed/s3.aws.upbound.io/v1beta1, kind=bucket  cannot initialize the Terraform plugin SDK async external client: cannot get terraform setup: could not configure the no-fork AWS client: cannot construct TF AWS Client from TF AWS Config, [{0 invalid AWS Region: us-west-6  []}]
```

The Bucket is configured with a region that does not exist (`us-west-6`).

Change the region to `us-west-1`:

```
~/cp-ts$ kubectl edit bucket rx-m-crossplane-bad-bucket-t46b4

```
```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: s3.aws.upbound.io/v1beta2
kind: Bucket
metadata:
  annotations:
    crossplane.io/external-name: rx-m-crossplane-bad-bucket-t46b4
  creationTimestamp: "2024-12-02T22:07:41Z"
  generateName: rx-m-crossplane-bad-bucket-
  generation: 2
  name: rx-m-crossplane-bad-bucket-t46b4
  resourceVersion: "207297"
  uid: 2c50054a-e94e-4698-8925-e20db5ae1acc
spec:
  deletionPolicy: Delete
  forProvider:
    objectLockEnabled: true
    region: us-west-1     ### HERE ###
```
```

bucket.s3.aws.upbound.io/rx-m-crossplane-bad-bucket-t46b4 edited
```

Verify the fix:

```
kubectl get bucket rx-m-crossplane-bad-bucket-t46b4

NAME                               SYNCED   READY   EXTERNAL-NAME                      AGE
rx-m-crossplane-bad-bucket-t46b4   True     True    rx-m-crossplane-bad-bucket-t46b4   72m
```

Cleanup:

```
kubectl delete bucket rx-m-crossplane-bad-bucket-t46b4

bucket.s3.aws.upbound.io "rx-m-crossplane-bad-bucket-t46b4" deleted
```


<br>

_Copyright (c) 2023-2024 RX-M LLC, Cloud Native & AI Training and Consulting, all rights reserved_