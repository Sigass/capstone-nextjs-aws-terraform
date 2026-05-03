# terraform-nextjs-aws

## Project Overview

This project provisions a fully automated, production-ready infrastructure on AWS to host a **Next.js** web application. Everything is defined as code using **Terraform**, making the stack reproducible, version-controlled, and easy to tear down.

The application ([Cameroon-website](https://github.com/wegosend/Cameroon-website)) is automatically cloned, built, and started on each EC2 instance at boot time via a `user_data` script. Traffic is distributed across instances by an Application Load Balancer, and CloudWatch alarms notify the team of any anomalies via email.

---

## Architecture Diagram

```
                         ┌─────────────────────────────────────────┐
                         │              AWS Cloud (us-west-2)     │
                         │                                         │
    Users                │   ┌──────────────────────────────────┐  │
      │                  │   │              VPC                 │  │
      │  HTTP :80        │   │  10.0.0.0/16                     │  │
      ▼                  │   │                                   │  │
 ┌─────────┐             │   │  ┌────────────┐ ┌────────────┐   │  │
 │Internet │─────────────┼──▶│  │  Subnet 1  │ │  Subnet 2  │   │  │
 │ Gateway │             │   │  │ us-west-2a │ │ us-west-2b │   │  │
 └─────────┘             │   │  └─────┬──────┘ └──────┬─────┘   │  │
                         │   │        │                │         │  │
                         │   │   ┌────▼────────────────▼────┐   │  │
                         │   │   │  Application Load Balancer│   │  │
                         │   │   │     (port 80 → 3000)      │   │  │
                         │   │   └────────────┬─────────────┘   │  │
                         │   │                │                  │  │
                         │   │   ┌────────────▼─────────────┐   │  │
                         │   │   │    Auto Scaling Group     │   │  │
                         │   │   │  ┌──────────┐ ┌────────┐  │   │  │
                         │   │   │  │  EC2 #1  │ │ EC2 #2 │  │   │  │
                         │   │   │  │ Next.js  │ │Next.js │  │   │  │
                         │   │   │  │ :3000    │ │ :3000  │  │   │  │
                         │   │   │  └──────────┘ └────────┘  │   │  │
                         │   │   └──────────────────────────┘   │  │
                         │   │                                   │  │
                         │   │   ┌───────────────────────────┐   │  │
                         │   │   │  CloudWatch + SNS Alerts  │   │  │
                         │   │   └───────────────────────────┘   │  │
                         │   └──────────────────────────────────┘  │
                         └─────────────────────────────────────────┘
```

---

## Architecture Components

| Component | Details |
|---|---|
| **VPC** | Custom VPC (`10.0.0.0/16`) with DNS support enabled |
| **Public Subnets** | 2 subnets across `us-west-2a` and `us-west-2b` for high availability |
| **Internet Gateway** | Provides public internet access to the VPC |
| **Route Table** | Routes all outbound traffic (`0.0.0.0/0`) through the IGW |
| **Security Groups** | ALB SG (inbound port 80), EC2 SG (inbound port 3000 from ALB) |
| **Application Load Balancer** | Distributes HTTP traffic across EC2 instances on port 3000 |
| **Target Group** | Health-checks instances at `/` every 30s (expects HTTP 200) |
| **Launch Template** | Amazon Linux 2023 (x86_64), configures instance type, key pair, and user_data |
| **Auto Scaling Group** | Maintains 2–3 EC2 instances; replaces unhealthy ones automatically |
| **CloudWatch Alarms** | Monitors CPU, ALB 5xx errors, and unhealthy target count |
| **SNS Topic** | Sends email alerts when any CloudWatch alarm triggers |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured with valid credentials (`aws configure`)
- An EC2 Key Pair created in the `us-west-2` region
- Sufficient IAM permissions to create VPC, EC2, ALB, CloudWatch, and SNS resources

---

## Quick Start Guide

```bash
# 1. Clone this repository
git clone <your-repo-url>
cd terraform-nextjs-aws

# 2. Initialize Terraform (downloads the AWS provider)
terraform init

# 3. Preview what will be created
terraform plan

# 4. Deploy the infrastructure
terraform apply
```

After apply completes, the ALB DNS name is printed:

```
Outputs:

alb_dns_name = "capstone-alb-main-xxxx.us-west-2.elb.amazonaws.com"
```

Open that URL in your browser to access the app.

> **Note:** EC2 instances take ~3–5 minutes to bootstrap (install dependencies, build, and start the app). The ALB will show healthy targets once the app is running on all instances.

**To destroy all resources:**

```bash
terraform destroy
```

---

## Project Structure

```
terraform-nextjs-aws/
├── main.tf               # Root module — wires all child modules together
├── variables.tf          # Input variable declarations and defaults
├── outputs.tf            # Output values (e.g. ALB DNS name)
├── provider.tf           # AWS provider configuration (region: us-west-2)
├── user_data.sh          # EC2 bootstrap script (runs at instance launch)
└── modules/
    ├── vpc/              # VPC, subnets, Internet Gateway, route table
    ├── security/         # Security groups for ALB and EC2
    ├── alb/              # Application Load Balancer, target group, listener
    ├── compute/          # Launch template and Auto Scaling Group
    └── monitoring/       # CloudWatch alarms and SNS email notifications
```

---

## Configuration Details

### Input Variables (`variables.tf`)

| Variable | Default | Description |
|---|---|---|
| `key_name` | `vockey` | Name of the EC2 Key Pair for SSH access |
| `instance_type` | `t2.micro` | EC2 instance type |
| `min_size` | `2` | Minimum number of instances in the ASG |
| `max_size` | `3` | Maximum number of instances in the ASG |
| `desired_capacity` | `2` | Desired number of running instances |

Override variables at apply time:

```bash
terraform apply -var="instance_type=t3.small" -var="desired_capacity=3"
```

### EC2 Bootstrap (`user_data.sh`)

Each instance automatically runs at first boot:

1. Updates system packages (`yum update`)
2. Installs **Node.js 20**, **git**, and the **CloudWatch agent**
3. Clones the app from GitHub: [Cameroon-website](https://github.com/wegosend/Cameroon-website)
4. Runs `npm install` and `npm run build`
5. Installs **pm2** globally and starts the app on `0.0.0.0:3000`
6. Persists pm2 across reboots (`pm2 startup && pm2 save`)

Bootstrap logs are available at `/var/log/user_data.log` on each instance.

### Networking

| Resource | Value |
|---|---|
| VPC CIDR | `10.0.0.0/16` |
| Subnet 1 | `10.0.0.0/24` — `us-west-2a` |
| Subnet 2 | `10.0.1.0/24` — `us-west-2b` |
| App port | `3000` |
| ALB listener port | `80` |

---

## Monitoring & Observability

### CloudWatch Alarms

Three alarms are configured and all trigger SNS email notifications:

| Alarm | Metric | Condition | Action |
|---|---|---|---|
| `high-cpu` | `AWS/EC2 CPUUtilization` | > 70% for 2 consecutive minutes | SNS alert |
| `alb-5xx-errors` | `AWS/ApplicationELB HTTPCode_ELB_5XX_Count` | > 5 in 1 minute | SNS alert |
| `unhealthy-targets` | `AWS/ApplicationELB UnHealthyHostCount` | > 1 in 1 minute | SNS alert |

### SNS Notifications

An SNS topic (`nextjs-alerts`) is created with an email subscription. After the first `terraform apply`, **confirm the subscription** from the email sent to the configured address — alerts will not be delivered until confirmed.

### Debugging

- **Bootstrap issues:** SSH into an instance and check `/var/log/user_data.log`
- **App status:** Run `pm2 list` and `pm2 logs nextjs-app` on the instance
- **ALB health:** Check the target group health in the AWS Console under EC2 → Target Groups
