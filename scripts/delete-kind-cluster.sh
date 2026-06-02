#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-k8s-troubleshooting-lab}"

usage() {
  cat <<EOF
usage: $0

Deletes the local kind cluster used by the troubleshooting lab.

Environment overrides:
  KIND_CLUSTER_NAME=$KIND_CLUSTER_NAME
EOF
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "missing required command: $command_name" >&2
    exit 1
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command kind

echo "Deleting kind cluster: $KIND_CLUSTER_NAME"
kind delete cluster --name "$KIND_CLUSTER_NAME"

