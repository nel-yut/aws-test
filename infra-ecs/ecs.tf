############################################################################
## CloudWatch Log Group
############################################################################
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs-task/${var.resource_id_prefix}"
  retention_in_days = 180

  tags = {
    Name = "${var.resource_id_prefix}-ecs-logs"
  }
}

############################################################################
## ECS Task Execution Role
############################################################################
# Get ECS task execution role policy
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "${var.resource_id_prefix}-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_task_execution_role_policy.policy
}

############################################################################
## ECS Task Security Group
############################################################################
resource "aws_security_group" "ecs_task" {
  name   = "${var.resource_id_prefix}-ecs-task-sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_id_prefix}-ecs-task-sg"
  }
}

resource "aws_security_group_rule" "ecs_ingress" {
  security_group_id        = aws_security_group.ecs_task.id
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = module.http_sg.aws_security_group_id
}

resource "aws_security_group_rule" "ecs_ingress_test" {
  security_group_id        = aws_security_group.ecs_task.id
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = module.http_test_sg.aws_security_group_id
}

resource "aws_security_group_rule" "ecs_egress" {
  security_group_id = aws_security_group.ecs_task.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################################
## ECS Cluster
############################################################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_id_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.resource_id_prefix}-ecs-cluster"
  }
}

############################################################################
## Container Definitions Template
############################################################################
locals {
  container_definitions = templatefile("${path.module}/json/container_definitions.json", {
    container_name = var.container_name
    repository_uri = aws_ecr_repository.app.repository_url
    aws_region     = var.aws_region
    log_group      = aws_cloudwatch_log_group.for_ecs.name
    container_port = var.container_port
  })
}

############################################################################
## ECS Task Definition
############################################################################
resource "aws_ecs_task_definition" "task_def" {
  family                   = var.task_family_name
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions    = local.container_definitions

  tags = {
    Name = "${var.resource_id_prefix}-task-definition"
  }
}

############################################################################
## ECS Service
############################################################################
resource "aws_ecs_service" "service" {
  name                              = "${var.resource_id_prefix}-ecs-service"
  cluster                           = aws_ecs_cluster.cluster.arn
  task_definition                   = aws_ecs_task_definition.task_def.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  # Use CodeDeploy for Blue/Green deployment
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_task.id]
    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [
      # Load balancer is dynamically changed
      desired_count,
      # Target group is changed by Blue/Green deployment
      load_balancer,
      # Task definition is changed by CodePipeline
      task_definition
    ]
  }

  tags = {
    Name = "${var.resource_id_prefix}-ecs-service"
  }
}