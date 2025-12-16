# =============================================================================
# ROOT MODULE - main.tf
# =============================================================================
# This is the entry point for our infrastructure. It:
# 1. Configures Terraform and the AWS provider
# 2. Calls all child modules (networking, alb, asg, rds, frontend)
# 3. Passes variables between modules as needed
# =============================================================================

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# =============================================================================
# MODULE CALLS
# =============================================================================

# -----------------------------------------------------------------------------
# Networking Module - VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
# -----------------------------------------------------------------------------
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# -----------------------------------------------------------------------------
# ALB Module - Application Load Balancer (Internal for Flask API)
# -----------------------------------------------------------------------------
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

# -----------------------------------------------------------------------------
# ASG Module - Auto Scaling Group for Flask App (in Private Subnets)
# -----------------------------------------------------------------------------
module "asg" {
  source                = "./modules/asg"
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  key_name              = var.key_name
}

# -----------------------------------------------------------------------------
# RDS Module - MySQL Database in Private Subnets
# -----------------------------------------------------------------------------
module "rds" {
  source                = "./modules/rds"
  project_name          = var.project_name
  private_subnet_ids    = module.networking.private_subnet_ids
  vpc_id                = module.networking.vpc_id
  app_security_group_id = module.asg.app_security_group_id
  db_username           = var.db_username
  db_password           = var.db_password
}

# -----------------------------------------------------------------------------
# Frontend Module - Nginx in Public Subnet
# -----------------------------------------------------------------------------
module "frontend" {
  source           = "./modules/frontend"
  project_name     = var.project_name
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_ids[0]
  key_name         = var.key_name
  alb_dns_name     = module.alb.alb_dns_name
}
