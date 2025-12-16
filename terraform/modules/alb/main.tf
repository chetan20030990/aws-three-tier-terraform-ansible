# =============================================================================
# ALB MODULE - main.tf
# =============================================================================
# This module creates:
# - Application Load Balancer (ALB) - distributes traffic to app instances
# - Target Group - where ALB sends traffic (our Flask instances)
# - Listener - listens on port 80 and forwards to target group
# - Security Group - controls what traffic can reach the ALB
#
# HOW IT WORKS:
# User Request → ALB (port 80) → Target Group → Flask Instances (port 5000)
# =============================================================================

# -----------------------------------------------------------------------------
# Security Group for ALB
# -----------------------------------------------------------------------------
# Controls inbound/outbound traffic to the load balancer
# We allow HTTP (80) from anywhere - this is the public entry point

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound: Allow HTTP from anywhere (this is public-facing)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all traffic out (needed to reach target instances)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------
# The ALB sits in public subnets and distributes traffic to backend instances
# "internet-facing" means it gets a public DNS name

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false  # internet-facing (not internal)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids  # Must be in at least 2 AZs

  # Enable deletion protection in production, disabled for learning
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------
# Defines WHERE the ALB sends traffic and HOW it checks instance health
# Our Flask app runs on port 5000

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = 5000  # Flask runs on port 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration
  # ALB periodically hits this endpoint to verify instances are healthy
  health_check {
    enabled             = true
    healthy_threshold   = 2      # 2 consecutive successes = healthy
    unhealthy_threshold = 2      # 2 consecutive failures = unhealthy
    timeout             = 5      # Wait 5 seconds for response
    interval            = 30     # Check every 30 seconds
    path                = "/items"  # Our Flask endpoint
    protocol            = "HTTP"
    matcher             = "200"  # Expect HTTP 200 OK
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

# -----------------------------------------------------------------------------
# ALB Listener
# -----------------------------------------------------------------------------
# Listens for incoming requests on port 80 and forwards to target group

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action: forward all traffic to our app target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
