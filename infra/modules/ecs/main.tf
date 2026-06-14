locals {
  backend_image    = "${var.backend_repository_url}:${var.backend_image_tag}"
  ai_backend_image = "${var.ai_backend_repository_url}:${var.ai_backend_image_tag}"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-cluster"
  })
}

resource "aws_security_group" "backend" {
  name        = "${var.name_prefix}-backend-service-sg"
  description = "Backend ECS service security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-service-sg"
  })
}

resource "aws_security_group" "ai_backend" {
  count = var.enable_ai_backend ? 1 : 0

  name        = "${var.name_prefix}-ai-service-sg"
  description = "AI ECS service security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-service-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.backend_container_port
  ip_protocol                  = "tcp"
  to_port                      = var.backend_container_port
}

resource "aws_vpc_security_group_ingress_rule" "ai_backend_from_alb" {
  count = var.enable_ai_backend ? 1 : 0

  security_group_id            = aws_security_group.ai_backend[0].id
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.ai_backend_container_port
  ip_protocol                  = "tcp"
  to_port                      = var.ai_backend_container_port
}

resource "aws_vpc_security_group_ingress_rule" "ai_backend_from_backend" {
  count = var.enable_ai_backend ? 1 : 0

  security_group_id            = aws_security_group.ai_backend[0].id
  referenced_security_group_id = aws_security_group.backend.id
  from_port                    = var.ai_backend_container_port
  ip_protocol                  = "tcp"
  to_port                      = var.ai_backend_container_port
}

resource "aws_vpc_security_group_egress_rule" "backend_all" {
  security_group_id = aws_security_group.backend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "ai_backend_all" {
  count = var.enable_ai_backend ? 1 : 0

  security_group_id = aws_security_group.ai_backend[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu.backend
  memory                   = var.task_memory.backend
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.backend_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.backend_image
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
          value = "validate"
        },
        {
          name  = "ARTIFACT_BUCKET"
          value = var.artifact_bucket_name
        },
        {
          name  = "AI_BACKEND_URL"
          value = "http://${var.alb_dns_name}/ai"
        },
        {
          name  = "DB_HOST"
          value = var.postgres_endpoint
        },
        {
          name  = "DB_PORT"
          value = tostring(var.postgres_port)
        },
        {
          name  = "DB_NAME"
          value = var.postgres_db_name
        },
        {
          name  = "DB_USERNAME"
          value = var.postgres_username
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.postgres_password_secret_arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_names.backend
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-task"
  })
}

resource "aws_ecs_task_definition" "ai_backend" {
  count = var.enable_ai_backend ? 1 : 0

  family                   = "${var.name_prefix}-ai"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu.ai_backend
  memory                   = var.task_memory.ai_backend
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.ai_backend_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "ai"
      image     = local.ai_backend_image
      essential = true
      portMappings = [
        {
          containerPort = var.ai_backend_container_port
          hostPort      = var.ai_backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = "prod"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "ARTIFACT_BUCKET"
          value = var.artifact_bucket_name
        },
        {
          name  = "MODEL_TABLE"
          value = var.model_table_name
        },
        {
          name  = "ROUND_TABLE"
          value = var.round_table_name
        },
        {
          name  = "PARTICIPANT_UPDATE_TABLE"
          value = var.participant_update_table_name
        },
        {
          name  = "MODEL_LOCAL_DIR"
          value = "/tmp/models"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_names.ai_backend
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ai"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-task"
  })
}

resource "aws_ecs_service" "backend" {
  name            = "${var.name_prefix}-backend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_counts.backend
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-service"
  })
}

resource "aws_ecs_service" "ai_backend" {
  count = var.enable_ai_backend ? 1 : 0

  name            = "${var.name_prefix}-ai-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ai_backend[0].arn
  desired_count   = var.desired_counts.ai_backend
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ai_backend[0].id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.ai_backend_target_group_arn == null ? [] : [1]

    content {
      target_group_arn = var.ai_backend_target_group_arn
      container_name   = "ai"
      container_port   = var.ai_backend_container_port
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-service"
  })
}
