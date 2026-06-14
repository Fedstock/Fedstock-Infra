locals {
  log_groups = merge(
    {
      backend = "/ecs/${var.name_prefix}-backend"
    },
    var.enable_ai_backend ? {
      ai_backend = "/ecs/${var.name_prefix}-ai"
    } : {}
  )
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = var.retention_in_days

  tags = merge(var.tags, {
    Name    = each.value
    Service = each.key
  })
}
