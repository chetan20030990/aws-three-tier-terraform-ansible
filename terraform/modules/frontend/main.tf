# =============================================================================
# FRONTEND MODULE - main.tf
# =============================================================================
# This module creates:
# - Nginx EC2 instance in public subnet
# - Security group allowing HTTP/HTTPS from anywhere
# - Nginx serves static content and proxies /api to Flask ALB
# =============================================================================

# -----------------------------------------------------------------------------
# Get latest Amazon Linux 2 AMI
# -----------------------------------------------------------------------------
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
# Security Group for Nginx Frontend
# -----------------------------------------------------------------------------
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "Security group for Nginx frontend"
  vpc_id      = var.vpc_id

  # Inbound: HTTP from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: HTTPS from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: SSH for management
  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

# -----------------------------------------------------------------------------
# Nginx Frontend EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install nginx1 -y
    
    # Create simple HTML frontend
    cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Capstone Project</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { background: white; padding: 30px; border-radius: 10px; max-width: 600px; margin: 0 auto; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            h1 { color: #333; }
            button { background: #667eea; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; font-size: 16px; }
            button:hover { background: #5a6fd6; }
            #result { margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Capstone Three-Tier Application</h1>
            <p>This frontend is served by Nginx and connects to Flask API through ALB.</p>
            <button onclick="fetchItems()">Fetch Items from Database</button>
            <div id="result"></div>
        </div>
        <script>
            function fetchItems() {
                document.getElementById('result').innerHTML = 'Loading...';
                fetch('/api/items')
                    .then(response => response.json())
                    .then(data => {
                        document.getElementById('result').innerHTML = '<strong>Items from RDS:</strong><br>' + JSON.stringify(data, null, 2);
                    })
                    .catch(error => {
                        document.getElementById('result').innerHTML = 'Error: ' + error;
                    });
            }
        </script>
    </body>
    </html>
    HTMLEOF
    
    # Configure Nginx to proxy /api to ALB
    cat > /etc/nginx/conf.d/capstone.conf << 'NGINXEOF'
    server {
        listen 80;
        server_name _;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /api/ {
            proxy_pass http://${var.alb_dns_name}/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    NGINXEOF
    
    # Remove default config
    rm -f /etc/nginx/conf.d/default.conf
    
    # Start Nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tags = {
    Name = "${var.project_name}-frontend"
  }
}
