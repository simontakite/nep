# networking/main.tf

########################################################################################################################
# Create random id to suffix vpc id
########################################################################################################################
resource "random_integer" "random" {
  min = 1
  max = 100
}

########################################################################################################################
# Create VPC
########################################################################################################################
resource "aws_vpc" "nep_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "nep_vpc-${random_integer.random.id}"
  }
}

########################################################################################################################
# Create public subnet
########################################################################################################################
resource "aws_subnet" "nep_public_subnet" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.nep_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = ["eu-west-1", "eu-west-2", "eu-north-1"][count.index]

  tags = {
    Name = "nep_public_${count.index + 1}"
  }
}

########################################################################################################################
# Create route table association to public subnet
########################################################################################################################
resource "aws_route_table_association" "nep_public_assoc" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.nep_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.nep_public_rt.id
}

########################################################################################################################
# Create private subnet
########################################################################################################################
resource "aws_subnet" "nep_private_subnet" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.nep_vpc.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = ["eu-west-1", "eu-west-2", "eu-north-1"][count.index]

  tags = {
    Name = "nep_private_${count.index + 1}"
  }
}

########################################################################################################################
# Create route table association to private subnet
########################################################################################################################
resource "aws_route_table_association" "nep_private_assoc" {
  count          = length(var.private_cidrs)
  subnet_id      = aws_subnet.nep_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.nep_private_rt.id
}

########################################################################################################################
# Create internet gateway
########################################################################################################################
resource "aws_internet_gateway" "nep_internet_gateway" {
  vpc_id = aws_vpc.nep_vpc.id

  tags = {
    Name = "nep_igw"
  }
  lifecycle {
    create_before_destroy = true
  }
}

########################################################################################################################
# Create elastic ip
########################################################################################################################
resource "aws_eip" "nep_eip" {

}

########################################################################################################################
# Create eip natgateway associatiin
########################################################################################################################
resource "aws_nat_gateway" "nep_natgateway" {
  allocation_id = aws_eip.nep_eip.id
  subnet_id     = aws_subnet.nep_public_subnet[1].id
}

########################################################################################################################
# Create public route table
########################################################################################################################
resource "aws_route_table" "nep_public_rt" {
  vpc_id = aws_vpc.nep_vpc.id

  tags = {
    Name = "nep_public"
  }
}

########################################################################################################################
# Create public route
########################################################################################################################
resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.nep_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nep_internet_gateway.id
}

########################################################################################################################
# Create private route
########################################################################################################################
resource "aws_route_table" "nep_private_rt" {
  vpc_id = aws_vpc.nep_vpc.id

  tags = {
    Name = "nep_private"
  }
}

########################################################################################################################
# Create private route cidr
########################################################################################################################
resource "aws_route" "default_private_route" {
  route_table_id         = aws_route_table.nep_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nep_natgateway.id
}

########################################################################################################################
# Create private route table
########################################################################################################################
resource "aws_default_route_table" "nep_private_rt" {
  default_route_table_id = aws_vpc.nep_vpc.default_route_table_id

  tags = {
    Name = "nep_private"
  }
}

########################################################################################################################
# Create bastion (ssh) security group
########################################################################################################################
resource "aws_security_group" "nep_public_sg" {
  name        = "nep_bastion_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.nep_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################################################################################
# Create private security group
########################################################################################################################
resource "aws_security_group" "nep_private_sg" {
  name        = "nep_database_sg"
  description = "Allow SSH inbound traffic from Bastion Host"
  vpc_id      = aws_vpc.nep_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nep_public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nep_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################################################################################
# Create web security group
########################################################################################################################
resource "aws_security_group" "nep_web_sg" {
  name        = "nep_web_sg"
  description = "Allow all inbound HTTP traffic"
  vpc_id      = aws_vpc.nep_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}