############################################################################
## VPC
############################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.resource_id_prefix}-vpc"
  }
}

############################################################################
## Internet Gateway
############################################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_id_prefix}-vpc-igw"
  }
}

############################################################################
## Public Route Table
############################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_id_prefix}-rtb-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

############################################################################
## Public Subnet 1a
############################################################################
resource "aws_subnet" "public_1a" {
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resource_id_prefix}-subnet-public-1a"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

############################################################################
## Public Subnet 1c
############################################################################
resource "aws_subnet" "public_1c" {
  availability_zone       = "ap-northeast-1c"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resource_id_prefix}-subnet-public-1c"
  }
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

############################################################################
## NAT Gateway (Single for cost savings)
############################################################################
resource "aws_eip" "nat_gateway_1a" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.resource_id_prefix}-eip-nat-gw-1a"
  }
}

resource "aws_nat_gateway" "nat_gateway_1a" {
  allocation_id = aws_eip.nat_gateway_1a.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "${var.resource_id_prefix}-nat-gw-1a"
  }
}

############################################################################
## Private Route Table 1a
############################################################################
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_id_prefix}-rtb-private-1a"
  }
}

resource "aws_route" "private_1a" {
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1a.id
  destination_cidr_block = "0.0.0.0/0"
}

############################################################################
## Private Subnet 1a
############################################################################
resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_blocks[0]
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.resource_id_prefix}-subnet-private-1a"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

############################################################################
## Private Route Table 1c (Using same NAT for cost savings)
############################################################################
resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_id_prefix}-rtb-private-1c"
  }
}

resource "aws_route" "private_1c" {
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1a.id  # Cost savings: using same NAT
  destination_cidr_block = "0.0.0.0/0"
}

############################################################################
## Private Subnet 1c
############################################################################
resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_blocks[1]
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.resource_id_prefix}-subnet-private-1c"
  }
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}