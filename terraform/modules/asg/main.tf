# =============================================================================
# ASG MODULE - main.tf
# =============================================================================
# This module creates:
# - Launch Template - defines HOW to create EC2 instances
# - Auto Scaling Group - manages instance count (min 2, max 6)
# - Scaling Policies - scale out/in based on CPU usage
# - Security Group - controls traffic to app instances
#
# HOW AUTO-SCALING WORKS:
# 1. ASG maintains desired number of instances (starts at 2)
# 2. CloudWatch monitors CPU usage
# 3. If CPU > 50% for 2 minutes → add instance (scale out)
# 4. If CPU < 30% for 2 minutes → remove instance (scale in)
# 5. ALB health checks remove unhealthy instances automatically
# =============================================================================

# -----------------------------------------------------------------------------
# Get latest Amazon Linux 2 AMI
# -----------------------------------------------------------------------------
# This dynamically fetches the latest Amazon Linux 2 AMI ID
# So we don't hardcode an AMI that might become outdated

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Security Group for App Instances
# -----------------------------------------------------------------------------
# Only allows traffic from the ALB - instances are not directly accessible

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for Flask application instances"
  vpc_id      = var.vpc_id

  # Inbound: Only allow traffic from ALB on port 5000
  ingress {
    description     = "Flask from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]  # Only from ALB!
  }

  # Inbound: SSH for debugging (optional - remove in production)
  ingress {
    description = "SSH for debugging"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict to your IP
  }

  # Outbound: Allow all (needed for package installs, DB connection)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# -----------------------------------------------------------------------------
# Launch Template
# -----------------------------------------------------------------------------
# Defines the "recipe" for creating EC2 instances
# Includes: AMI, instance type, security group, and startup script

resource "aws_launch_template" "app" {
  name          = "${var.project_name}-app-lt"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"  # Free tier eligible for newer accounts
  key_name      = var.key_name  # SSH key for Ansible access

  # Network settings
  network_interfaces {
    associate_public_ip_address = false  # Private subnet - no public IP needed
    security_groups             = [aws_security_group.app.id]
  }

  # User data script - runs on first boot
  # This installs dependencies; Ansible will do the actual app deployment
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip git
    pip3 install flask mysql-connector-python gunicorn
    
    # Create app directory
    mkdir -p /opt/flask-app
    
    # Create a simple health check endpoint (Ansible will deploy full app)
    cat > /opt/flask-app/app.py << 'APPEOF'
    from flask import Flask, jsonify
    import os
    
    app = Flask(__name__)
    
    @app.route('/items')
    def get_items():
        # Placeholder - Ansible will deploy the real app with DB connection
        return jsonify(["placeholder - waiting for Ansible deployment"])
    
    @app.route('/health')
    def health():
        return jsonify({"status": "healthy"})
    
    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=5000)
    APPEOF
    
    # Start Flask app (Ansible will configure proper systemd service)
    cd /opt/flask-app
    nohup python3 app.py > /var/log/flask.log 2>&1 &
  EOF
  )

  # Enable detailed monitoring for scaling metrics
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-app-lt"
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------
# Manages the fleet of EC2 instances

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  desired_capacity    = 2   # Start with 2 instances
  min_size            = 2   # Never go below 2
  max_size            = 6   # Never exceed 6
  vpc_zone_identifier = var.private_subnet_ids  # Launch in private subnets
  target_group_arns   = [var.target_group_arn]  # Register with ALB
  health_check_type   = "ELB"  # Use ALB health checks
  health_check_grace_period = 300  # 5 min grace period for new instances

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Instance refresh - for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-instance"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# Scale Out Policy (Add Instances)
# -----------------------------------------------------------------------------
# Triggered when CPU > 50% - adds 1 instance

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-scale-out"
  scaling_adjustment     = 1  # Add 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120  # Wait 2 min before scaling again
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm to trigger scale out
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2       # Check 2 times
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60      # Every 60 seconds
  statistic           = "Average"
  threshold           = 50      # 50% CPU

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# -----------------------------------------------------------------------------
# Scale In Policy (Remove Instances)
# -----------------------------------------------------------------------------
# Triggered when CPU < 30% - removes 1 instance

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-scale-in"
  scaling_adjustment     = -1  # Remove 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm to trigger scale in
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30      # 30% CPU

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]

  tags = {
    Name = "${var.project_name}-low-cpu-alarm"
  }
}
