# Kubernetes Troubleshooting Lab

[![CI](https://github.com/Goren17/k8s-troubleshooting-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/Goren17/k8s-troubleshooting-lab/actions/workflows/ci.yml)

This repo is a scenario-based Kubernetes lab for debugging when the platform gives you a symptom that points in the wrong direction.

Each scenario starts from a broken workload, walks through the commands that separate noise from signal, identifies the root cause, applies a fix, and documents how to prevent the failure from coming back.

## What This Proves

- Debugging Kubernetes from symptoms instead of guesses.
- Reading pod events, logs, selectors, probes, ingress rules, secrets, and resource limits.
- Connecting delivery problems across Kubernetes, ingress, registries, secrets, and observability.
- Turning a one-off fix into a prevention control.

## Scenarios

| Scenario | What the platform says | Real failure |
| --- | --- | --- |
| `crashloop-bad-env` | Pod is `CrashLoopBackOff` | Runtime config is present but invalid |
| `imagepullbackoff-private-registry` | Pod is `ImagePullBackOff` | Private registry auth is missing |
| `service-selector-mismatch` | Service exists but traffic fails | Service selector does not match pod labels |
| `ingress-path-rewrite-bug` | Ingress returns 404/502 | Regex capture groups and rewrite target do not match |
| `readiness-probe-failure` | Pod is running but not receiving traffic | Readiness probe checks the wrong path |
| `external-secret-not-syncing` | Application secret never appears | ExternalSecret references the wrong SecretStore |
| `pod-oomkilled-limits` | Pod keeps restarting | Memory limit is lower than runtime demand |

## Repo Layout

```text
k8s-troubleshooting-lab/
├── scenarios/
│   ├── crashloop-bad-env/
│   ├── imagepullbackoff-private-registry/
│   ├── service-selector-mismatch/
│   ├── ingress-path-rewrite-bug/
│   ├── readiness-probe-failure/
│   ├── external-secret-not-syncing/
│   └── pod-oomkilled-limits/
├── solutions/
├── scripts/
│   ├── apply-scenario.sh
│   ├── check-scenario.sh
│   ├── validate-scripts.sh
│   ├── validate-scenarios.sh
│   └── reset-lab.sh
└── README.md
```

Each scenario contains:

```text
README.md
broken/
fixed/
```

## Requirements

- A Kubernetes cluster such as kind, minikube, Docker Desktop, EKS, GKE, or AKS.
- `kubectl` configured against the target cluster.
- Optional: an ingress controller for the ingress scenario.
- Optional: External Secrets Operator for the external secret scenario.

The default namespace is `troubleshooting-lab`.

## Usage

Apply a broken scenario:

```bash
./scripts/apply-scenario.sh crashloop-bad-env
```

Inspect the scenario:

```bash
./scripts/check-scenario.sh crashloop-bad-env
```

Apply the fixed state:

```bash
./scripts/apply-scenario.sh crashloop-bad-env fixed
```

Reset the lab namespace:

```bash
./scripts/reset-lab.sh
```

Use a different namespace:

```bash
LAB_NAMESPACE=devops-debug ./scripts/apply-scenario.sh service-selector-mismatch
```

Validate the repo contract locally:

```bash
./scripts/validate-scripts.sh
./scripts/validate-scenarios.sh
```

## Continuous Integration

GitHub Actions validates this repo on every push and pull request:

- Shell script syntax.
- Script executable bit, shebang, syntax, and ShellCheck output when available.
- Scenario structure and required troubleshooting headings.
- YAML parsing for every manifest.
- Kubernetes schema validation with kubeconform.

## Portfolio Reading Path

If you are reviewing this as a portfolio project, start with the scenario READMEs rather than the YAML. The value is in the debugging path:

1. What Kubernetes reports.
2. Why that symptom can mislead you.
3. Which commands expose the useful signal.
4. What the root cause actually is.
5. How the fix and prevention differ.
