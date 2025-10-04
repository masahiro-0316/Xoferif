#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

LOG_DIR="${DJANGO_LOG_DIR:-/app/logs}"
mkdir -p "${LOG_DIR}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

STATUS=0

run_tool() {
  local tool="$1"
  local log_name="$2"
  shift 2

  local log_file="${LOG_DIR}/${log_name}-${TIMESTAMP}.log"

  if command -v "${tool}" >/dev/null 2>&1; then
    echo "Running ${tool}..."
    set +e
    "${tool}" "$@" | tee "${log_file}"
    local exit_code=${PIPESTATUS[0]}
    set -e
    if [[ ${exit_code} -ne 0 ]]; then
      echo "${tool} exited with status ${exit_code}" | tee -a "${log_file}"
      STATUS=1
    fi
  else
    echo "${tool} is not installed; skipping." | tee "${log_file}"
  fi
}

run_tool "ruff" "ruff" "."
run_tool "black" "black" "--check" "."
run_tool "mypy" "mypy" "."
run_tool "bandit" "bandit" "-r" "."
run_tool "pip-audit" "pip-audit" "--progress-spinner" "off"
run_tool "pytest" "pytest" "-vv"

exit ${STATUS}
