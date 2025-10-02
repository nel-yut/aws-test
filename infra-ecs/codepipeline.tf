############################################################################
## CodePipeline Execution Role
############################################################################
# CodePipeline role policy
data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codedeploy:*",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

# CodePipeline role
module "codepipeline_role" {
  source     = "./modules/iam_role"
  name       = "${var.resource_id_prefix}-codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

############################################################################
## Artifact Store S3 Bucket
############################################################################
resource "aws_s3_bucket" "artifact" {
  bucket = "${var.resource_id_prefix}-artifact-${random_string.artifact_suffix.result}"

  tags = {
    Name = "${var.resource_id_prefix}-artifact-bucket"
  }
}

resource "random_string" "artifact_suffix" {
  length  = 8
  special = false
  upper   = false
}

############################################################################
## CodeCommit Repository (Optional - for demonstration)
############################################################################
resource "aws_codecommit_repository" "repo" {
  repository_name = var.repository_name
  description     = "Repository for ${var.resource_id_prefix} application"

  tags = {
    Name = "${var.resource_id_prefix}-repository"
  }
}

############################################################################
## CodePipeline
############################################################################
resource "aws_codepipeline" "pipeline" {
  name     = "${var.resource_id_prefix}-pipeline"
  role_arn = module.codepipeline_role.iam_role_arn

  artifact_store {
    location = aws_s3_bucket.artifact.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["Source"]

      configuration = {
        RepositoryName   = aws_codecommit_repository.repo.repository_name
        BranchName       = var.branch_name
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["Build"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.ecs_app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.ecs_deployment_group.deployment_group_name
        TaskDefinitionTemplateArtifact = "Build"
        AppSpecTemplateArtifact        = "Build"
      }
    }
  }

  tags = {
    Name = "${var.resource_id_prefix}-pipeline"
  }
}