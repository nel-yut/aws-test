############################################################################
## CodeDeploy Execution Role
############################################################################
# CodeDeploy AWS managed policy
data "aws_iam_policy" "codedeploy_role_policy" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

module "codedeploy_role" {
  source     = "./modules/iam_role"
  name       = "${var.resource_id_prefix}-codedeploy"
  identifier = "codedeploy.amazonaws.com"
  policy     = data.aws_iam_policy.codedeploy_role_policy.policy
}

############################################################################
## CodeDeploy Application
############################################################################
resource "aws_codedeploy_app" "ecs_app" {
  compute_platform = "ECS"
  name             = "${var.resource_id_prefix}-codedeploy-app"

  tags = {
    Name = "${var.resource_id_prefix}-codedeploy-app"
  }
}

# CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
  deployment_group_name  = "${var.resource_id_prefix}-deployment-group"
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = module.codedeploy_role.iam_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 180
    }

    terminate_blue_instances_on_deployment_success {
      action                   = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http_prod.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.http_test.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  tags = {
    Name = "${var.resource_id_prefix}-deployment-group"
  }
}