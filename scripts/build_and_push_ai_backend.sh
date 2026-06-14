#!/usr/bin/env bash
set -euo pipefail

REPO_PATH=""
IMAGE_TAG="latest"
AWS_REGION="ap-northeast-2"
PROJECT="fl-mlops"
ENVIRONMENT="prod"
PLATFORM="linux/amd64"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-path)
      REPO_PATH="$2"
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
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${REPO_PATH}" ]]; then
  echo "Usage: $0 --repo-path <Fedstock-ai-path> [--image-tag tag] [--aws-region region]" >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPOSITORY="${PROJECT}-${ENVIRONMENT}-ai-repo"
IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
docker build --platform "${PLATFORM}" -t "${ECR_REPOSITORY}:${IMAGE_TAG}" "${REPO_PATH}"
docker tag "${ECR_REPOSITORY}:${IMAGE_TAG}" "${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "${IMAGE_URI}"
