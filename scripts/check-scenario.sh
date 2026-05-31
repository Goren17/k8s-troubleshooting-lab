#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-}"
LAB_NAMESPACE="${LAB_NAMESPACE:-troubleshooting-lab}"

if [[ -z "$SCENARIO" ]]; then
  echo "usage: $0 <scenario>" >&2
  exit 1
fi

echo "Namespace: $LAB_NAMESPACE"
echo "Scenario:  $SCENARIO"
echo

kubectl get all,ingress,secrets -n "$LAB_NAMESPACE" -l "troubleshooting-lab/scenario=$SCENARIO" 2>/dev/null || true

echo
echo "External Secrets resources, if the CRDs are installed:"
kubectl get externalsecrets,secretstores -n "$LAB_NAMESPACE" -l "troubleshooting-lab/scenario=$SCENARIO" 2>/dev/null || true

echo
echo "Recent events:"
kubectl get events -n "$LAB_NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -n 20 || true

echo
echo "Useful next commands:"
echo "kubectl describe pod -n $LAB_NAMESPACE -l troubleshooting-lab/scenario=$SCENARIO"
echo "kubectl logs -n $LAB_NAMESPACE -l troubleshooting-lab/scenario=$SCENARIO --all-containers --tail=80"
echo "kubectl get endpoints -n $LAB_NAMESPACE"
