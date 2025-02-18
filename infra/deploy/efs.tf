##########################
# EFS for Media storage. #
##########################

# EFS is a serverless, scalable, and elastic file system that can be mounted on multiple EC2 instances.
# It's like ecs, you just tell it to create a new file system and it will do it for you.

# Create the resource which is a wrapper and then we map the resource to the actual EFS file system.
resource "aws_efs_file_system" "media" {
  encrypted = true # Encrypt the data at rest.
  tags = {
    Name = "${local.prefix}-media" # Name in the AWS console.
  }
}

# New security group
resource "aws_security_group" "efs" {
  name   = "${local.prefix}-efs" # Name with the preffix that we are using
  vpc_id = aws_vpc.main.id       # VPC where the security group will be created

  # Allos inbound access on port 2049 from the ECS service security group.
  ingress {
    from_port = 2049  # That is the standard port for NFS that EFS uses.
    to_port   = 2049  # Same as above. 
    protocol  = "tcp" # TCP protocol

    # Allow it from the ECS service security group.
    # That will be the only service that will be able to access the EFS.
    security_groups = [
      aws_security_group.ecs_service.id
    ]
  }
}
