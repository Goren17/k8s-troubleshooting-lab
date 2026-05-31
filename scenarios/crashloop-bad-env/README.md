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
kubectl get deploy -n troubleshooting-lab crashloop-api -o yaml
kubectl get configmap -n troubleshooting-lab crashloop-app-config -o yaml
```

## Wrong Assumptions To Avoid

- Assuming `CrashLoopBackOff` means the image is broken.
- Restarting the deployment before checking the previous container logs.
- Looking only at pod events and ignoring runtime config.

## Root Cause

The ConfigMap contains `DATABASE_URL`, but the broken Deployment tries to load `DATABASE_DSN` into the container's `DATABASE_URL` environment variable. Because the key is marked optional, Kubernetes starts the container instead of failing pod configuration. The app then exits during startup because `DATABASE_URL` is empty.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh crashloop-bad-env fixed
```

The fixed Deployment reads the `DATABASE_URL` key from the ConfigMap, allowing the container to pass startup validation.

## Prevention

- Validate required environment variables in CI.
- Use Helm schema, Kustomize validation, or policy-as-code for required config keys.
- Fail with explicit startup logs instead of generic process exits.
- Alert on restart rate, not just pod phase.
