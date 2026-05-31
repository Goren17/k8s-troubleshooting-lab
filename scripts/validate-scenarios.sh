#!/usr/bin/env bash
set -euo pipefail

REQUIRED_HEADINGS=(
  "## Symptoms"
  "## First Commands To Run"
  "## Wrong Assumptions To Avoid"
  "## Root Cause"
  "## Fix"
  "## Prevention"
)

required_scenarios=(
  "crashloop-bad-env"
  "imagepullbackoff-private-registry"
  "service-selector-mismatch"
  "ingress-path-rewrite-bug"
  "readiness-probe-failure"
  "external-secret-not-syncing"
  "pod-oomkilled-limits"
)

failures=0

check_file_exists() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    echo "missing file: $path" >&2
    failures=$((failures + 1))
  fi
}

check_dir_exists() {
  local path="$1"

  if [[ ! -d "$path" ]]; then
    echo "missing directory: $path" >&2
    failures=$((failures + 1))
  fi
}

check_yaml_exists() {
  local path="$1"

  if ! find "$path" -maxdepth 1 -type f -name '*.yaml' | grep -q .; then
    echo "missing yaml manifests in: $path" >&2
    failures=$((failures + 1))
  fi
}

check_heading_exists() {
  local readme="$1"
  local heading="$2"

  if ! grep -qxF "$heading" "$readme"; then
    echo "missing heading in $readme: $heading" >&2
    failures=$((failures + 1))
  fi
}

for scenario in "${required_scenarios[@]}"; do
  scenario_dir="scenarios/$scenario"
  readme="$scenario_dir/README.md"
  scenario_failures_before="$failures"

  echo "::group::scenario/$scenario"

  check_dir_exists "$scenario_dir"
  check_dir_exists "$scenario_dir/broken"
  check_dir_exists "$scenario_dir/fixed"
  check_file_exists "$readme"

  if [[ -f "$readme" ]]; then
    for heading in "${REQUIRED_HEADINGS[@]}"; do
      check_heading_exists "$readme" "$heading"
    done
  fi

  if [[ -d "$scenario_dir/broken" ]]; then
    check_yaml_exists "$scenario_dir/broken"
  fi

  if [[ -d "$scenario_dir/fixed" ]]; then
    check_yaml_exists "$scenario_dir/fixed"
  fi

  if [[ "$failures" -eq "$scenario_failures_before" ]]; then
    echo "scenario passed: $scenario"
  else
    echo "scenario failed: $scenario" >&2
  fi

  echo "::endgroup::"
done

actual_count="$(find scenarios -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
expected_count="${#required_scenarios[@]}"

if [[ "$actual_count" != "$expected_count" ]]; then
  echo "expected $expected_count scenarios, found $actual_count" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "scenario validation failed with $failures issue(s)" >&2
  exit 1
fi

echo "scenario validation passed"
