import json
import boto3
import os
import uuid

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def handler(event, context):
    data = json.loads(event['body'])
    item_id = str(uuid.uuid4())
    item = {
        'id': item_id,
        'data': data
    }
    table.put_item(Item=item)
    return {
        'statusCode': 201,
        'body': json.dumps({'id': item_id})
    }
