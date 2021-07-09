# compute/outputs.tf

output "database_asg" {
  value = aws_autoscaling_group.nep_webapp
}