#!/bin/bash

echo "Adding sample products using AWS CLI..."

# Product 1
aws dynamodb put-item \
    --region eu-west-2 \
    --table-name Products \
    --item '{
        "productId": {"S": "prod-001"},
        "name": {"S": "MacBook Pro"},
        "category": {"S": "electronics"},
        "price": {"N": "1999.99"},
        "brand": {"S": "Apple"},
        "stock": {"N": "15"},
        "description": {"S": "16-inch MacBook Pro with M2 Pro chip"}
    }'

# Product 2
aws dynamodb put-item \
    --region eu-west-2 \
    --table-name Products \
    --item '{
        "productId": {"S": "prod-002"},
        "name": {"S": "iPhone 15"},
        "category": {"S": "electronics"},
        "price": {"N": "899.99"},
        "brand": {"S": "Apple"},
        "stock": {"N": "30"},
        "description": {"S": "Latest iPhone with A16 Bionic chip"}
    }'

# Product 3
aws dynamodb put-item \
    --region eu-west-2 \
    --table-name Products \
    --item '{
        "productId": {"S": "prod-003"},
        "name": {"S": "Wireless Headphones"},
        "category": {"S": "electronics"},
        "price": {"N": "249.99"},
        "brand": {"S": "Sony"},
        "stock": {"N": "50"},
        "description": {"S": "Noise cancelling wireless headphones"}
    }'

# Product 4
aws dynamodb put-item \
    --region eu-west-2 \
    --table-name Products \
    --item '{
        "productId": {"S": "prod-004"},
        "name": {"S": "Cotton T-Shirt"},
        "category": {"S": "clothing"},
        "price": {"N": "24.99"},
        "brand": {"S": "Nike"},
        "stock": {"N": "100"},
        "description": {"S": "Comfortable cotton t-shirt"}
    }'

# Product 5
aws dynamodb put-item \
    --region eu-west-2 \
    --table-name Products \
    --item '{
        "productId": {"S": "prod-005"},
        "name": {"S": "Running Shoes"},
        "category": {"S": "clothing"},
        "price": {"N": "129.99"},
        "brand": {"S": "Adidas"},
        "stock": {"N": "25"},
        "description": {"S": "Lightweight running shoes"}
    }'

echo "✅ Sample products added successfully!"
