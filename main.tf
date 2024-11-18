terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

# AWS Provider configuration
provider aws {
    region = "eu-west-1"
}

#VPC(s)
#Subnet(s)
#Internet Gateway(s)
#Route Tables.
#NAT Gateway(s) – Optional.
#Security Group(s) – These can also be part of an EC2 module or a separate module.
#Network Access Control List(s) – Optional.
#Peering – Optional.

resource "aws_vpc" "main"{
    cidr_block       = "10.0.0.0/16"
    instance_tenancy  = "default"
    assign_generated_ipv6_cidr_block = true

    tags = {
    Name = "main_vpc"
    }
}
resource "aws_subnet" "production_subnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = { 
        Name = "production_subnet"
    }
}
resource "aws_subnet" "stagging_subnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/28"
    map_public_ip_on_launch = true
    tags = { 
        Name = "production_subnet"
    }
}
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "IGW"
    }
}

resource "aws_route_table" "rt"{
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/24"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "route_table"
    }

}
resource "aws_route_table_association" "a"{
    subnet_id = aws_subnet.production_subnet.id
    route_table_id = aws_route_table.rt.id
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}