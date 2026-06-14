#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/envs/prod"

AWS_REGION="ap-northeast-2"
ROUND_ID="round-$(date -u +%Y%m%d%H%M%S)"
PARTICIPANT_ID="participant-smoke"
CALL_API="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aws-region)
      AWS_REGION="$2"
      shift 2
      ;;
    --round-id)
      ROUND_ID="$2"
      shift 2
      ;;
    --participant-id)
      PARTICIPANT_ID="$2"
      shift 2
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

BUCKET="$(terraform -chdir="${ENV_DIR}" output -raw artifact_bucket_name)"
ROUND_TABLE="$(terraform -chdir="${ENV_DIR}" output -raw round_table_name)"
PARTICIPANT_UPDATE_TABLE="$(terraform -chdir="${ENV_DIR}" output -raw participant_update_table_name)"
ALB_DNS="$(terraform -chdir="${ENV_DIR}" output -raw alb_dns_name)"

if [[ -z "${ROUND_TABLE}" || -z "${PARTICIPANT_UPDATE_TABLE}" ]]; then
  echo "MLOps DynamoDB tables are not enabled. Set enable_mlops_resources=true before running this smoke test." >&2
  exit 1
fi

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
UPDATE_FILE="$(mktemp)"
printf "mock update for %s / %s\n" "${ROUND_ID}" "${PARTICIPANT_ID}" > "${UPDATE_FILE}"

S3_KEY="participant-updates/${ROUND_ID}/${PARTICIPANT_ID}.pt"
S3_PATH="s3://${BUCKET}/${S3_KEY}"

aws s3 cp "${UPDATE_FILE}" "${S3_PATH}" --region "${AWS_REGION}"
rm -f "${UPDATE_FILE}"

aws dynamodb put-item \
  --region "${AWS_REGION}" \
  --table-name "${ROUND_TABLE}" \
  --item "{
    \"round_id\": {\"S\": \"${ROUND_ID}\"},
    \"status\": {\"S\": \"ready_for_aggregation\"},
    \"expected_participants\": {\"N\": \"1\"},
    \"received_participants\": {\"N\": \"1\"},
    \"aggregation_method\": {\"S\": \"mock\"},
    \"created_at\": {\"S\": \"${NOW}\"}
  }"

aws dynamodb put-item \
  --region "${AWS_REGION}" \
  --table-name "${PARTICIPANT_UPDATE_TABLE}" \
  --item "{
    \"round_id\": {\"S\": \"${ROUND_ID}\"},
    \"participant_id\": {\"S\": \"${PARTICIPANT_ID}\"},
    \"update_s3_path\": {\"S\": \"${S3_PATH}\"},
    \"sample_count\": {\"N\": \"10\"},
    \"local_accuracy\": {\"N\": \"0.75\"},
    \"local_loss\": {\"N\": \"0.25\"},
    \"status\": {\"S\": \"uploaded\"},
    \"created_at\": {\"S\": \"${NOW}\"}
  }"

if [[ "${CALL_API}" == "true" ]]; then
  curl -fsS "http://${ALB_DNS}/health" || echo "Backend health check failed or service is not ready yet." >&2
  curl -fsS "http://${ALB_DNS}/ai/health" || echo "AI Backend health check failed or service is not ready yet." >&2
  curl -fsS -X POST "http://${ALB_DNS}/api/mlops/rounds/${ROUND_ID}/aggregate" || echo "Aggregation API failed or application endpoint is not implemented yet." >&2
else
  echo "Skipped API calls. Use --call-api after health and aggregation endpoints are implemented."
fi

echo "Created smoke round ${ROUND_ID} with participant update ${S3_PATH}"
