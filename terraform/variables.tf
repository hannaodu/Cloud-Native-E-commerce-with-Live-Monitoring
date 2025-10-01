# terraform/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "serverless-ecommerce"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}