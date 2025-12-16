# =============================================================================
# ALB MODULE - outputs.tf
# =============================================================================
# Other modules need these values:
# - ASG needs target_group_arn to register instances
# - ASG needs alb_security_group_id to allow traffic from ALB
# - Root module needs dns_name to show user where to access the app
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the load balancer (use this to access the app)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group (ASG registers instances here)"
  value       = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "Security group ID of ALB (app instances allow traffic from this)"
  value       = aws_security_group.alb.id
}
