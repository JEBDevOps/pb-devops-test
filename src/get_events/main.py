"""
Lambda function to get an event by id.
"""
import json
import os
import boto3

def handler(event, context):
    """
    Handles the retrieval of an event.
    """
    _ = context
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ.get('TABLE_NAME')
    table = dynamodb.Table(table_name)

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
