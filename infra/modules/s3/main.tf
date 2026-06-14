data "aws_caller_identity" "current" {}

locals {
  bucket_name = coalesce(var.artifact_bucket_name, "${var.name_prefix}-artifact-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "artifact" {
  bucket = local.bucket_name

  tags = merge(var.tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    id     = "expire-noncurrent-artifact-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_expiration_days
    }
  }
}
