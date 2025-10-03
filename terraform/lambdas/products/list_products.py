import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
products_table = dynamodb.Table(os.environ['PRODUCTS_TABLE'])

def lambda_handler(event, context):
    try:
        # Scan products table (for small datasets - use query for large ones)
        response = products_table.scan()
        
        products = response.get('Items', [])
        
        # Convert any Decimal values to float for JSON serialization
        for product in products:
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
            'body': json.dumps({
                'products': products,
                'count': len(products)
            })
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
