#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/envs/prod"

AWS_REGION="ap-northeast-2"
MODEL_PATH=""
MODEL_ID="global-model"
VERSION="v0"
ACCURACY="0.0"
LOSS="0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aws-region)
      AWS_REGION="$2"
      shift 2
      ;;
    --model-path)
      MODEL_PATH="$2"
      shift 2
      ;;
    --model-id)
      MODEL_ID="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --accuracy)
      ACCURACY="$2"
      shift 2
      ;;
    --loss)
      LOSS="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

BUCKET="$(terraform -chdir="${ENV_DIR}" output -raw artifact_bucket_name)"
MODEL_TABLE="$(terraform -chdir="${ENV_DIR}" output -raw model_version_table_name)"

if [[ -z "${MODEL_TABLE}" ]]; then
  echo "ModelVersion DynamoDB table is not enabled. Set enable_mlops_resources=true before seeding a model." >&2
  exit 1
fi

TEMP_MODEL=""
if [[ -z "${MODEL_PATH}" ]]; then
  TEMP_MODEL="$(mktemp)"
  printf "mock initial model %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${TEMP_MODEL}"
  MODEL_PATH="${TEMP_MODEL}"
fi

S3_KEY="initial-model/initial-model.pt"
S3_PATH="s3://${BUCKET}/${S3_KEY}"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

aws s3 cp "${MODEL_PATH}" "${S3_PATH}" --region "${AWS_REGION}"

aws dynamodb put-item \
  --region "${AWS_REGION}" \
  --table-name "${MODEL_TABLE}" \
  --item "{
    \"model_id\": {\"S\": \"${MODEL_ID}\"},
    \"version\": {\"S\": \"${VERSION}\"},
    \"s3_path\": {\"S\": \"${S3_PATH}\"},
    \"status\": {\"S\": \"approved\"},
    \"accuracy\": {\"N\": \"${ACCURACY}\"},
    \"loss\": {\"N\": \"${LOSS}\"},
    \"round_id\": {\"S\": \"initial\"},
    \"created_at\": {\"S\": \"${NOW}\"},
    \"approved_at\": {\"S\": \"${NOW}\"}
  }"

if [[ -n "${TEMP_MODEL}" ]]; then
  rm -f "${TEMP_MODEL}"
fi

echo "Seeded ${MODEL_ID}/${VERSION} at ${S3_PATH}"
