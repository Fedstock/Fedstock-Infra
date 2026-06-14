#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/envs/prod"
PLAN_FILE="${ENV_DIR}/prod.tfplan"

if [[ -f "${PLAN_FILE}" ]]; then
  terraform -chdir="${ENV_DIR}" apply "${PLAN_FILE}"
else
  terraform -chdir="${ENV_DIR}" apply "$@"
fi
