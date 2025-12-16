# =============================================================================
# FRONTEND MODULE - outputs.tf
# =============================================================================

output "frontend_public_ip" {
  description = "Public IP of the Nginx frontend"
  value       = aws_instance.frontend.public_ip
}

output "frontend_public_dns" {
  description = "Public DNS of the Nginx frontend"
  value       = aws_instance.frontend.public_dns
}

output "frontend_security_group_id" {
  description = "Security group ID of the frontend"
  value       = aws_security_group.frontend.id
}
