#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BACKEND_REPO_PATH="${ROOT_DIR}/../Fedstock-Backend"
AI_REPO_PATH="${ROOT_DIR}/../Fedstock-AI"
IMAGE_TAG="v1"
AWS_REGION="ap-northeast-2"
SKIP_TERRAFORM="false"
SKIP_BUILD="false"
SKIP_AI_DEPLOY="true"
SKIP_SMOKE="true"
CALL_API="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend-repo-path)
      BACKEND_REPO_PATH="$2"
      shift 2
      ;;
    --ai-repo-path)
      AI_REPO_PATH="$2"
      shift 2
      ;;
    --image-tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --aws-region)
      AWS_REGION="$2"
      shift 2
      ;;
    --skip-terraform)
      SKIP_TERRAFORM="true"
      shift
      ;;
    --skip-build)
      SKIP_BUILD="true"
      shift
      ;;
    --run-ai-deploy)
      SKIP_AI_DEPLOY="false"
      shift
      ;;
    --skip-smoke)
      SKIP_SMOKE="true"
      shift
      ;;
    --run-smoke)
      SKIP_SMOKE="false"
      shift
      ;;
    --call-api)
      CALL_API="true"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "${SKIP_TERRAFORM}" != "true" ]]; then
  "${SCRIPT_DIR}/terraform_init.sh"
  "${SCRIPT_DIR}/terraform_plan.sh"
  "${SCRIPT_DIR}/terraform_apply.sh"
fi

if [[ "${SKIP_BUILD}" != "true" ]]; then
  "${SCRIPT_DIR}/build_and_push_backend.sh" \
    --repo-path "${BACKEND_REPO_PATH}" \
    --image-tag "${IMAGE_TAG}" \
    --aws-region "${AWS_REGION}"

  "${SCRIPT_DIR}/build_and_push_ai_backend.sh" \
    --repo-path "${AI_REPO_PATH}" \
    --image-tag "${IMAGE_TAG}" \
    --aws-region "${AWS_REGION}"
fi

"${SCRIPT_DIR}/deploy_backend.sh" --aws-region "${AWS_REGION}"

if [[ "${SKIP_AI_DEPLOY}" != "true" ]]; then
  "${SCRIPT_DIR}/deploy_ai_backend.sh" --aws-region "${AWS_REGION}"
fi

if [[ "${SKIP_SMOKE}" != "true" ]]; then
  if [[ "${CALL_API}" == "true" ]]; then
    "${SCRIPT_DIR}/run_test_round.sh" --aws-region "${AWS_REGION}" --call-api
  else
    "${SCRIPT_DIR}/run_test_round.sh" --aws-region "${AWS_REGION}"
  fi
fi
