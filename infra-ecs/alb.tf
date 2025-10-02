############################################################################
## Security Group Module
############################################################################
# HTTP (80) Security Group
module "http_sg" {
  source      = "./modules/security_group"
  name        = "${var.resource_id_prefix}-http-sg"
  vpc_id      = aws_vpc.main.id
  port        = 80
  cidr_blocks = [var.my_ip_cidr_block]
}

# HTTP Test (8080) Security Group
module "http_test_sg" {
  source      = "./modules/security_group"
  name        = "${var.resource_id_prefix}-http-test-sg"
  vpc_id      = aws_vpc.main.id
  port        = 8080
  cidr_blocks = [var.my_ip_cidr_block]
}

############################################################################
## ALB Log Bucket
############################################################################
resource "aws_s3_bucket" "alb_log" {
  bucket = "${var.resource_id_prefix}-alb-log-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Get ALB service account for log writing
data "aws_elb_service_account" "alb_log" {}

# Policy document for ALB logs
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.alb_log.id]
    }
  }
}

# ALB log bucket policy
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

############################################################################
## Application Load Balancer
############################################################################
resource "aws_lb" "alb" {
  name               = "${var.resource_id_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60

  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.aws_security_group_id,
    module.http_test_sg.aws_security_group_id
  ]

  tags = {
    Name = "${var.resource_id_prefix}-alb"
  }
}

############################################################################
## ALB Listeners
############################################################################
# Production listener (port 80)
resource "aws_lb_listener" "http_prod" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = "200"
    }
  }

  tags = {
    Name = "${var.resource_id_prefix}-prod-listener"
  }
}

# Test listener (port 8080)
resource "aws_lb_listener" "http_test" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP-test」です"
      status_code  = "200"
    }
  }

  tags = {
    Name = "${var.resource_id_prefix}-test-listener"
  }
}

############################################################################
## Target Groups
############################################################################
# Blue Target Group
resource "aws_lb_target_group" "blue" {
  name        = "${var.resource_id_prefix}-blue-tg"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  port        = var.container_port
  protocol    = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.alb]

  tags = {
    Name = "${var.resource_id_prefix}-blue-tg"
  }
}

# Green Target Group (for Blue/Green deployment)
resource "aws_lb_target_group" "green" {
  name        = "${var.resource_id_prefix}-green-tg"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  port        = var.container_port
  protocol    = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.alb]

  tags = {
    Name = "${var.resource_id_prefix}-green-tg"
  }
}

############################################################################
## Listener Rules
############################################################################
# Production listener rule (forwards to blue target group)
resource "aws_lb_listener_rule" "prod" {
  listener_arn = aws_lb_listener.http_prod.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [
      # Target group is dynamically changed by Blue/Green deployment
      action["target_group_arn"],
    ]
  }

  tags = {
    Name = "${var.resource_id_prefix}-prod-rule"
  }
}

# Test listener rule (forwards to green target group)
resource "aws_lb_listener_rule" "test" {
  listener_arn = aws_lb_listener.http_test.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [
      # Target group is dynamically changed by Blue/Green deployment
      action["target_group_arn"],
    ]
  }

  tags = {
    Name = "${var.resource_id_prefix}-test-rule"
  }
}