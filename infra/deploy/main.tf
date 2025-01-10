terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # source of the provider
      version = "5.23.0"        # version of the provider
    }
  }

  backend "s3" {
    bucket               = "devops-recipe-app-tf-state-david-demo" # name of the bucket
    key                  = "tf-state-deploy"                       # name of the subfolder in the bucket
    workspace_key_prefix = "tf-state-deploy-env"                   # allows to specify key for environment
    region               = "us-east-2"                             # region of the bucket
    encrypt              = true                                    # encrypt the state file
    dynamodb_table       = "devops-recipe-app-api-tf-lock"         # name of the dynamodb table
  }
}

provider "aws" {
  region = "us-east-2" # region of the provider

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManageBy    = "Terraform/deploy"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {

}

