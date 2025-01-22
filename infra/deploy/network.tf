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

########################################################################
# Public Subnets for the ALB (Application Load Balancer) public access #
########################################################################
# Public Subnet for the ALB (Application Load Balancer)
# they become accessible by signing them a public ip address

# Creates a subnet for the ALB (Application Load Balancer) A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id                    # Reference to the vpc created above
  cidr_block              = "10.1.1.0/24"                      # Subnet for the ALB (Application Load Balancer), from the vpc cidr_block
  map_public_ip_on_launch = true                               # Enable public ip address for the instances (any resource in this subnet gets mapped a public ip address)
  availability_zone       = "${data.aws_region.current.name}a" # Get the current region and availability zone

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

# Create a route table for the vpc
# This route gives access to the resources in the public subnet
resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id # Reference to the vpc created above

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id      # Reference to the public subnet created above
  route_table_id = aws_route_table.public_a.id # Reference to the route table created above
}

# Add a route to route table to link up internet access to our internet gateway
# 0.0.0.0/0 is essentially a way of saying “every IP address”. In a route table, adding a route with the destination 0.0.0.0/0 means 
# “send all traffic (to any IP address) out through the specified gateway,” which in your case is the Internet Gateway.
resource "aws_route" "public_internet_access_a" {       # This creates a aws route
  route_table_id         = aws_route_table.public_a.id  # It has a route table id
  destination_cidr_block = "0.0.0.0/0"                  # All IP addresses
  gateway_id             = aws_internet_gateway.main.id # Go through the internet gateway
}

# Creates a subnet for the ALB (Application Load Balancer) B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id                    # Reference to the vpc created above
  cidr_block              = "10.1.2.0/24"                      # Subnet for the ALB (Application Load Balancer), from the vpc cidr_block
  map_public_ip_on_launch = true                               # Enable public ip address for the instances (any resource in this subnet gets mapped a public ip address)
  availability_zone       = "${data.aws_region.current.name}b" # Get the current region and availability zone

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

# Create a route table for the vpc
# This route gives access to the resources in the public subnet
resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id # Reference to the vpc created above

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id      # Reference to the public subnet created above
  route_table_id = aws_route_table.public_b.id # Reference to the route table created above
}

# Add a route to route table to link up internet access to our internet gateway
resource "aws_route" "public_internet_access_b" {       # This creates a aws route
  route_table_id         = aws_route_table.public_b.id  # It has a route table id
  destination_cidr_block = "0.0.0.0/0"                  # All IP addresses
  gateway_id             = aws_internet_gateway.main.id # Go through the internet gateway
}

############################################
# Private Subnets for internal access only #
############################################
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id # Assign to vpn created above
  cidr_block        = "10.1.10.0/24"  # Subnet for the private addresses (unique range)
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id # Assign to vpn created above
  cidr_block        = "10.1.11.0/24"  # Subnet for the private addresses (unique range)
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-private-b"
  }
}

########################################################################
# Endpoints to allow ECS to access ECR, Cloudwatch and Systems Manager #
########################################################################

# Allow ecs service to connect to ecr to pull docker images
# Cloudwatch to submits logs to read in the interface
# Systems manager used to connect to ecs to perform administrator tasks


# VPC endpoints allow to give our resources in the private network access to other aws services
# For example: When docker container needs to write logs, those are sent to cloudwatch logs. So we need to give access to cloudwatch logs
# We need to create a vpc endpoint for cloudwatch logs
# The same for ECR


# Creates security group assigned to endpoints that allows us to connect to those endpoints
resource "aws_security_group" "endpoint_access" {
  description = "Access to endpoints"
  name        = "${local.prefix}-endpoint-access"
  vpc_id      = aws_vpc.main.id # Assign to vpn created above

  # inbound access to whatever is the security group assigned to. We will assign it to the endpoints from the cidr block of the vpc
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block] # gives access to it from anywhere in the vpc
    from_port   = 443                       # All endpoints use HTTPS so we need to open port 443
    to_port     = 443
    protocol    = "tcp" # all HTTP trafic goes over TCP
  }
}

# Connection to ECR
# Connection to ECR requires 3 endpoints to make the connection possible, endpoint to ecr, endpoint to dkr and endpoint to s3
# All this is required to get ecr from ecs service
resource "aws_vpc_endpoint" "ecr" {                                             # aws_vpc_endpoint is a resource type to create endpoints
  vpc_id              = aws_vpc.main.id                                         # Assign to vpn created above
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api" # Service name for ECR, documentation page has this info
  vpc_endpoint_type   = "Interface"                                             # Interface endpoint (Gateway and interface), 
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_access.id]

  tags = {
    Name = "${local.prefix}-ecr-endpoint"
  }
}


resource "aws_vpc_endpoint" "dkr" {     # aws_vpc_endpoint is a resource type to create endpoints
  vpc_id              = aws_vpc.main.id # Assign to vpn created above
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface" # Interface endpoint (Gateway and interface), 
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_access.id]

  tags = {
    Name = "${local.prefix}-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" { # aws_vpc_endpoint is a resource type to create endpoints
  vpc_id              = aws_vpc.main.id         # Assign to vpn created above
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface" # Interface endpoint (Gateway and interface), 
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_access.id]

  tags = {
    Name = "${local.prefix}-cloudwatch-endpoint"
  }
}

# Endpoint needed to have access to our running containers from our local machine by the shell
resource "aws_vpc_endpoint" "ssm" {     # aws_vpc_endpoint is a resource type to create endpoints
  vpc_id              = aws_vpc.main.id # Assign to vpn created above
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface" # Interface endpoint (Gateway and interface), 
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_access.id]

  tags = {
    Name = "${local.prefix}-ssmmessages-endpoint"
  }
}

# s3 endpoint to get access to s3 bucket and pull images from there
# This endpoint is gateway type
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id                                        # Assign to vpn created above
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3" # Service name for S3, documentation page has this info
  vpc_endpoint_type = "Gateway"                                              # Gateway endpoint (Gateway and interface),
  route_table_ids = [
    aws_vpc.main.default_route_table_id # Specify the route table id for our vpc
  ]

  tags = {
    Name = "${local.prefix}-s3-endpoint"
  }
}
