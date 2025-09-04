import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def handler(event, context):
    try:
        data = json.loads(event['body'])
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid JSON body'})
        }

    required_fields = ['id', 'type', 'payload']
    if not all(field in data for field in required_fields):
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Missing required fields: id, type, payload'})
        }

    table.put_item(Item=data)

    return {
        'statusCode': 201,
        'body': json.dumps({'id': data['id']})
    }
