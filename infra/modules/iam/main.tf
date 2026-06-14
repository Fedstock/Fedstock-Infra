data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_secrets" {
  count = length(var.secrets_manager_secret_arns) > 0 ? 1 : 0

  statement {
    sid       = "ReadRuntimeSecrets"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_manager_secret_arns
  }
}

resource "aws_iam_policy" "task_execution_secrets" {
  count = length(var.secrets_manager_secret_arns) > 0 ? 1 : 0

  name   = "${var.name_prefix}-ecs-task-execution-secrets-policy"
  policy = data.aws_iam_policy_document.task_execution_secrets[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-task-execution-secrets-policy"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_secrets" {
  count = length(var.secrets_manager_secret_arns) > 0 ? 1 : 0

  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_secrets[0].arn
}

resource "aws_iam_role" "backend_task" {
  name               = "${var.name_prefix}-backend-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-task-role"
  })
}

resource "aws_iam_role" "ai_backend_task" {
  name               = "${var.name_prefix}-ai-backend-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-backend-task-role"
  })
}

data "aws_iam_policy_document" "backend_task" {
  statement {
    sid = "ArtifactBucketReadWrite"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.artifact_bucket_arn}/*"]
  }

  statement {
    sid       = "ArtifactBucketList"
    actions   = ["s3:ListBucket"]
    resources = [var.artifact_bucket_arn]
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []

    content {
      sid = "MlopsMetadataReadWrite"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ]
      resources = var.dynamodb_table_arns
    }
  }
}

resource "aws_iam_policy" "backend_task" {
  name   = "${var.name_prefix}-backend-task-policy"
  policy = data.aws_iam_policy_document.backend_task.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-task-policy"
  })
}

resource "aws_iam_role_policy_attachment" "backend_task" {
  role       = aws_iam_role.backend_task.name
  policy_arn = aws_iam_policy.backend_task.arn
}

data "aws_iam_policy_document" "ai_backend_task" {
  statement {
    sid = "ArtifactBucketReadWrite"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/*"
    ]
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []

    content {
      sid = "MlopsMetadataReadWrite"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ]
      resources = var.dynamodb_table_arns
    }
  }
}

resource "aws_iam_policy" "ai_backend_task" {
  name   = "${var.name_prefix}-ai-backend-task-policy"
  policy = data.aws_iam_policy_document.ai_backend_task.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-backend-task-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ai_backend_task" {
  role       = aws_iam_role.ai_backend_task.name
  policy_arn = aws_iam_policy.ai_backend_task.arn
}
