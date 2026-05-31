#!/usr/bin/env bash
set -euo pipefail

failures=0
script_count=0

report() {
  local message="${1:-}"

  echo "$message"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "$message" >> "$GITHUB_STEP_SUMMARY"
  fi
}

report_table_header() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "## Script Validation"
      echo
      echo "| Script | Executable | Shebang | Bash syntax | ShellCheck |"
      echo "| --- | --- | --- | --- | --- |"
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

report_table_row() {
  local script="$1"
  local executable="$2"
  local shebang="$3"
  local syntax="$4"
  local shellcheck="$5"

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "| \`$script\` | $executable | $shebang | $syntax | $shellcheck |" >> "$GITHUB_STEP_SUMMARY"
  fi
}

validate_script() {
  local script="$1"
  local executable="pass"
  local shebang="pass"
  local syntax="pass"
  local shellcheck_result="skipped"

  script_count=$((script_count + 1))
  echo "::group::$script"
  echo "checking executable bit"
  if [[ ! -x "$script" ]]; then
    executable="fail"
    echo "not executable: $script" >&2
    failures=$((failures + 1))
  fi

  echo "checking shebang"
  if [[ "$(head -n 1 "$script")" != "#!/usr/bin/env bash" ]]; then
    shebang="fail"
    echo "invalid shebang in $script" >&2
    failures=$((failures + 1))
  fi

  echo "checking bash syntax"
  if ! bash -n "$script"; then
    syntax="fail"
    failures=$((failures + 1))
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    echo "running shellcheck"
    if shellcheck "$script"; then
      shellcheck_result="pass"
    else
      shellcheck_result="fail"
      failures=$((failures + 1))
    fi
  else
    echo "shellcheck not installed; skipping"
  fi

  echo "result: executable=$executable shebang=$shebang syntax=$syntax shellcheck=$shellcheck_result"
  echo "::endgroup::"
  report_table_row "$script" "$executable" "$shebang" "$syntax" "$shellcheck_result"
}

report_table_header

while IFS= read -r script; do
  validate_script "$script"
done < <(find scripts -maxdepth 1 -type f -name '*.sh' | sort)

if [[ "$script_count" -eq 0 ]]; then
  echo "no shell scripts found under scripts/" >&2
  exit 1
fi

if [[ "$failures" -gt 0 ]]; then
  report
  report "script validation failed with $failures issue(s)"
  exit 1
fi

report
report "script validation passed for $script_count script(s)"
