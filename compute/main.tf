# compute/main.tf

########################################################################################################################
# Get AMIs
########################################################################################################################
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

########################################################################################################################
# Create bastion instance
########################################################################################################################
resource "aws_launch_template" "nep_bastion" {
  name_prefix            = "nep_bastion"
  image_id               = data.aws_ami.linux.id
  instance_type          = var.bastion_instance_type
  vpc_security_group_ids = [var.public_sg]
  key_name               = var.key_name

  tags = {
    Name = "nep_bastion"
  }
}

########################################################################################################################
# Create bastion autoscaling group
########################################################################################################################
resource "aws_autoscaling_group" "nep_bastion" {
  name                = "nep_bastion"
  vpc_zone_identifier = tolist(var.public_subnet)
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.nep_bastion.id
    version = "$Latest"
  }
}

########################################################################################################################
# Create webapp instance
########################################################################################################################
resource "aws_launch_template" "nep_webapp" {
  name_prefix            = "nep_webapp"
  image_id               = data.aws_ami.linux.id
  instance_type          = var.database_instance_type
  vpc_security_group_ids = [var.private_sg]
  key_name               = var.key_name
  user_data              = filebase64("scripts/install_apache.sh")

  tags = {
    Name = "nep_webapp"
  }
}

########################################################################################################################
# Create webserver autoscaling group
########################################################################################################################
resource "aws_autoscaling_group" "nep_webapp" {
  name                = "nep_webapp"
  vpc_zone_identifier = tolist(var.public_subnet)
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.nep_webapp.id
    version = "$Latest"
  }
}

########################################################################################################################
# Create autoscaling group / webserver attachment
########################################################################################################################
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.nep_webapp.id
  # elb                    = var.elb
  alb_target_group_arn = var.alb_tg
}
