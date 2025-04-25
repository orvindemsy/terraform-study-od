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

