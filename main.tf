terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


#NETWORKING  SERVICES
resource "aws_vpc" "ts_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "ts_public_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "ts public subnet"
  }
}


resource "aws_subnet" "ts_private_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "ts private subnet"
  }
}


resource "aws_subnet" "ts_database_subnet" {
  vpc_id     = aws_vpc.ts_vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "ts database subnet"
  }
}



resource "aws_default_security_group" "fe_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_default_security_group" "be_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 443
    to_port   = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_default_security_group" "db_sg" {
  vpc_id = aws_vpc.ts_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 3306
    to_port   = 3306
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}






resource "aws_internet_gateway" "ts_gw" {
  vpc_id = aws_vpc.ts_vpc.id

  tags = {
    Name = "ts igw"
  }
}


resource "aws_route_table" "ts_public_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.ts_gw.id
  }



  tags = {
    Name = "ts public rt"
  }
}


resource "aws_route_table" "ts_private_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "10.1.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "private rt"
  }
}

resource "aws_route_table" "ts_database_rt" {
  vpc_id = aws_vpc.ts_vpc.id

  route {
    cidr_block = "10.1.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "database rt"
  }
}



resource "aws_route_table_association" "ts_public_association" {
  subnet_id      = aws_subnet.ts_public_rt.id
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

resource "aws_nat_gateway" "ts_ng" {

  subnet_id = aws_subnet.ts_public_subnet.id

  tags = {
    Name = "gw NAT"
  }


  depends_on = [aws_internet_gateway.ts_gw]
}




#COMPUTE SERVICE