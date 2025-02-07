#################
# Load Balancer #
#################

# Security group created for the Load Balancer   
resource "aws_security_group" "lb" {
  description = "Configure access for the Application Load Balancer" # Description of the security group
  name        = "${local.prefix}-alb-access"                         # Name of the security group, contains the worskpace either staging of production
  vpc_id      = aws_vpc.main.id                                      # VPC ID

  # Rules for security group
  # Allows access from the internet to the Load Balancer on port 80 and 443

  # Traffic thhrough port 80 goes through the Load Balancer with http. Then we foward them to port 443 with https 
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Traffic through port 443 goes through the Load Balancer with https
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # This is the connection from the application load balancer
  # So it can make and receive connections. The application runs in ecs on port 8000
  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# There exists the gateway load balancer, netword load balancer and application load balancer
# Network load balancer: Accepts requests and forwards them at network level without knowing about application info. No context about the HTTP requests that are made
# Gateway load balancer: Security in connecting things across different vpcs
# Application load balancer: Provides context about the HTTP requests that are made. We can terminate https certificates or foward requests from http to https
# This is useful to have context about the requests that are made and foward request from load balancer to app service
resource "aws_lb" "api" {
  name               = "${local.prefix}-lb"
  load_balancer_type = "application"                                    # Type of load balancer
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] # Application load balancer must be in public subnets there it is the internet gateway
  security_groups    = [aws_security_group.lb.id]                       # Security group for the load balancer, this allows ingress access
}
