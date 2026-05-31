# Ingress Path Rewrite Bug

## Symptoms

- The application works through port-forward or directly through the Service.
- The same app returns 404 through Ingress.
- Ingress object is accepted by the cluster.

## What The Platform Says

The Ingress exists and points at the expected Service.

## Why That Is Misleading

Ingress controllers can accept an object that is syntactically valid but semantically wrong for path matching and rewrite behavior.

## First Commands To Run

```bash
kubectl get ingress -n troubleshooting-lab rewrite-demo -o yaml
kubectl describe ingress -n troubleshooting-lab rewrite-demo
kubectl get svc,endpoints -n troubleshooting-lab rewrite-demo
kubectl port-forward -n troubleshooting-lab svc/rewrite-demo 8080:80
curl -i http://localhost:8080/
```

If using nginx ingress:

```bash
curl -i http://rewrite.localhost/api/
```

## Wrong Assumptions To Avoid

- Assuming the backend is broken because Ingress returns 404.
- Checking only the Service and endpoints.
- Forgetting that rewrite capture groups are controller-specific.

## Root Cause

The broken Ingress uses `rewrite-target: /$2`, but the path only defines one capture group. Requests are rewritten to an empty or wrong path.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh ingress-path-rewrite-bug fixed
```

The fixed Ingress uses the nginx-compatible regex path `/api(/|$)(.*)` with `rewrite-target: /$2`.

## Prevention

- Add smoke tests that hit the public ingress URL, not only the Service.
- Keep rewrite examples close to ingress manifests.
- Review controller-specific annotations during ingress controller upgrades.

