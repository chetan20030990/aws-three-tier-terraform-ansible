# =============================================================================
# RDS MODULE - main.tf
# =============================================================================
# This module creates:
# - DB Subnet Group - tells RDS which subnets to use
# - Security Group - only allows MySQL traffic from app instances
# - RDS MySQL Instance - the actual database
#
# SECURITY:
# - RDS is in PRIVATE subnets (no direct internet access)
# - Security group ONLY allows port 3306 from app security group
# - This means only our Flask instances can connect to the database
# =============================================================================

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
# RDS requires a subnet group that spans at least 2 AZs
# We use our private subnets for security

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Database subnet group for ${var.project_name}"
  subnet_ids  = var.private_subnet_ids  # Private subnets only!

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Security Group for RDS
# -----------------------------------------------------------------------------
# CRITICAL: Only allows traffic from app instances on port 3306

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS MySQL instance"
  vpc_id      = var.vpc_id

  # Inbound: MySQL only from app security group
  ingress {
    description     = "MySQL from app instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]  # Only app instances!
  }

  # Outbound: Usually not needed for RDS, but allow all
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# -----------------------------------------------------------------------------
# RDS MySQL Instance
# -----------------------------------------------------------------------------
# Free tier eligible: db.t3.micro with 20GB storage

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  # Engine configuration
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"  # Free tier eligible
  allocated_storage    = 20              # 20 GB (free tier limit)
  storage_type         = "gp2"           # General purpose SSD

  # Database configuration
  db_name  = "capstone"       # Creates database named 'capstone'
  username = var.db_username  # Master username
  password = var.db_password  # Master password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # Not accessible from internet

  # Backup configuration (disabled for dev - enable in production)
  backup_retention_period = 0     # No backups (saves cost)
  skip_final_snapshot     = true  # Don't create snapshot on delete

  # Maintenance
  auto_minor_version_upgrade = true
  maintenance_window         = "Mon:00:00-Mon:03:00"

  # Performance Insights (disabled to stay free)
  performance_insights_enabled = false

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
