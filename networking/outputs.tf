# networking/outputs.tf

########################################################################################################################
# vpc id
########################################################################################################################
output "vpc_id" {
  value = aws_vpc.nep_vpc.id
}

########################################################################################################################
# public security group
########################################################################################################################
output "public_sg" {
  value = aws_security_group.nep_public_sg.id
}

########################################################################################################################
# private security group
########################################################################################################################
output "private_sg" {
  value = aws_security_group.nep_private_sg.id
}

########################################################################################################################
# web security group
########################################################################################################################
output "web_sg" {
  value = aws_security_group.nep_web_sg.id
}

########################################################################################################################
# private subnet
########################################################################################################################
output "private_subnet" {
  value = aws_subnet.nep_private_subnet[*].id
}

########################################################################################################################
# public subnet
########################################################################################################################
output "public_subnet" {
  value = aws_subnet.nep_public_subnet[*].id
}