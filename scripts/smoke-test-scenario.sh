#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-}"
LAB_NAMESPACE="${LAB_NAMESPACE:-troubleshooting-lab-smoke}"
TIMEOUT="${TIMEOUT:-90s}"

usage() {
  cat <<EOF
usage: $0 <scenario>

Runs an in-cluster broken-then-fixed smoke test for scenarios with stable local behavior.

Supported scenarios:
  crashloop-bad-env
  service-selector-mismatch
  readiness-probe-failure

Environment overrides:
  LAB_NAMESPACE=$LAB_NAMESPACE
  TIMEOUT=$TIMEOUT
EOF
}

if [[ -z "$SCENARIO" ]]; then
  usage >&2
  exit 1
fi

case "$SCENARIO" in
  crashloop-bad-env|service-selector-mismatch|readiness-probe-failure)
    ;;
  *)
    echo "unsupported smoke-test scenario: $SCENARIO" >&2
    usage >&2
    exit 1
    ;;
esac

reset_namespace() {
  kubectl delete namespace "$LAB_NAMESPACE" --ignore-not-found --wait=true
  kubectl create namespace "$LAB_NAMESPACE"
}

apply_state() {
  local state="$1"

  echo "Applying $state state for $SCENARIO"
  LAB_NAMESPACE="$LAB_NAMESPACE" ./scripts/apply-scenario.sh "$SCENARIO" "$state"
}

rollout_succeeds() {
  local deployment="$1"

  kubectl rollout status "deployment/$deployment" -n "$LAB_NAMESPACE" --timeout="$TIMEOUT"
}

rollout_fails() {
  local deployment="$1"
  local timeout="${2:-30s}"

  if kubectl rollout status "deployment/$deployment" -n "$LAB_NAMESPACE" --timeout="$timeout"; then
    echo "expected rollout to fail, but deployment became available: $deployment" >&2
    return 1
  fi
}

wait_for_log_text() {
  local selector="$1"
  local expected_text="$2"
  local attempts=30

  for _ in $(seq 1 "$attempts"); do
    if kubectl logs -n "$LAB_NAMESPACE" -l "$selector" --all-containers --tail=100 2>/dev/null | grep -qF "$expected_text"; then
      return 0
    fi

    if kubectl logs -n "$LAB_NAMESPACE" -l "$selector" --all-containers --previous --tail=100 2>/dev/null | grep -qF "$expected_text"; then
      return 0
    fi

    sleep 2
  done

  echo "expected log text not found: $expected_text" >&2
  kubectl get pods -n "$LAB_NAMESPACE" -l "$selector" -o wide >&2 || true
  kubectl describe pods -n "$LAB_NAMESPACE" -l "$selector" >&2 || true
  return 1
}

assert_no_ready_endpoints() {
  local service="$1"
  local ready_addresses

  ready_addresses="$(kubectl get endpoints "$service" -n "$LAB_NAMESPACE" -o jsonpath='{.subsets[*].addresses}' 2>/dev/null || true)"
  if [[ -n "$ready_addresses" ]]; then
    echo "expected no ready endpoints for service/$service, found: $ready_addresses" >&2
    return 1
  fi
}

wait_for_endpoints() {
  local service="$1"
  local attempts=30
  local subsets

  for _ in $(seq 1 "$attempts"); do
    subsets="$(kubectl get endpoints "$service" -n "$LAB_NAMESPACE" -o jsonpath='{.subsets}' 2>/dev/null || true)"
    if [[ -n "$subsets" ]]; then
      return 0
    fi
    sleep 2
  done

  echo "expected endpoints for service/$service, but none became ready" >&2
  kubectl describe service "$service" -n "$LAB_NAMESPACE" >&2 || true
  kubectl get pods -n "$LAB_NAMESPACE" --show-labels >&2 || true
  return 1
}

test_crashloop_bad_env() {
  reset_namespace
  apply_state broken
  wait_for_log_text "troubleshooting-lab/scenario=crashloop-bad-env" "fatal: DATABASE_URL is empty"

  apply_state fixed
  rollout_succeeds crashloop-api
  wait_for_log_text "troubleshooting-lab/scenario=crashloop-bad-env" "connected to postgres://"
}

test_service_selector_mismatch() {
  reset_namespace
  apply_state broken
  rollout_succeeds payments-api
  assert_no_ready_endpoints selector-demo

  apply_state fixed
  wait_for_endpoints selector-demo
}

test_readiness_probe_failure() {
  reset_namespace
  apply_state broken
  rollout_fails readiness-demo 30s
  assert_no_ready_endpoints readiness-demo

  apply_state fixed
  rollout_succeeds readiness-demo
  wait_for_endpoints readiness-demo
}

echo "Running smoke test for scenario: $SCENARIO"
echo "This applies the broken state, verifies the expected failure signal, applies the fixed state, and verifies recovery."

case "$SCENARIO" in
  crashloop-bad-env)
    test_crashloop_bad_env
    ;;
  service-selector-mismatch)
    test_service_selector_mismatch
    ;;
  readiness-probe-failure)
    test_readiness_probe_failure
    ;;
esac

echo "smoke test passed: $SCENARIO"
