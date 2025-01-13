###################################################################
# Create Elastic Container Registry (ECR) for storing Docker images
###################################################################

# We are creating a new resource (once ecr repository)
resource "aws_ecr_repository" "app" {         # repositpry for the app
  name                 = "recipe-app-api-app" # Name of the repository (resource)
  image_tag_mutability = "MUTABLE"            # We can push same tag name with diff versions of the code
  force_delete         = true                 # Delete the repository even if it has images

  image_scanning_configuration {
    # Best practice is to have it on, for this course it will be disabled to avoid getting stuck
    # Update to true for real deployments
    scan_on_push = false
  }
}

# We are creating a new resource (once ecr repository)
resource "aws_ecr_repository" "proxy" {         # repositpry for the proxy
  name                 = "recipe-app-api-proxy" # Name of the repository (resource)
  image_tag_mutability = "MUTABLE"              # We can push same tag name with diff versions of the code
  force_delete         = true                   # Delete the repository even if it has images

  image_scanning_configuration {
    # Best practice is to have it on, for this course it will be disabled to avoid getting stuck
    # Update to true for real deployments
    scan_on_push = false
  }
}
