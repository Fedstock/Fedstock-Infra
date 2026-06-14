# Fedstock Infra 프로젝트 명세서

## 1. 프로젝트 개요

`Fedstock-Infra`는 `Fedstock-backend`, `Fedstock-ai` 두 애플리케이션 레포를 AWS에 배포하기 위한 인프라 레포다. 이 레포에는 애플리케이션 코드나 웹 프런트 배포 정의를 두지 않는다.

Spring Backend는 사용자 API, PostgreSQL, S3, DynamoDB, AI 서비스 호출을 담당한다. AI Backend는 inference, federated learning aggregation, model evaluation, approved model reload를 담당한다.

이 구조는 MSA가 아니다. Spring Backend가 서비스 API와 AI 기능 호출을 중심에서 오케스트레이션하는 `Spring Backend 중심의 AI Backend 연동형 분리 백엔드 구조`다.

## 2. 레포 구성

- `Fedstock-backend`: Spring Backend, 사용자 API, PostgreSQL/S3/DynamoDB 연동, AI 호출 orchestration
- `Fedstock-ai`: AI Backend, inference, aggregation, evaluation, model artifact 처리, model reload
- `Fedstock-Infra`: Terraform 인프라, AWS 리소스, 배포 스크립트, 문서

## 3. Fedstock-backend 책임

- Spring Boot REST API 구현
- PostgreSQL 기반 서비스 데이터 관리
- S3 presigned URL 발급
- artifact metadata 관리
- DynamoDB 기반 MLOps metadata 저장
- AI Backend HTTP 호출 모듈 구현
- aggregation/evaluation/reload 요청 오케스트레이션
- model status/version 조회 API 제공
- inference 요청 proxy 또는 orchestration API 제공

주요 Controller 예시:

- `HealthController`
- `FileController`
- `MlopsRoundController`
- `ParticipantUpdateController`
- `ModelController`
- `PredictionController`

주요 Service 예시:

- `S3Service`
- `RoundService`
- `ParticipantUpdateService`
- `ModelVersionService`
- `AiBackendCaller`
- `PredictionService`

## 4. Fedstock-ai 책임

- AI API 서버 구현
- `/health`, `/ai/predict`, `/ai/model/current` 제공
- `/internal/mlops/rounds/{roundId}/aggregate` 제공
- `/internal/mlops/models/{version}/evaluate` 제공
- `/internal/mlops/models/reload` 제공
- S3 artifact download/upload
- DynamoDB model metadata 조회/수정
- aggregation mock 또는 실제 구현
- model loader/evaluator 구현

## 5. 시스템 아키텍처

기본 서비스 흐름:

```text
External User/System
  -> Fedstock-backend
     -> PostgreSQL
     -> S3
     -> DynamoDB
     -> Fedstock-ai
```

MLOps 흐름:

```text
External Participant/System
  -> Fedstock-backend에 upload URL 요청
  -> S3에 update artifact 업로드
  -> Fedstock-backend에 update metadata 전송
  -> Fedstock-backend가 Fedstock-ai에 aggregation 요청
  -> Fedstock-ai가 update artifact 조회
  -> aggregation 수행
  -> global model 생성
  -> S3에 global model 저장
  -> evaluation 수행
  -> model status 변경
  -> inference model reload
```

## 6. AWS 인프라 목표

`Fedstock-Infra`는 prod 환경 기준으로 다음 AWS 인프라를 Terraform으로 구성한다.

- VPC
- Public Subnet 2개
- Private Subnet 2개
- Internet Gateway
- NAT Gateway
- Security Groups
- ALB
- ECS Fargate Cluster
- ECR repositories 2개
- S3 artifact bucket
- RDS PostgreSQL
- DynamoDB metadata tables
- CloudWatch Log Groups
- IAM roles and policies
- AWS Secrets Manager 기반 RDS master password

배치 원칙:

- Public Subnet: ALB, NAT Gateway
- Private Subnet: backend ECS service, ai ECS service, RDS PostgreSQL
- Regional/Managed Resources: S3, ECR, DynamoDB, CloudWatch Logs, Secrets Manager

## 7. ALB 라우팅

- `/api/*` -> Fedstock-backend
- `/health` -> Fedstock-backend
- default -> Fedstock-backend

외부 ALB는 Fedstock-ai로 직접 라우팅하지 않는다. AI health, inference, aggregation, evaluation, reload는 Fedstock-backend가 받은 뒤 내부 통신으로 Fedstock-ai를 호출한다. 이 원칙 때문에 Backend가 gateway/orchestrator 역할을 수행한다.

## 8. 데이터 저장소 역할

### PostgreSQL

- 사용자 정보
- 서비스 도메인 데이터
- 파일 metadata
- 요청 이력
- 필요 시 모델 metadata 일부

### S3

- participant update artifact
- global model artifact
- evaluation report
- uploaded file
- initial model

### DynamoDB

- model version/status
- round status
- participant update status
- model artifact S3 path

### Secrets Manager

- RDS master password

## 9. API 설계

외부 요청에서 Fedstock-backend로 호출:

- `GET /health`
- `POST /api/mlops/rounds`
- `GET /api/mlops/rounds/{roundId}`
- `POST /api/mlops/rounds/{roundId}/participants/{participantId}/upload-url`
- `POST /api/mlops/rounds/{roundId}/participants/{participantId}/updates`
- `POST /api/mlops/rounds/{roundId}/aggregate` planned
- `GET /api/mlops/models`
- `GET /api/mlops/models/latest`
- `GET /api/mlops/models/{version}`
- `POST /api/mlops/models/{version}/approve`
- `POST /api/predict`

Fedstock-backend에서 Fedstock-ai로 호출:

