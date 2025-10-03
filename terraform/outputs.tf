

output "orders_table_arn" {
  value = aws_dynamodb_table.orders.arn
}

output "orders_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "order_items_table_arn" {
  value = aws_dynamodb_table.order_items.arn
}

output "order_items_table_name" {
  value = aws_dynamodb_table.order_items.name
}