###########################
# Network Infraestructure #
###########################

resource "aws_vpc" "main" {
  # Subnet available for our network that is created on our vpc. 
  # Divide IP addresses by network and endpoint addresses. There is a cheatsheet for this in udemy course lesson 67
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true # Enable DNS hostnames (user friendly names)
  enable_dns_support   = true # Enable DNS support (resolve domain names)
}

###################################################################################
# Internet Gateway needed for inbound access to the ALB (Application Load Balancer)
###################################################################################
resource "aws_internet_gateway" "main" { # Resource type and name have to be unique together
  vpc_id = aws_vpc.main.id               # Reference to the vpc created above, it needs one vpc_id

  tags = {                        # Tags are used to identify the resource
    Name = "${local.prefix}-main" # prefix was defined in main.tf
  }
}
