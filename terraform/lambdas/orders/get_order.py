import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
order_items_table = dynamodb.Table(os.environ['ORDER_ITEMS_TABLE'])

def lambda_handler(event, context):
    try:
        print("Event:", event)
        order_id = event['pathParameters']['order_id']
        print("Order ID:", order_id)
        
        # Get order
        order_response = orders_table.get_item(Key={'order_id': order_id})
        print("Order response:", order_response)
        
        if 'Item' not in order_response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Order not found'})
            }
        
        order = order_response['Item']
        print("Order item:", order)
        
        # Get order items
        items_response = order_items_table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('order_id').eq(order_id)
        )
        print("Items response:", items_response)
        
        # Simple response without complex processing
        response_data = {
            'order': order,
            'items': items_response.get('Items', [])
        }
        
        print("Final response data:", response_data)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data, default=str)  # SIMPLE FIX: default=str handles everything
        }
        
    except Exception as e:
        print("Error:", str(e))
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }