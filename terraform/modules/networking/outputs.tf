# =============================================================================
# NETWORKING MODULE - outputs.tf
# =============================================================================
# These values are passed back to the root module and other modules
# Other modules need these IDs to create resources in our VPC/subnets
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id  # Returns list: [subnet-xxx, subnet-yyy]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
