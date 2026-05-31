# External Secret Not Syncing

## Symptoms

- Application pod waits for a Kubernetes Secret that does not exist.
- `ExternalSecret` object exists.
- Secret sync status is not `Ready`.
- Restarting the application does not help.

## What The Platform Says

The app may report a missing secret, while Kubernetes only shows a pod configuration or mount failure.

## Why That Is Misleading

The application is downstream of a controller workflow. The real failure is usually in the External Secrets Operator status, SecretStore reference, provider auth, or remote key.

## First Commands To Run

```bash
kubectl get externalsecret -n troubleshooting-lab app-config
kubectl describe externalsecret -n troubleshooting-lab app-config
kubectl get secretstore -n troubleshooting-lab
kubectl get secret -n troubleshooting-lab synced-app-config
kubectl get events -n troubleshooting-lab --sort-by='.lastTimestamp'
```

## Wrong Assumptions To Avoid

- Assuming the app deployment is wrong because it cannot read a Secret.
- Recreating pods before checking controller status.
- Checking only Kubernetes Secret objects and not the `ExternalSecret` conditions.

## Root Cause

The broken `ExternalSecret` references a `SecretStore` named `prod-vault`, but the namespace contains a `SecretStore` named `lab-vault`.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh external-secret-not-syncing fixed
```

The fixed `ExternalSecret` references `lab-vault`.

## Prevention

- Validate SecretStore references in CI.
- Alert on `ExternalSecret` resources with `Ready=False`.
- Keep provider auth and app secret names owned by the platform layer, not each app team independently.
- Use a pre-deploy check that confirms required Kubernetes Secrets exist before rollout.

## Note

This scenario requires the External Secrets Operator CRDs to be installed before applying the manifests. Without the CRDs, `kubectl apply` fails before the scenario can be created.

