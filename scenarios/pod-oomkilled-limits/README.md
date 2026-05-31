# Pod OOMKilled By Memory Limit

## Symptoms

- Pod restarts even though the image and config are valid.
- `kubectl describe pod` shows last state `Terminated` with reason `OOMKilled`.
- Exit code is `137`.
- Logs may end abruptly.

## What The Platform Says

The container terminated and restarted.

## Why That Is Misleading

The restart looks similar to a crash loop, but the process did not choose to exit. The kernel killed it after it exceeded its cgroup memory limit.

## First Commands To Run

```bash
kubectl get pods -n troubleshooting-lab -l troubleshooting-lab/scenario=pod-oomkilled-limits
kubectl describe pod -n troubleshooting-lab -l troubleshooting-lab/scenario=pod-oomkilled-limits
kubectl logs -n troubleshooting-lab -l troubleshooting-lab/scenario=pod-oomkilled-limits --previous
kubectl top pod -n troubleshooting-lab
```

## Wrong Assumptions To Avoid

- Treating every restart as an application exception.
- Raising replica count before understanding per-pod memory demand.
- Looking only at CPU throttling when the failure is memory pressure.

## Root Cause

The broken deployment sets a `64Mi` memory limit while the process allocates around 180 MiB. Kubernetes enforces the container limit and the process is killed.

## Fix

Apply the fixed manifest:

```bash
./scripts/apply-scenario.sh pod-oomkilled-limits fixed
```

The fixed deployment raises the memory limit to `256Mi`.

## Prevention

- Set requests and limits from observed usage, not guesses.
- Track memory working set and OOMKilled events in Prometheus/Grafana.
- Load-test memory-heavy paths before rollout.
- Use alerts for `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`.

