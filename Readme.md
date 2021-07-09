# NEP assignment

This demo includes a two-tier highly available architecture in AWS with 
public and private subnets. The application layer includes webservers placed in a private subnets
to ensure that they are not directly accessible from the internet. A bastion
host is added to the public subnet in an autoscaling group with capacity of 1 to 
enable SSHing into the webservers. This ensures that when a bastion host goes down, a new 
one will be created in any availability zone. A NAT gateway is added to allow the webservers to access the internet for updates. Only
one NAT gateway for the private subnet has been added for demonstration and cost purposes. Ideally, 
a NAT gateway should be added to the public subnets as well. An internet-facing Application Load Balancer is attached to enable the private 
subnets accommodating the webservers be accessible from the internet, which are 
also in an Autoscaling group to ensure high availability with a desired capacity of 2.
Alternatively, a target policy would have the Autoscaling group expand and contract
the compute capacity on demand.

# Prerequisites
* GitHub Account
* Install Terraform / Sign up for Terraform Cloud
* AWS cli / AWS Account / AWS EC2 KeyPair
* CI tool (Jenkins)

# AWS Resources
* Application Load Balancer targeting Webserver Auto Scaling Group
* 3 Public Subnets
* 3 Private Subnets
* Auto Scaling Group for Bastion Host
* Auto Scaling Group for Web Server

# Continuous Deployment
A `Jenkinsfile` has been included to automate the terraform steps for deployment of the architecture on AWS.
