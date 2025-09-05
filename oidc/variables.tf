variable "project_name" {
  type        = string
  default     = "pb-test"
  description = "The name of the project."
}

variable "github_org" {
  type        = string
  default     = "JEBDevOps"
  description = "The GitHub organization where the repository is located."
}

variable "github_repo" {
  type        = string
  default     = "pb-devops-test"
  description = "The name of the GitHub repository."
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
  description = "The AWS region to deploy the resources in."
}
