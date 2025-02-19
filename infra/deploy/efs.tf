##########################
# EFS for Media storage. #
##########################

# EFS is a serverless, scalable, and elastic file system that can be mounted on multiple EC2 instances.
# It's like ecs, you just tell it to create a new file system and it will do it for you.\

# First block is to create the efs file system resource
# Second block is to create a security group for the efs, to allow access
# Third and fourth block is to create a mount target for each availability zone, allow network access in our private subnets
# Fifth block is to create an access point for the efs, provision access to efl file sustem at certain locations

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

# We need to create a mount target for each availability zone where we have a private subnet.
# Component that allows us to mount to the file system via the network using NFS.
# We assign all subnets we want to be accessible, so each task could be running in a different subnet. This is for scaling
resource "aws_efs_mount_target" "media_a" { # 
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "media_b" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}

# Access point is a way to access the EFS file system.
# Access point is a way to split up locations in efs file system
# Give different access to different things
# If we have different apps and we want to split the efs, then i can add multiple access points and split up
resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.media.id
  root_directory {      # Root directory of that access point
    path = "/api/media" # In this case I just created a single access point for the media folder.
    creation_info {     # This is for file system creation and permissions of linux user id. in the docker file of project we can set the user id
      owner_gid   = 101
      owner_uid   = 101
      permissions = "755" # This is a linux permission code
    }
  }
}
