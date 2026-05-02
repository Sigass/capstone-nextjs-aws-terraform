
###############################################################
# Capstone Project - Infrastructure as Code (IaC) with Terraform
#
# Architecture:
# - VPC & Subnets
# - Security Groups
# - Application Load Balancer (ALB)
# - EC2 Auto Scaling Group for Next.js app
# - Monitoring/Alerting (optionnel)
###############################################################

# VPC and networking
module "vpc" {
  source = "./modules/vpc"
}

# Security groups for ALB and EC2
module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

# Application Load Balancer and Target Group
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  alb_sg         = module.security.alb_sg_id
}

# Compute: EC2 Auto Scaling Group for Next.js app
module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnets
  instance_sg        = module.security.instance_sg_id
  target_group_arn   = module.alb.target_group_arn
  key_name           = var.key_name
  instance_type      = var.instance_type
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
}

# Monitoring & alerting (optionnel)
module "monitoring" {
  source = "./modules/monitoring"

  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  email = "sigahnouarmand@gmail.com"
}