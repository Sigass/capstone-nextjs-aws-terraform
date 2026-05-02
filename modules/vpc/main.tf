###############################################################
# VPC module for Capstone Project
# Provides a VPC, public subnets, internet gateway, and routing
###############################################################

# Main Virtual Private Cloud
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "capstone-vpc-main" }
}

# Internet Gateway for public internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "capstone-igw"
    Role = "internet-gateway"
  }
}

# Two public subnets in different AZs for high availability
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = ["us-west-2a", "us-west-2b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "capstone-public-subnet-${count.index + 1}"
    Role = "public-subnet"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "capstone-public-rt"
    Role = "public-route-table"
  }
}

# Default route to the internet via the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "assoc" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}