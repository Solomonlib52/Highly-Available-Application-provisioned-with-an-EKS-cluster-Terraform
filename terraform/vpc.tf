# 1. Main VPC
resource "aws_vpc" "drupal_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "bincom-drupal-vpc" }
}

# 2. Internet Gateway for Public Facing Traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.drupal_vpc.id
  tags   = { Name = "bincom-drupal-igw" }
}

# 3. Public Subnets (For the Application Load Balancer)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "drupal-public-1-us-east-1a" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "drupal-public-2-us-east-1b" }
}

# 4. Private Subnets (For the Drupal Application Servers)
resource "aws_subnet" "private_app_1" {
  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "drupal-private-app-1-us-east-1a" }
}

resource "aws_subnet" "private_app_2" {
  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "drupal-private-app-2-us-east-1b" }
}

# 5. Private Subnets (For the Managed MySQL Database)
resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.drupal_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "drupal-private-db-1-us-east-1a" }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.drupal_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "drupal-private-db-2-us-east-1b" }
}

# 6. Elastic IP and NAT Gateway (Allows private app servers to download PHP/Drupal packages)
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "bincom-drupal-nat-gw" }
}

# 7. Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.drupal_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "drupal-public-rt" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.drupal_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "drupal-private-rt" }
}

# 8. Route Table Associations
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Change these two to point to public_rt.id
resource "aws_route_table_association" "private_app_1_assoc" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_app_2_assoc" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 9. Database Subnet Group
# Disabled for Terraform destroy because it depends on EKS subnet data sources.
# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "bincom-drupal-eks-db-subnet-group"
#   subnet_ids = data.aws_subnets.eks_private.ids

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = { Name = "Bincom Drupal EKS DB Subnet Group" }
# }
