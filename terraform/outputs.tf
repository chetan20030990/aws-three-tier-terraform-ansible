# =============================================================================
# ROOT MODULE - outputs.tf
# =============================================================================

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# -----------------------------------------------------------------------------
# Frontend Outputs
# -----------------------------------------------------------------------------
output "frontend_public_ip" {
  description = "Public IP of Nginx frontend - ACCESS YOUR APP HERE"
  value       = module.frontend.frontend_public_ip
}

output "frontend_public_dns" {
  description = "Public DNS of Nginx frontend"
  value       = module.frontend.frontend_public_dns
}

# -----------------------------------------------------------------------------
# ALB Outputs (Internal - Flask API)
# -----------------------------------------------------------------------------
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (internal)"
  value       = module.alb.alb_dns_name
}

# -----------------------------------------------------------------------------
# ASG Outputs
# -----------------------------------------------------------------------------
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

# -----------------------------------------------------------------------------
# RDS Outputs
# -----------------------------------------------------------------------------
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "rds_host" {
  description = "RDS hostname (for Ansible)"
  value       = module.rds.db_host
}

# -----------------------------------------------------------------------------
# Combined Output for Ansible
# -----------------------------------------------------------------------------
output "ansible_vars" {
  description = "Variables to pass to Ansible"
  value = {
    alb_dns_name       = module.alb.alb_dns_name
    db_host            = module.rds.db_host
    db_name            = module.rds.db_name
    db_port            = module.rds.db_port
    frontend_public_ip = module.frontend.frontend_public_ip
  }
}
