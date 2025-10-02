variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "resource_id_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "bg-deploy-test"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "my_ip_cidr_block" {
  description = "Your IP CIDR block for security group access"
  type        = string
  default     = "0.0.0.0/0"  # セキュリティ上、実際のIPに変更してください
}

variable "task_family_name" {
  description = "ECS task definition family name"
  type        = string
  default     = "bg-deploy-app"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "branch_name" {
  description = "Git branch name for CodeCommit"
  type        = string
  default     = "main"
}

variable "repository_name" {
  description = "CodeCommit repository name"
  type        = string
  default     = "bg-deploy-test-repo"
}