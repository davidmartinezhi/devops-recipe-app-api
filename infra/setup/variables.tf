variable "tf_state_bucket" {
  description = "Name of the S3 bucket to store the Terraform state file"
  type        = string
  default     = "devops-recipe-app-tf-state-david-demo"
}

variable "tf_state_lock_table" {
  description = "Name of the DynamoDB table to lock the Terraform state file"
  type        = string
  default     = "devops-recipe-app-api-tf-lock"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-recipe-app-api"
}

variable "contact" {
  description = "Contact name/email for tagging resources"
  default     = "gerardomartinez.hi@gmail.com"

}
