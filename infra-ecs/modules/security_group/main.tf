variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "port" {
  description = "Port to allow"
  type        = number
}

variable "cidr_blocks" {
  description = "CIDR blocks to allow"
  type        = list(string)
}

resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id

  tags = {
    Name = var.name
  }
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.default.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "aws_security_group_id" {
  value = aws_security_group.default.id
}