# =============================================================================
# FRONTEND MODULE - variables.tf
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the frontend instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the internal ALB for Flask API"
  type        = string
}
