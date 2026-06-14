resource "aws_dynamodb_table" "model_version" {
  name         = "${var.name_prefix}-model-version-table"
  billing_mode = var.billing_mode
  hash_key     = "model_id"
  range_key    = "version"

  attribute {
    name = "model_id"
    type = "S"
  }

  attribute {
    name = "version"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-model-version-table"
  })
}

resource "aws_dynamodb_table" "round" {
  name         = "${var.name_prefix}-round-table"
  billing_mode = var.billing_mode
  hash_key     = "round_id"

  attribute {
    name = "round_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-round-table"
  })
}

resource "aws_dynamodb_table" "participant_update" {
  name         = "${var.name_prefix}-participant-update-table"
  billing_mode = var.billing_mode
  hash_key     = "round_id"
  range_key    = "participant_id"

  attribute {
    name = "round_id"
    type = "S"
  }

  attribute {
    name = "participant_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-participant-update-table"
  })
}
