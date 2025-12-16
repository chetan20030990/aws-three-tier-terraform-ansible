# =============================================================================
# ROOT MODULE - variables.tf
# =============================================================================
# These are the input variables for the root module.
# Values come from terraform.tfvars or command line (-var flags)
# =============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name - used for naming all resources"
  type        = string
  default     = "capstone"
}

# -----------------------------------------------------------------------------
# Network Settings
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  # Gives us 65,536 IP addresses
}

# -----------------------------------------------------------------------------
# Database Settings
# -----------------------------------------------------------------------------
variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true  # Marked sensitive - won't appear in logs
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true  # Marked sensitive - won't appear in logs
  
  # Basic validation - password must be at least 8 characters
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
  default     = "capstone-key"
}
