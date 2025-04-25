provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "main-abc" {
  cidr_block = "10.0.0.0/16" # primary CIDR block

  tags = {
    Name = "main-abc"
    Environment = "sandbox"
    creator = "demsy"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.main-abc.id
  cidr_block = "10.1.0.0/16"  # secondary CIDR block
}

# Subnet
## Public Subnet
resource "aws_subnet" "abc-public-subnetA" {
  vpc_id     = aws_vpc.main-abc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "abc-public-subnetA"
  }
}

resource "aws_subnet" "abc-public-subnetB" {
  vpc_id     = aws_vpc.main-abc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c" # apparently ap-northeast-1b is not available
  map_public_ip_on_launch = "true"

  tags = {
    Name = "abc-public-subnetB"
  }
}

## Private Subnet
resource "aws_subnet" "abc-private-subnetA" {
  vpc_id     = aws_vpc.main-abc.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "abc-private-subnetA"
  }
}

resource "aws_subnet" "abc-private-subnetB" {
  vpc_id     = aws_vpc.main-abc.id
  cidr_block = "10.0.32.0/20"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "abc-private-subnetB"
  }
}


# EC2
resource "aws_instance" "example_server" {
  ami           = "ami-0599b6e53ca798bb2"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.abc-public-subnetA.id

  vpc_security_group_ids = [aws_security_group.sg-abc1.id]  # Attach the security group

  user_data = <<EOF
      #!/bin/bash
      # Use this for your user data (script from top to bottom)
      # install httpd (Linux 2 version)
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
    EOF

  tags = {
    Name = "example-instance-demsy-publicA-abc"
  }
}


# Security Group
resource "aws_security_group" "sg-abc1" {
  name        = "security group for abc1 public"
  description = "Security group for the public subnet in main-abc VPC"
  vpc_id      = aws_vpc.main-abc.id

  tags = {
    Name = "sg-abc-public"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.sg-abc1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sg-abc1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg-abc1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# IGW
resource "aws_internet_gateway" "igw-main-abc" {
  vpc_id = aws_vpc.main-abc.id

  tags = {
    Name = "igw-main-abc"
  }
}

# Route table
resource "aws_route_table" "main-abc-public-subnet-route" {
  vpc_id = aws_vpc.main-abc.id

  route {
    cidr_block = "10.0.0.0/16" # primary
    gateway_id = "local"
  }

  route {
    cidr_block = "10.1.0.0/16" # secondary
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0" # public
    gateway_id = aws_internet_gateway.igw-main-abc.id
  }

  tags = {
    Name = "public-subnet-route-table"
  }
}

# Route table
resource "aws_route_table" "main-abc-private-subnet-route" {
  vpc_id = aws_vpc.main-abc.id

  route {
    cidr_block = "10.0.0.0/16" # primary
    gateway_id = "local"
  }

  route {
    cidr_block = "10.1.0.0/16" # secondary
    gateway_id = "local"
  }

  tags = {
    Name = "private-subnet-route-table"
  }
}

# Public route table explicit association
resource "aws_route_table_association" "associate-public-subnet-A" {
  subnet_id      = aws_subnet.abc-public-subnetA.id
  route_table_id = aws_route_table.main-abc-public-subnet-route.id
}

resource "aws_route_table_association" "associate-public-subnet-B" {
  subnet_id      = aws_subnet.abc-public-subnetB.id
  route_table_id = aws_route_table.main-abc-public-subnet-route.id
}

# Private route table explicit association
resource "aws_route_table_association" "associate-private-subnetA" {
  subnet_id      = aws_subnet.abc-private-subnetA.id
  route_table_id = aws_route_table.main-abc-private-subnet-route.id
}

resource "aws_route_table_association" "associate-private-subnetB" {
  subnet_id      = aws_subnet.abc-private-subnetB.id
  route_table_id = aws_route_table.main-abc-private-subnet-route.id
}

