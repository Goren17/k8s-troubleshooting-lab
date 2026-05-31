# Service Selector Mismatch

## Symptoms

- Deployment pods are running.
- Service exists and has a ClusterIP.
- Requests through the Service fail or time out.
- `kubectl get endpoints` shows no endpoints for the Service.

## What The Platform Says

The workload looks healthy if you only check pods and deployments.

## Why That Is Misleading

Kubernetes Services route to pods through label selectors. A running pod is not enough; the Service must select it.

## First Commands To Run

```bash
kubectl get pods -n troubleshooting-lab --show-labels
kubectl get svc -n troubleshooting-lab selector-demo -o yaml
kubectl get endpoints -n troubleshooting-lab selector-demo
kubectl describe svc -n troubleshooting-lab selector-demo
```

## Wrong Assumptions To Avoid

- Assuming a Service has endpoints because pods are running.
- Debugging DNS before checking selectors.
- Restarting pods when the routing object is wrong.

## Root Cause

The broken Service selects `app: payment-api`, but the Deployment pods are labeled `app: payments-api`.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh service-selector-mismatch fixed
```

The fixed Service selector matches the pod label.

## Prevention

- Generate Services and Deployments from the same Helm values or Kustomize labels.
- Add CI checks that validate selectors match pod template labels.
- Alert on Services with zero endpoints.

