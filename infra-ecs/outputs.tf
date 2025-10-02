output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.alb.zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.alb.arn
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.cluster.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "codecommit_repository_clone_url_http" {
  description = "CodeCommit repository clone URL (HTTP)"
  value       = aws_codecommit_repository.repo.clone_url_http
}

output "codecommit_repository_clone_url_ssh" {
  description = "CodeCommit repository clone URL (SSH)"
  value       = aws_codecommit_repository.repo.clone_url_ssh
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "app_url_prod" {
  description = "Production application URL (Blue environment)"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "app_url_test" {
  description = "Test application URL (Green environment)"
  value       = "http://${aws_lb.alb.dns_name}:8080"
}