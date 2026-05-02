
# Application Load Balancer for Capstone Project
resource "aws_lb" "alb" {
  name               = "capstone-alb-main"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_sg]
  tags = {
    Name = "capstone-alb-main"
    Role = "application-load-balancer"
  }
}

# Target group for Next.js app instances (port 3000)
resource "aws_lb_target_group" "tg" {
  name     = "capstone-tg-nextjs"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = {
    Name = "capstone-tg-nextjs"
    Role = "target-group"
  }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Listener to forward HTTP traffic to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  tags = {
    Name = "capstone-alb-listener"
    Role = "alb-listener"
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}