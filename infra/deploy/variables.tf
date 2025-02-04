# Prefix added to the name of every resource in aws, raa + environment + resource name
variable "prefix" {
  description = "Prefix for the resources in AWS"
  default     = "raa"
}

# Name of the project, this is an identifier for the project
variable "project" {
  description = "Project name for tagging resources"
  default     = "recipe-app-api"
}

# Tag on resources to identify the contact person for a resource
variable "contact" {
  description = "Contact name/email for tagging resources"
  default     = "gerardomartinez.hi@gmail.com"
}

variable "db_username" {
  description = "Username for the recipe app api database"
  default     = "recipeapp"
}

variable "db_password" {
  description = "Password for the Terraform database"
  type        = string
}

variable "ecr_proxy_image" {
  description = "Path to the ECR repo with the proxy image"
}

variable "ecr_app_image" {
  description = "Path to the ECR repo with the API image"
}

variable "django_secret_key" {
  description = "Secret key for Django"
}
