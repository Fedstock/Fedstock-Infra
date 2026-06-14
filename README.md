# Fedstock-Infra

## Overview

Fedstock-Infra는 Fedstock Backend와 AI Backend를 AWS production 환경에 배포하기 위한 Terraform 인프라 레포입니다.

이 레포에는 애플리케이션 코드가 포함되지 않습니다. Fedstock 서비스 운영에 필요한 클라우드 인프라, 배포 스크립트, 네트워크, 저장소, 컨테이너 레지스트리, 데이터베이스, secret, 운영 리소스를 관리합니다.

production 구조는 Spring Backend를 중심으로 설계되어 있습니다. 외부 요청은 ALB를 통해 Backend service로 들어오고, Backend는 인증된 클라이언트 요청을 검증한 뒤 queue 또는 batch 흐름을 제어하며, AI 처리가 필요할 때 AI Backend를 호출합니다.

## Tech Stack & Role & Architecture

| Category | Content |
| --- | --- |
| IaC | Terraform |
| Cloud | AWS |
| Runtime | ECS Fargate |
| Registry | ECR |
| Database | RDS PostgreSQL |
| Storage | S3 Artifact Bucket |
| Secret Management | AWS Secrets Manager |
| Network | VPC, public/private subnets, ALB, NAT Gateway |
| Observability | CloudWatch Logs |
| Deployment | Shell script |
| 담당자 | 안재현 AWS cloud engineering 100% |

Architecture:



## Infrastructure Scope

이 레포는 production 기준으로 아래 인프라를 정의합니다.

- public/private subnet 기반 VPC network
- Internet Gateway와 NAT Gateway
- Application Load Balancer
- ECS Fargate cluster와 service
- Backend, AI image를 위한 ECR repository
- private subnet에 배치되는 RDS PostgreSQL
- AI/FL artifact 저장을 위한 S3 bucket
- CloudWatch log group
- ECS task 실행을 위한 IAM role과 policy
- database credential 관리를 위한 AWS Secrets Manager 연동


## Repository Structure

```text
Fedstock-Infra/
├── infra/
│   ├── envs/
│   │   └── prod/          # production Terraform composition
│   └── modules/           # reusable Terraform modules
├── scripts/               # Terraform, image build, and ECS deploy scripts
├── README.md
└── .gitignore
```

## Environment & Secrets

실제 배포 값은 커밋하지 않습니다.

커밋에서 제외하는 local file 예시는 다음과 같습니다.

- `terraform.tfvars`
- Terraform state file
- Terraform plan file
- `.env`
- private key와 certificate


RDS master password는 AWS Secrets Manager에서 생성하고 관리합니다. ECS는 database credential을 plain configuration이 아니라 task definition secret을 통해 전달받습니다.

## Deploy Flow

Terraform 초기화 및 적용:

```bash
./scripts/terraform_init.sh
./scripts/terraform_plan.sh
./scripts/terraform_apply.sh
```

Backend image build 및 배포:

```bash
./scripts/build_and_push_backend.sh
./scripts/deploy_backend.sh
```

AI service를 활성화할 때 AI Backend image build 및 배포:

```bash
./scripts/build_and_push_ai_backend.sh
./scripts/deploy_ai_backend.sh
```

## Scripts

| Script | Role |
| --- | --- |
| `terraform_init.sh` | production 환경 Terraform 초기화 |
| `terraform_plan.sh` | 인프라 변경 사항 미리 확인 |
| `terraform_apply.sh` | production 인프라 적용 |
| `terraform_destroy.sh` | 명시적으로 의도한 경우 인프라 제거 |
| `build_and_push_backend.sh` | Backend Docker image를 build하고 ECR에 push |
| `deploy_backend.sh` | Backend ECS service 강제 재배포 |
| `build_and_push_ai_backend.sh` | AI Backend Docker image를 build하고 ECR에 push |
| `deploy_ai_backend.sh` | AI Backend ECS service 강제 재배포 |
| `deploy_all.sh` | 통합 배포 흐름 실행 |
| `seed_model.sh` | MLOps workflow용 초기 model artifact 등록 |
| `run_test_round.sh` | MLOps 검증용 test round 실행 |

## Security Notes

이 레포는 public-safe repository를 기준으로 관리합니다.

실제 AWS credential, Terraform state, private deployment variable, private key, certificate, runtime secret은 커밋하지 않습니다. 계정별 값은 ignored local file 또는 외부 secret management를 통해서만 주입합니다.
