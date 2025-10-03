import json
import boto3
import os
import decimal
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
order_items_table = dynamodb.Table(os.environ['ORDER_ITEMS_TABLE'])

def lambda_handler(event, context):
    try:
        order_id = event['pathParameters']['order_id']
        
        # Get order
        order_response = orders_table.get_item(Key={'order_id': order_id})
        
        if 'Item' not in order_response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Order not found'})
            }
        
        order = order_response['Item']
        
        # Get order items
        items_response = order_items_table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('order_id').eq(order_id)
        )
        
        # Convert Decimal to float for JSON serialization
        order_items = []
        for item in items_response['Items']:
            order_items.append({
                'product_id': item['product_id'],
                'name': item['name'],
                'price': float(item['price']),  # Convert Decimal to float
                'quantity': item['quantity'],
                'item_total': float(item['item_total'])  # Convert Decimal to float
            })
        
        # Convert order Decimal values to float
        order_data = {
            'order_id': order['order_id'],
            'user_id': order['user_id'],
            'status': order['status'],
            'total_amount': float(order['total_amount']),  # Convert Decimal to float
            'shipping_address': order.get('shipping_address', ''),
            'payment_method': order.get('payment_method', ''),
            'created_at': order['created_at'],
            'updated_at': order['updated_at'],
            'items': order_items
        }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(order_data, default=lambda x: float(x) if isinstance(x, decimal.Decimal) else str(x))
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)}, default=lambda x: float(x) if isinstance(x, decimal.Decimal) else str(x))
        }