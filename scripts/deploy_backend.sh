#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-northeast-2"
CLUSTER="fl-mlops-prod-ecs-cluster"
SERVICE="fl-mlops-prod-backend-service"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aws-region)
      AWS_REGION="$2"
      shift 2
      ;;
    --cluster)
      CLUSTER="$2"
      shift 2
      ;;
    --service)
      SERVICE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

aws ecs update-service \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --force-new-deployment
