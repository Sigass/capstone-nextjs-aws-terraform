
# Security group for the Application Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name   = "capstone-alb-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "capstone-alb-sg"
    Role = "alb-security-group"
  }

  # Allow HTTP traffic from anywhere to the ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic from the ALB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for EC2 instances running the Next.js app
resource "aws_security_group" "instance_sg" {
  name   = "capstone-app-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "capstone-app-sg"
    Role = "app-security-group"
  }

  # Allow HTTP traffic from the ALB security group to the app instances (port 3000)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH access from anywhere (for debugging; restrict in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic from the app instances
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}