# =============================================================================
# NETWORKING MODULE - variables.tf
# =============================================================================
# Input variables for this module - passed in from root module
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
