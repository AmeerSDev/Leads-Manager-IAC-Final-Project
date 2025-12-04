# Network
# Data source for availability zones
data "aws_availability_zones" "available" {
  provider = aws.North-Virginia
  state = "available"
}

# VPC
resource "aws_vpc" "LEADS_VPC" {
  provider = aws.North-Virginia
  cidr_block           = "10.0.0.0/16"
  tags = {
    Name = "leads-manager-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "LEADS_IGW" {
  provider = aws.North-Virginia
  vpc_id = aws_vpc.LEADS_VPC.id

  tags = {
    Name = "leads-manager-igw"
  }
}

# Public Subnet 1
resource "aws_subnet" "LEADS_Public_Subnet_1" {
  provider = aws.North-Virginia
  vpc_id                  = aws_vpc.LEADS_VPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "leads-manager-public-subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "LEADS_Public_Subnet_2" {
  provider = aws.North-Virginia
  vpc_id                  = aws_vpc.LEADS_VPC.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "leads-manager-public-subnet-2"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "LEADS_RT" {
  provider = aws.North-Virginia
  vpc_id = aws_vpc.LEADS_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.LEADS_IGW.id
  }

  tags = {
    Name = "leads-manager-public-rt"
  }
}

# Public 1 RTA
resource "aws_route_table_association" "LEADS_RTA_Public_1" {
  provider = aws.North-Virginia
  subnet_id      = aws_subnet.LEADS_Public_Subnet_1.id
  route_table_id = aws_route_table.LEADS_RT.id
}

# Public 2 RTA
resource "aws_route_table_association" "LEADS_RTA_Public_2" {
  provider = aws.North-Virginia
  subnet_id      = aws_subnet.LEADS_Public_Subnet_2.id
  route_table_id = aws_route_table.LEADS_RT.id
}
