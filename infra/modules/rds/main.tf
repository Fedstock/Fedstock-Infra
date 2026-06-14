resource "aws_security_group" "postgres" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "Allow PostgreSQL access from private application subnets"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.postgres.id
  cidr_ipv4         = each.value
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "postgres" {
  security_group_id = aws_security_group.postgres.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-postgres-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-subnet-group"
  })
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_encrypted     = true

  db_name  = var.postgres_db_name
  username = var.postgres_username
  password = var.manage_master_user_password ? null : var.postgres_password

  manage_master_user_password = var.manage_master_user_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  multi_az                = var.multi_az

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
