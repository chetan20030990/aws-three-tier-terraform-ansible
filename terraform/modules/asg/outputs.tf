# =============================================================================
# ASG MODULE - outputs.tf
# =============================================================================

output "app_security_group_id" {
  description = "Security group ID for app instances (RDS needs this)"
  value       = aws_security_group.app.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}
