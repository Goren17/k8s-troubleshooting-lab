# ImagePullBackOff From Private Registry Auth

## Symptoms

- Pod stays in `ImagePullBackOff` or `ErrImagePull`.
- The deployment exists and the replica set is created.
- No application logs are available because the container never starts.

## What The Platform Says

Kubernetes reports that it cannot pull the image.

## Why That Is Misleading

Image pull failures can be caused by bad image names, missing tags, registry downtime, network policy, DNS, or credentials. The pod phase alone does not identify which one is true.

## First Commands To Run

```bash
kubectl get pods -n troubleshooting-lab -l troubleshooting-lab/scenario=imagepullbackoff-private-registry
kubectl describe pod -n troubleshooting-lab -l troubleshooting-lab/scenario=imagepullbackoff-private-registry
kubectl get secret -n troubleshooting-lab private-registry-credentials -o yaml
kubectl get serviceaccount -n troubleshooting-lab private-registry-runner -o yaml
```

## Wrong Assumptions To Avoid

- Assuming the image tag does not exist before checking pull secret configuration.
- Looking for application logs when the container has not started.
- Adding registry credentials to a different namespace than the workload.

## Root Cause

The broken deployment references a private registry image but does not configure `imagePullSecrets`.

## Fix

Create a real registry secret in the workload namespace, then apply the fixed deployment:

```bash
kubectl create secret docker-registry private-registry-credentials \
  -n troubleshooting-lab \
  --docker-server=registry.example.com \
  --docker-username="$REGISTRY_USER" \
  --docker-password="$REGISTRY_PASSWORD"

./scripts/apply-scenario.sh imagepullbackoff-private-registry fixed
```

The included fixed manifest wires the pod to `private-registry-credentials`. The placeholder secret in this repo is intentionally invalid so no real credentials are committed.

## Prevention

- Manage registry credentials through External Secrets or sealed secrets.
- Validate `imagePullSecrets` in deployment policy.
- Monitor `ImagePullBackOff` events separately from application crashes.
- Keep registry, image, tag, and secret ownership visible in release documentation.

