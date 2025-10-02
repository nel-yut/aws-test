############################################################################
## CodeBuild Execution Role
############################################################################
# CodeBuild role policy document
data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
  }
}

# CodeBuild role
module "codebuild_role" {
  source     = "./modules/iam_role"
  name       = "${var.resource_id_prefix}-codebuild"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

############################################################################
## CodeBuild Project
############################################################################
resource "aws_codebuild_project" "build" {
  name         = "${var.resource_id_prefix}-build-project"
  service_role = module.codebuild_role.iam_role_arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    privileged_mode = true

    environment_variable {
      name  = "REPOSITORY_URL"
      value = aws_ecr_repository.app.repository_url
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TASK_FAMILY"
      value = var.task_family_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "EXECUTION_ROLE_ARN"
      value = module.ecs_task_execution_role.iam_role_arn
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
      type  = "PLAINTEXT"
    }
  }

  cache {
    type = "LOCAL"
    modes = [
      "LOCAL_DOCKER_LAYER_CACHE",
    ]
  }

  tags = {
    Name = "${var.resource_id_prefix}-build-project"
  }
}