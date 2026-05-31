# Readiness Probe Failure

## Symptoms

- Pod status is `Running`.
- Container logs look normal.
- Service has no ready endpoints, or traffic never reaches the pod.
- Deployment rollout may hang.

## What The Platform Says

The pod is running but not ready.

## Why That Is Misleading

Running only means the process exists. Readiness controls whether the pod is eligible for Service traffic.

## First Commands To Run

```bash
kubectl get pods -n troubleshooting-lab -l troubleshooting-lab/scenario=readiness-probe-failure
kubectl describe pod -n troubleshooting-lab -l troubleshooting-lab/scenario=readiness-probe-failure
kubectl get endpoints -n troubleshooting-lab readiness-demo
kubectl logs -n troubleshooting-lab -l troubleshooting-lab/scenario=readiness-probe-failure
```

## Wrong Assumptions To Avoid

- Treating `Running` as healthy.
- Debugging Service selectors before checking readiness conditions.
- Removing probes instead of fixing what they check.

## Root Cause

The broken readiness probe checks `/ready` on nginx. That path returns 404, so Kubernetes never marks the pod ready.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh readiness-probe-failure fixed
```

The fixed readiness probe checks `/`, which nginx serves successfully.

## Prevention

- Make readiness endpoints explicit and stable.
- Include readiness checks in deployment smoke tests.
- Alert on pods stuck in `Running` but not `Ready`.

