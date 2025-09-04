import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def handler(event, context):
    item_id = event['pathParameters']['id']
    item = table.get_item(Key={'id': item_id}).get('Item')
    if item:
        return {
            'statusCode': 200,
            'body': json.dumps(item)
        }
    return {
        'statusCode': 404,
        'body': json.dumps({'message': 'Item not found'})
    }
