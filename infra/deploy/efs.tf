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
