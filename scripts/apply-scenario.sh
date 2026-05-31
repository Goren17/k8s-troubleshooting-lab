#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-}"
STATE="${2:-broken}"
LAB_NAMESPACE="${LAB_NAMESPACE:-troubleshooting-lab}"

if [[ -z "$SCENARIO" ]]; then
  echo "usage: $0 <scenario> [broken|fixed]" >&2
  exit 1
fi

if [[ "$STATE" != "broken" && "$STATE" != "fixed" ]]; then
  echo "state must be 'broken' or 'fixed'" >&2
  exit 1
fi

SCENARIO_DIR="scenarios/$SCENARIO/$STATE"

if [[ ! -d "$SCENARIO_DIR" ]]; then
  echo "scenario state not found: $SCENARIO_DIR" >&2
  exit 1
fi

kubectl create namespace "$LAB_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "$LAB_NAMESPACE" -f "$SCENARIO_DIR"

echo
echo "Applied $STATE state for $SCENARIO in namespace $LAB_NAMESPACE"
echo "Run: ./scripts/check-scenario.sh $SCENARIO"

