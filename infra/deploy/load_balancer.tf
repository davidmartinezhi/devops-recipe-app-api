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
