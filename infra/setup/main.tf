# Define providers to use and configure backedn of that provider
# providers are plugins that add integrations with other services and APIs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }

  backend "s3" {
    bucket         = "devops-recipe-app-tf-state-david-demo" # name of bucket
    key            = "tf-state-setup"                        # name of subfolder in bucket
    region         = "us-east-2"                             # region of bucket
    encrypt        = true                                    # encrypt the state file
    dynamodb_table = "devops-recipe-app-api-tf-lock"         # name of dynamodb table
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManageBy    = "Terraform/setup"
    }
  }
}
