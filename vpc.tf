#Define the Corporate_core VPC
resource "aws_vpc" "corporate_core" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "Corporate-Core-VPC"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
#Create a public subnet
resource "aws_subnet" "public_tier_1a"{
  vpc_id = aws_vpc.corporate_core.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = false #No public ip for any instance to satisfy AWS-0164

  tags = {
    Name = "Public-Web-Tier-1A"
    Environment = "Production"
    ManagedBy = "Terraform"
  }
}
#Create a private subnet
resource "aws_subnet" "private_tier_1a"{
  vpc_id = aws_vpc.corporate_core.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Web-Tier-1A"
    Environment = "Production"
    ManagedBy = "Terraform"
  }
}
#Create an internet gateway
resource "aws_internet_gateway" "perimeter_igw"{
  vpc_id = aws_vpc.corporate_core.id

  tags = {
    Name = "Perimeter_IGW"
    ManagedBy = "Terraform"
  }
}
#Create a public routing table
resource "aws_route_table" "public_rt"{
  vpc_id = aws_vpc.corporate_core.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.perimeter_igw.id
  }
  tags = {
    Name = "Public_RouteTable"
    ManagedBy = "Terraform"
  }
}
#Associate the routing table to our public subnet
resource "aws_route_table_association" "public_association"{
  subnet_id = aws_subnet.public_tier_1a.id
  route_table_id = aws_route_table.public_rt.id
}