#!/usr/bin/env bash
set -euo pipefail

LAB_NAMESPACE="${LAB_NAMESPACE:-troubleshooting-lab}"

kubectl delete namespace "$LAB_NAMESPACE" --ignore-not-found
echo "Deleted namespace $LAB_NAMESPACE"

