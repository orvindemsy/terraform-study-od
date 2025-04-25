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


# IGW
resource "aws_internet_gateway" "igw-main-abc" {
  vpc_id = aws_vpc.main-abc.id

  tags = {
    Name = "igw-main-abc"
  }
}

# Elastic IP
resource "aws_eip" "natgw_eip" {
  domain   = "vpc"

  tags = {
    Name = "main-abc-vpc-eip"
  }
}

# NAT GW
resource "aws_nat_gateway" "nat-gw-main-abc" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = aws_subnet.abc-public-subnetA.id

  tags = {
    Name = "nat-gw-main-abc"
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

  route {
    cidr_block = "0.0.0.0/0" # public through nat gateway
    gateway_id = aws_nat_gateway.nat-gw-main-abc.id
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


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/my-key.pem"
}

resource "local_file" "public_key" {
  content  = tls_private_key.example.public_key_pem
  filename = "${path.module}/my-key-public.pem"
}

# public key can only be in some supported format https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "aws-ec2-public-key-demo" {
  key_name   = "aws-ec2-public-key-demo"
  public_key = tls_private_key.example.public_key_openssh
}


# EC2
## One in public subnet, named it bastion
resource "aws_instance" "bastion" {
  ami           = "ami-0599b6e53ca798bb2"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.abc-public-subnetA.id

  vpc_security_group_ids = [aws_security_group.sg-public-abc.id]  # Attach the security group

  user_data = <<-EOF
              #!/bin/bash
              echo "${tls_private_key.example.private_key_openssh}" > /home/ec2-user/.ssh/id_rsa
              chmod 400 /home/ec2-user/.ssh/id_rsa
              chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
              EOF
  tags = {
    Name = "bastion-main-abc-publicA"
  }
}

# EC2
## One in private subnet
resource "aws_instance" "private-subnet-instance" {
  ami           = "ami-0599b6e53ca798bb2"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.abc-private-subnetA.id
  key_name      = aws_key_pair.aws-ec2-public-key-demo.key_name

  vpc_security_group_ids = [aws_security_group.sg-private-abc.id]  # Attach the security group

  tags = {
    Name = "private-subnet-abc-privateA"
  }
}


# Security Group
## sg for public instance
resource "aws_security_group" "sg-public-abc" {
  name        = "security group for abc public"
  description = "Security group for the public subnet in main-abc VPC"
  vpc_id      = aws_vpc.main-abc.id

  tags = {
    Name = "sg-abc-public"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4_public" {
  security_group_id = aws_security_group.sg-public-abc.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4_public" {
  security_group_id = aws_security_group.sg-public-abc.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_public" {
  security_group_id = aws_security_group.sg-public-abc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## sg for private instance
resource "aws_security_group" "sg-private-abc" {
  name        = "security group for abc private"
  description = "Security group for the private subnet in main-abc VPC"
  vpc_id      = aws_vpc.main-abc.id

  tags = {
    Name = "sg-abc-private"
  }
}

### refer to public sg for inbound
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4_private" {
  security_group_id = aws_security_group.sg-private-abc.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_bastion_access" {
  security_group_id = aws_security_group.sg-private-abc.id
  referenced_security_group_id = aws_security_group.sg-public-abc.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_private" {
  security_group_id = aws_security_group.sg-private-abc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
