
import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
products_table = dynamodb.Table(os.environ['PRODUCTS_TABLE'])

def lambda_handler(event, context):
    try:
        product_id = event['pathParameters']['product_id']
        
        response = products_table.get_item(Key={'productId': product_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Product not found'})
            }
        
        product = response['Item']
        
        # Convert Decimal to float
        if 'price' in product:
            product['price'] = float(product['price'])
        if 'stock_quantity' in product:
            product['stock_quantity'] = int(product['stock_quantity'])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(product)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
