locals {
  name_prefix = "${var.project}-${var.env}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
      Repository  = "Fedstock-Infra"
    },
    var.extra_tags
  )

  dynamodb_table_arns = var.enable_mlops_resources ? module.dynamodb[0].table_arns : []

  model_table_name              = var.enable_mlops_resources ? module.dynamodb[0].model_version_table_name : ""
  round_table_name              = var.enable_mlops_resources ? module.dynamodb[0].round_table_name : ""
  participant_update_table_name = var.enable_mlops_resources ? module.dynamodb[0].participant_update_table_name : ""
}

module "network" {
  source = "../../modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix          = local.name_prefix
  artifact_bucket_name = var.artifact_bucket_name
  tags                 = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "dynamodb" {
  count = var.enable_mlops_resources ? 1 : 0

  source = "../../modules/dynamodb"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  name_prefix       = local.name_prefix
  enable_ai_backend = var.enable_ai_service
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                 = local.name_prefix
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  allowed_cidr_blocks         = module.network.private_subnet_cidrs
  postgres_db_name            = var.postgres_db_name
  postgres_username           = var.postgres_username
  postgres_password           = var.postgres_password
  manage_master_user_password = var.manage_rds_master_user_password
  instance_class              = var.rds_instance_class
  allocated_storage           = var.rds_allocated_storage
  engine_version              = var.rds_engine_version
  backup_retention_period     = var.rds_backup_retention_period
  multi_az                    = var.rds_multi_az
  deletion_protection         = var.rds_deletion_protection
  skip_final_snapshot         = var.rds_skip_final_snapshot
  tags                        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix                 = local.name_prefix
  vpc_id                      = module.network.vpc_id
  public_subnet_ids           = module.network.public_subnet_ids
  allowed_ingress_cidr_blocks = var.allowed_alb_ingress_cidr_blocks
  certificate_arn             = var.existing_certificate_arn
  enable_ai_backend           = var.enable_ai_service
  backend_container_port      = var.backend_container_port
  ai_backend_container_port   = var.ai_backend_container_port
  tags                        = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix         = local.name_prefix
  artifact_bucket_arn = module.s3.artifact_bucket_arn
  dynamodb_table_arns = local.dynamodb_table_arns
  secrets_manager_secret_arns = [
    module.rds.master_user_secret_arn
  ]
  tags = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix                   = local.name_prefix
  aws_region                    = var.aws_region
  vpc_id                        = module.network.vpc_id
  private_subnet_ids            = module.network.private_subnet_ids
  alb_security_group_id         = module.alb.alb_security_group_id
  backend_target_group_arn      = module.alb.backend_target_group_arn
  ai_backend_target_group_arn   = module.alb.ai_backend_target_group_arn
  enable_ai_backend             = var.enable_ai_service
  backend_repository_url        = module.ecr.backend_repository_url
  ai_backend_repository_url     = module.ecr.ai_backend_repository_url
  backend_image_tag             = var.backend_image_tag
  ai_backend_image_tag          = var.ai_backend_image_tag
  backend_container_port        = var.backend_container_port
  ai_backend_container_port     = var.ai_backend_container_port
  task_execution_role_arn       = module.iam.task_execution_role_arn
  backend_task_role_arn         = module.iam.backend_task_role_arn
  ai_backend_task_role_arn      = module.iam.ai_backend_task_role_arn
  log_group_names               = module.cloudwatch.log_group_names
  artifact_bucket_name          = module.s3.artifact_bucket_name
  model_table_name              = local.model_table_name
  round_table_name              = local.round_table_name
  participant_update_table_name = local.participant_update_table_name
  postgres_endpoint             = module.rds.postgres_endpoint
  postgres_port                 = module.rds.postgres_port
  postgres_db_name              = var.postgres_db_name
  postgres_username             = var.postgres_username
  postgres_password_secret_arn  = module.rds.master_user_secret_arn
  alb_dns_name                  = module.alb.alb_dns_name
  public_domain_name            = var.domain_name
  desired_counts                = var.ecs_desired_counts
  task_cpu                      = var.ecs_task_cpu
  task_memory                   = var.ecs_task_memory
  tags                          = local.common_tags

  depends_on = [module.alb]
}
