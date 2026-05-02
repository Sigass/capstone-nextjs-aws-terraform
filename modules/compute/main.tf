
###############################################################
# Compute module for Capstone Project
# Provisions EC2 instances (via ASG) to run the Next.js app
###############################################################

# Get the latest Amazon Linux 2023 AMI (x86_64)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }
}

# Launch template for EC2 instances
resource "aws_launch_template" "lt" {
  name_prefix   = "capstone-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.instance_sg]

  # Pass the user_data script to configure the instance
  user_data = base64encode(file("${path.module}/../../user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "capstone-nextjs-app-instance"
      Role = "nextjs-app-server"
    }
  }
}

# Auto Scaling Group to manage EC2 instances
resource "aws_autoscaling_group" "asg" {
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.public_subnets

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "capstone-nextjs-asg"
    propagate_at_launch = true
  }
}