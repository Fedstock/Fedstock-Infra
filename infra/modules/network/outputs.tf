output "vpc_id" {
  description = "VPC id."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet ids."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet ids."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_id" {
  description = "NAT Gateway id."
  value       = aws_nat_gateway.this.id
}