- `GET /health`
- `POST /internal/mlops/rounds/{roundId}/aggregate`
- `POST /internal/mlops/models/{version}/evaluate`
- `POST /internal/mlops/models/reload`
- `GET /ai/model/current`
- `POST /ai/predict`

`/internal/*` API는 일반 사용자에게 직접 노출하지 않는다.

## 10. Artifact 저장 규칙

```text
s3://<artifact-bucket>/
  participant-updates/
    round-{roundId}/
      participant-{participantId}.pt
  global-models/
    global-model-v{version}.pt
  evaluation-reports/
    global-model-v{version}.json
  initial-model/
    initial-model.pt
```

모델 상태:

- `candidate`
- `approved`
- `rejected`
- `production`
- `archived`

## 11. DynamoDB 테이블 설계

### ModelVersionTable

- 키: `PK=model_id`, `SK=version`
- 필드: `model_id`, `version`, `s3_path`, `status`, `accuracy`, `loss`, `round_id`, `created_at`, `approved_at`, `deployed_at`

### RoundTable

- 키: `PK=round_id`
- 필드: `round_id`, `status`, `expected_participants`, `received_participants`, `aggregation_method`, `created_at`, `completed_at`

### ParticipantUpdateTable

- 키: `PK=round_id`, `SK=participant_id`
- 필드: `round_id`, `participant_id`, `update_s3_path`, `sample_count`, `local_accuracy`, `local_loss`, `status`, `created_at`

## 12. Terraform 구조

```text
Fedstock-Infra/
  README.md
  PROJECT_SPEC.md
  explain.md
  architecture/
    architecture_notes.md
  infra/
    envs/
      prod/
        provider.tf
        backend.tf
        main.tf
        variables.tf
        outputs.tf
        terraform.tfvars.example
    modules/
      network/
      s3/
      ecr/
      rds/
      dynamodb/
      alb/
      ecs/
      iam/
      cloudwatch/
  scripts/
    terraform_init.sh
    terraform_plan.sh
    terraform_apply.sh
    terraform_destroy.sh
    build_and_push_backend.sh
    build_and_push_ai_backend.sh
    deploy_backend.sh
    deploy_ai_backend.sh
    seed_model.sh
    run_test_round.sh
```

## 13. Terraform 구현 규칙

- prod 환경을 기준으로 구현한다.
- 모든 리소스 이름은 `project-env-resource` 형식을 따른다.
- `project` 기본값은 `fl-mlops`, `env` 기본값은 `prod`로 한다.
- ALB만 public subnet에 배치한다.
- ECS service와 RDS는 private subnet에 배치한다.
- S3 bucket public access block을 활성화한다.
- RDS public access는 false다.
- RDS password는 Secrets Manager로 관리한다.
- IAM은 execution role과 task role을 분리한다.
- CloudWatch Log Group은 서비스별로 분리한다.

## 14. 환경변수 규칙

Fedstock-backend:

- `SPRING_PROFILES_ACTIVE=prod`
- `AWS_REGION=ap-northeast-2`
- `ARTIFACT_BUCKET=<artifact-bucket>`
- `DB_HOST=<rds-endpoint>`
- `DB_PORT=5432`
- `DB_NAME=app`
- `DB_USERNAME=app`
- `DB_PASSWORD=<Secrets Manager에서 ECS secret으로 주입>`

현재 `Fedstock-backend` 코드가 MLOps table env와 AI URL env를 읽지 않으므로 Terraform도 backend task에 `MODEL_TABLE`, `ROUND_TABLE`, `PARTICIPANT_UPDATE_TABLE`, `AI_BACKEND_URL`을 주입하지 않는다. 해당 기능을 backend에 구현하면 Infra도 함께 확장한다.

Fedstock-ai:

- `ENV=prod`
- `AWS_REGION=ap-northeast-2`
- `ARTIFACT_BUCKET=<artifact-bucket>`
- `MODEL_TABLE=fl-mlops-prod-model-version-table`
- `ROUND_TABLE=fl-mlops-prod-round-table`
- `PARTICIPANT_UPDATE_TABLE=fl-mlops-prod-participant-update-table`
- `MODEL_LOCAL_DIR=/tmp/models`

## 15. 보안 규칙

- AWS access key를 커밋하지 않는다.
- DB password를 커밋하지 않고 AWS Secrets Manager로 관리한다.
- `.env` 파일을 커밋하지 않는다.
- `terraform.tfvars`를 커밋하지 않는다.
- `terraform.tfvars.example`만 커밋한다.
- S3 bucket public access를 차단한다.
- RDS public access를 false로 설정한다.
- ECS task role에만 S3/DynamoDB 권한을 부여한다.
- execution role과 task role을 분리한다.
- AI internal API는 일반 사용자 직접 호출을 전제로 설계하지 않는다.

## 16. MVP 완료 기준

- Terraform apply로 prod 인프라가 생성된다.
- VPC, subnet, ALB, ECS, ECR, S3, RDS, DynamoDB, CloudWatch, Secrets Manager 연동이 생성된다.
- Fedstock-backend, Fedstock-ai용 ECR repository가 존재한다.
- backend와 ai ECS service가 생성된다.
- ALB DNS로 backend health check가 가능하다.
- AI health check가 가능하다.
- backend가 AI를 호출할 수 있다.
- backend가 S3 presigned URL을 발급할 수 있다.
- participant update artifact와 model artifact가 S3에 저장될 수 있다.
- model metadata가 DynamoDB에 저장될 수 있다.
- AI가 latest approved model을 조회하고 로드할 수 있다.
- CloudWatch에서 backend와 AI 로그를 확인할 수 있다.
