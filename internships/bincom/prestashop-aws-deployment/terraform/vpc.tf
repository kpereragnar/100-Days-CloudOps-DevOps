data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "prestashop_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prestashop-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.prestashop_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "prestashop-public-subnet"
  }
}

resource "aws_internet_gateway" "prestashop_igw" {
  vpc_id = aws_vpc.prestashop_vpc.id

  tags = {
    Name = "prestashop-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prestashop_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prestashop_igw.id
  }

  tags = {
    Name = "prestashop-public-rt"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
