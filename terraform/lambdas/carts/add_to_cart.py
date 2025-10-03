import json
import boto3
import os
from decimal import Decimal 

dynamodb = boto3.resource('dynamodb')
carts_table = dynamodb.Table(os.environ['CARTS_TABLE'])
products_table = dynamodb.Table(os.environ['PRODUCTS_TABLE'])

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        user_id = body.get('user_id')
        product_id = body.get('product_id')
        quantity = body.get('quantity', 1)
        
        # Verify product exists
        product_response = products_table.get_item(Key={'productId': product_id})
        if 'Item' not in product_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Product not found'})
            }
        
        product = product_response['Item']
        
        # Convert price to Decimal for DynamoDB
        price = Decimal(str(product['price'])) if 'price' in product else Decimal('0')
        
        # Add to cart
        carts_table.update_item(
            Key={'user_id': user_id},
            UpdateExpression='SET #items = list_append(if_not_exists(#items, :empty_list), :new_item)',
            ExpressionAttributeNames={'#items': 'items'},
            ExpressionAttributeValues={
                ':empty_list': [],
                ':new_item': [{
                    'product_id': product_id, 
                    'quantity': quantity,
                    'name': product.get('name'),
                    'price': price  # ← Use Decimal instead of float
                }]
            }
        )
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'message': 'Item added to cart'})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }