# ALB
resource "aws_lb" "LEADS_ALB" {
  provider = aws.North-Virginia
  name               = "leads-manager-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LEADS_ALB_SG.id]
  subnets            = [aws_subnet.LEADS_Public_Subnet_1.id, aws_subnet.LEADS_Public_Subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "leads-manager-alb"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "LEADS_TG" {
  provider = aws.North-Virginia
  name     = "leads-manager-tg"
  port     = 32000  # K8s NodePort that maps to app port 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.LEADS_VPC.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 15
    path                = "/health"
    protocol            = "HTTP"
    port                = 32000
    matcher             = "200"
  }

  tags = {
    Name = "leads-manager-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "LEADS_ALB_LISTENER" {
  provider = aws.North-Virginia
  load_balancer_arn = aws_lb.LEADS_ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.LEADS_TG.arn
  }
}

# Target Group Attachments
# Worker 1
resource "aws_lb_target_group_attachment" "WORKER_1_TGA" {
  provider = aws.North-Virginia
  target_group_arn = aws_lb_target_group.LEADS_TG.arn
  target_id        = aws_instance.WORKER_1.id
  port             = 32000
}

# Worker 2
resource "aws_lb_target_group_attachment" "WORKER_2_TGA" {
  provider = aws.North-Virginia
  target_group_arn = aws_lb_target_group.LEADS_TG.arn
  target_id        = aws_instance.WORKER_2.id
  port             = 32000
}
