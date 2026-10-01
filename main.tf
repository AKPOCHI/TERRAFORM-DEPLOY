terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ======================================================
# NETWORK
# ======================================================

resource "aws_vpc" "ts_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ts-vpc"
  }
}

resource "aws_internet_gateway" "ts_gw" {
  vpc_id = aws_vpc.ts_vpc.id

  tags = {
    Name = "ts-igw"
  }
}

resource "aws_subnet" "ts_public_subnet" {
  vpc_id                  = aws_vpc.ts_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ts-public-subnet"
  }
}

resource "aws_subnet" "ts_private_subnet" {
  vpc_id            = aws_vpc.ts_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ts-private-subnet"
  }
}

resource "aws_subnet" "ts_database_subnet" {
  vpc_id            = aws_vpc.ts_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ts-database-subnet"
  }
}

# ======================================================
# SECURITY GROUPS
# ======================================================

resource "aws_security_group" "fe_sg" {
  name   = "fe-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fe-sg"
  }
}

resource "aws_security_group" "be_sg" {
  name   = "be-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.fe_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "be-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.be_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# ======================================================
# NAT GATEWAY
# ======================================================

resource "aws_eip" "ts_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "ts-nat-eip"
  }
}

resource "aws_nat_gateway" "ts_ng" {
  allocation_id = aws_eip.ts_nat_eip.id
  subnet_id     = aws_subnet.ts_public_subnet.id

  depends_on = [aws_internet_gateway.ts_gw]

  tags = {
    Name = "ts-nat-gateway"
  }
}

# ======================================================
# ROUTE TABLES
# ======================================================

resource "aws_route_table" "ts_public_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ts_gw.id
  }

  tags = {
    Name = "ts-public-rt"
  }
}

resource "aws_route_table" "ts_private_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ts_ng.id
  }

  tags = {
    Name = "ts-private-rt"
  }
}

resource "aws_route_table" "ts_database_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  tags = {
    Name = "ts-database-rt"
  }
}

resource "aws_route_table_association" "ts_public_association" {
  subnet_id      = aws_subnet.ts_public_subnet.id
  route_table_id = aws_route_table.ts_public_rt.id
}

resource "aws_route_table_association" "ts_private_association" {
  subnet_id      = aws_subnet.ts_private_subnet.id
  route_table_id = aws_route_table.ts_private_rt.id
}

resource "aws_route_table_association" "ts_database_association" {
  subnet_id      = aws_subnet.ts_database_subnet.id
  route_table_id = aws_route_table.ts_database_rt.id
}

# ======================================================
# COMPUTE SERVICE
# ======================================================
