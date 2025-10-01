# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket for our frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# DynamoDB Table for Products
resource "aws_dynamodb_table" "products" {
  name         = "${var.project_name}-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "productId"

  attribute {
    name = "productId"
    type = "S"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    CostCenter  = "ECommerce"
  }
}

# Add some sample products
resource "aws_dynamodb_table_item" "sample_products" {
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    productId   = { "S" : "1" }
    name        = { "S" : "Serverless Compute Book" }
    price       = { "N" : "29.99" }
    description = { "S" : "Complete guide to serverless architecture" }
    category    = { "S" : "Books" }
  })
}