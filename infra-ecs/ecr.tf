############################################################################
## ECR Repository
############################################################################
resource "aws_ecr_repository" "app" {
  name                 = "${var.resource_id_prefix}-app-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.resource_id_prefix}-app-repo"
  }
}

# ECR authorization token for initial push
data "aws_ecr_authorization_token" "token" {}

# Initial image push to ECR (for first deployment)
resource "null_resource" "image_push" {
  provisioner "local-exec" {
    command = <<-EOF
      docker build ../app -t ${aws_ecr_repository.app.repository_url}:latest
      docker login -u AWS -p ${data.aws_ecr_authorization_token.token.password} ${data.aws_ecr_authorization_token.token.proxy_endpoint}
      docker push ${aws_ecr_repository.app.repository_url}:latest
    EOF
  }

  triggers = {
    # Re-run when ECR repository URL changes
    repository_url = aws_ecr_repository.app.repository_url
  }
}