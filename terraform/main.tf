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
    stock_quantity = { "N" : "100" }
  })
}

# Orders Table
resource "aws_dynamodb_table" "orders" {
  name           = "orders"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name               = "user_id-index"
    hash_key           = "user_id"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  global_secondary_index {
    name               = "status-index"
    hash_key           = "status"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  tags = {
    Environment = "production"
    Project     = "ecommerce"
  }
}

# Order Items Table
resource "aws_dynamodb_table" "order_items" {
  name           = "order_items"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"
  range_key      = "product_id"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "product_id"
    type = "S"
  }

  tags = {
    Environment = "production"
    Project     = "ecommerce"
  }
}

resource "aws_dynamodb_table" "shopping_carts" {
  name         = "${var.project_name}-shopping-carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for Lambdas
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-lambda-dynamodb"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.order_items.arn,
          aws_dynamodb_table.shopping_carts.arn,
          "${aws_dynamodb_table.orders.arn}/index/*",
          "${aws_dynamodb_table.products.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Functions
resource "aws_lambda_function" "list_products" {
  filename         = "lambdas/products/list_products.zip"
  function_name    = "${var.project_name}-list-products"
  role             = aws_iam_role.lambda_role.arn
  handler          = "list_products.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("lambdas/products/list_products.zip")

  environment {
    variables = {
      PRODUCTS_TABLE = aws_dynamodb_table.products.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_dynamodb]
}

resource "aws_lambda_function" "get_product" {
  filename         = "lambdas/products/get_product.zip"
  function_name    = "${var.project_name}-get-product"
  role             = aws_iam_role.lambda_role.arn
  handler          = "get_product.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("lambdas/products/get_product.zip")

  environment {
    variables = {
      PRODUCTS_TABLE = aws_dynamodb_table.products.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_dynamodb]
}

resource "aws_lambda_function" "add_to_cart" {
  filename         = "lambdas/carts/add_to_cart.zip"
  function_name    = "${var.project_name}-add-to-cart"
  role             = aws_iam_role.lambda_role.arn
  handler          = "add_to_cart.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("lambdas/carts/add_to_cart.zip")

  environment {
    variables = {
      CARTS_TABLE    = aws_dynamodb_table.shopping_carts.name
      PRODUCTS_TABLE = aws_dynamodb_table.products.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_dynamodb]
}

resource "aws_lambda_function" "create_order_v2" {
  filename         = "lambdas/orders/create_order_v2.zip"
  function_name    = "${var.project_name}-create-order-v2"
  role             = aws_iam_role.lambda_role.arn
  handler          = "create_order_v2.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  source_code_hash = filebase64sha256("lambdas/orders/create_order_v2.zip")

  environment {
    variables = {
      ORDERS_TABLE      = aws_dynamodb_table.orders.name
      ORDER_ITEMS_TABLE = aws_dynamodb_table.order_items.name
      CARTS_TABLE       = aws_dynamodb_table.shopping_carts.name
      PRODUCTS_TABLE    = aws_dynamodb_table.products.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_dynamodb]
}

# Remove duplicate create_order lambda - we only need create_order_v2
# resource "aws_lambda_function" "create_order" {
#   ... duplicate - remove this ...
# }

# API Gateway
resource "aws_api_gateway_rest_api" "orders_api" {
  name        = "${var.project_name}-orders-api"
  description = "ECommerce Orders API"
}

# Products API Resources
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "products"
}

# GET /products - List all products
resource "aws_api_gateway_method" "list_products" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_products" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.list_products.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_products.invoke_arn
}

# GET /products/{product_id} - Get specific product
resource "aws_api_gateway_resource" "product" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{product_id}"
}

resource "aws_api_gateway_method" "get_product" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_product" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.product.id
  http_method = aws_api_gateway_method.get_product.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_product.invoke_arn
}

# POST /cart - Add to cart
resource "aws_api_gateway_resource" "cart" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "cart"
}

resource "aws_api_gateway_method" "add_to_cart" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.cart.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "add_to_cart" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.cart.id
  http_method = aws_api_gateway_method.add_to_cart.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.add_to_cart.invoke_arn
}

# Orders resource
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "orders"
}

# Create Order endpoint (POST /orders)
resource "aws_api_gateway_method" "create_order" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_order" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.create_order.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_order_v2.invoke_arn
}

# Get Order endpoint (GET /orders/{orderId})
resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_resource.orders.id
  path_part   = "{orderId}"
}

resource "aws_api_gateway_method" "get_order" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_order" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.get_order.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_order_v2.invoke_arn
}

# Lambda Permissions for API Gateway - WITH UNIQUE STATEMENT IDs
resource "aws_lambda_permission" "api_gateway_list_products" {
  statement_id  = "AllowAPIGatewayListProducts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_products.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_product" {
  statement_id  = "AllowAPIGatewayGetProduct"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_add_to_cart" {
  statement_id  = "AllowAPIGatewayAddToCart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add_to_cart.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_create_order" {
  statement_id  = "AllowAPIGatewayCreateOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order_v2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_order" {
  statement_id  = "AllowAPIGatewayGetOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order_v2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

# Deploy the API
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.list_products,
    aws_api_gateway_integration.get_product,
    aws_api_gateway_integration.add_to_cart,
    aws_api_gateway_integration.create_order,
    aws_api_gateway_integration.get_order
  ]

  rest_api_id = aws_api_gateway_rest_api.orders_api.id
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# Outputs for easy access
output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.prod.stage_name}/"
}

output "list_products_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.prod.stage_name}/products"
}

output "get_product_url_example" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.prod.stage_name}/products/1"
}

output "add_to_cart_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.prod.stage_name}/cart"
}

output "create_order_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.prod.stage_name}/orders"
}
