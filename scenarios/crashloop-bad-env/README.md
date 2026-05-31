# CrashLoopBackOff From Bad Runtime Config

## Symptoms

- Pod starts and immediately restarts.
- `kubectl get pods` shows `CrashLoopBackOff`.
- The image pulls successfully and the pod schedules normally.

## What The Platform Says

Kubernetes reports a container restart loop. That can make the issue look like an image, node, or deployment problem.

## Why That Is Misleading

The platform is only reporting the restart behavior. The useful signal is inside the application startup path.

## First Commands To Run

```bash
kubectl get pods -n troubleshooting-lab -l troubleshooting-lab/scenario=crashloop-bad-env
kubectl describe pod -n troubleshooting-lab -l troubleshooting-lab/scenario=crashloop-bad-env
kubectl logs -n troubleshooting-lab -l troubleshooting-lab/scenario=crashloop-bad-env --previous
kubectl get configmap -n troubleshooting-lab crashloop-app-config -o yaml
```

## Wrong Assumptions To Avoid

- Assuming `CrashLoopBackOff` means the image is broken.
- Restarting the deployment before checking the previous container logs.
- Looking only at pod events and ignoring runtime config.

## Root Cause

The container expects `DATABASE_URL` to be a usable connection string. The broken ConfigMap sets it to an empty value, so the startup command exits with a non-zero status.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh crashloop-bad-env fixed
```

The fixed ConfigMap provides a valid-looking `DATABASE_URL`, allowing the container to pass startup validation.

## Prevention

- Validate required environment variables in CI.
- Use Helm schema, Kustomize validation, or policy-as-code for required config keys.
- Fail with explicit startup logs instead of generic process exits.
- Alert on restart rate, not just pod phase.

