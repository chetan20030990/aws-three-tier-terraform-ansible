# Capstone Project: Multi-Tier Application with Terraform, Ansible & AWS Auto-Scaling

## 📋 Overview

This project deploys a three-tier web application on AWS:

```
┌─────────────────────────────────────────────────────────────┐
│                          VPC                                │
│  ┌────────────────────┐    ┌────────────────────┐          │
│  │   Public Subnet 1  │    │   Public Subnet 2  │          │
│  │                    │    │                    │          │
│  │  ┌──────────────┐  │    │  ┌──────────────┐  │          │
│  │  │    Nginx     │  │    │  │  Flask ASG   │  │          │
│  │  │  (Frontend)  │  │    │  │  (2-6 inst)  │  │          │
│  │  └──────────────┘  │    │  └──────────────┘  │          │
│  └────────────────────┘    └────────────────────┘          │
│            │                        │                       │
│            └───────────┬────────────┘                       │
│                        ▼                                    │
│               ┌──────────────┐                              │
│               │     ALB      │                              │
│               └──────────────┘                              │
│                                                             │
│  ┌────────────────────┐    ┌────────────────────┐          │
│  │  Private Subnet 1  │    │  Private Subnet 2  │          │
│  │  ┌──────────────┐  │    │                    │          │
│  │  │  RDS MySQL   │  │    │                    │          │
│  │  └──────────────┘  │    │                    │          │
│  └────────────────────┘    └────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 🏗️ Architecture Components

| Tier | Technology | Description |
|------|------------|-------------|
| Frontend | Nginx on EC2 | Serves static HTML, reverse proxies to API |
| Application | Flask on EC2 (ASG) | REST API with auto-scaling (2-6 instances) |
| Database | AWS RDS MySQL | Managed database in private subnet |
| Load Balancer | AWS ALB | Distributes traffic to Flask instances |

## 📁 Project Structure

```
capstone-project/
├── terraform/
│   ├── main.tf              # Root module
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── terraform.tfvars     # Variable values (DO NOT COMMIT)
│   └── modules/
│       ├── networking/      # VPC, subnets, IGW, route tables
│       ├── alb/             # Application Load Balancer
│       ├── asg/             # Auto Scaling Group, Launch Template
│       └── rds/             # RDS MySQL instance
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory/
│   │   ├── hosts.yml        # Static inventory
│   │   └── group_vars/
│   │       └── all.yml      # Shared variables
│   ├── playbooks/
│   │   ├── site.yml         # Main playbook
│   │   ├── deploy_app.yml   # Deploy Flask only
│   │   └── init_db.yml      # Initialize database
│   └── roles/
│       ├── app/             # Flask application
│       ├── frontend/        # Nginx configuration
│       └── db_init/         # Database initialization
├── scripts/
│   └── load_test.py         # Load testing script
└── docs/
    └── architecture.md      # Architecture documentation
```

## 🚀 Quick Start

### Prerequisites

- AWS Account with Free Tier
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- Ansible >= 2.9
- Python 3 with `requests` library

### Step 1: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Save the outputs - you'll need `alb_dns_name` and `rds_host`.

### Step 2: Create SSH Key Pair

```bash
# In AWS Console: EC2 → Key Pairs → Create key pair
# Name: capstone-key
# Download and save as ~/.ssh/capstone-key.pem
chmod 400 ~/.ssh/capstone-key.pem
```

### Step 3: Update Ansible Inventory

Edit `ansible/inventory/hosts.yml` with EC2 instance IPs.
Edit `ansible/inventory/group_vars/all.yml` with Terraform outputs.

### Step 4: Run Ansible

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### Step 5: Test the Application

```bash
# Test Flask API directly
curl http://<ALB_DNS>/items

# Open frontend in browser
open http://<NGINX_IP>
```

### Step 6: Load Test (Trigger Auto-Scaling)

```bash
cd scripts
pip3 install requests
python3 load_test.py http://<ALB_DNS>/items -w 200 -n 10000
```

## 📊 Auto-Scaling Configuration

| Parameter | Value |
|-----------|-------|
| Min Instances | 2 |
| Max Instances | 6 |
| Scale Out | CPU > 50% for 2 min |
| Scale In | CPU < 30% for 2 min |
| Cooldown | 120 seconds |

## 🧹 Cleanup

**Important:** Destroy resources when done to avoid charges!

```bash
cd terraform
terraform destroy
```

## 💰 Cost Estimate (Free Tier)

| Resource | Free Tier | Cost if exceeded |
|----------|-----------|------------------|
| EC2 t2.micro | 750 hrs/month | ~$0.0116/hr |
| RDS db.t3.micro | 750 hrs/month | ~$0.017/hr |
| ALB | 750 hrs/month | ~$0.0225/hr |
| Data Transfer | 15 GB/month | ~$0.09/GB |

**Tip:** Run `terraform destroy` immediately after testing to stay within Free Tier.

## 📝 License

This project is for educational purposes (TELE 6420 Capstone).
