import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from create_events.main import handler


class TestCreateEventHandler(unittest.TestCase):

    @patch('create_events.main.boto3')
    def test_handler_success(self, mock_boto3):
        mock_dynamodb = MagicMock()
        mock_table = MagicMock()
        mock_dynamodb.Table.return_value = mock_table
        mock_boto3.resource.return_value = mock_dynamodb

        event = {
            'body': json.dumps({
                'id': '123',
                'type': 'test_event',
                'payload': {'key': 'value'}
            })
        }
        context = {}

        response = handler(event, context)

        mock_table.put_item.assert_called_once_with(Item={
            'id': '123',
            'type': 'test_event',
            'payload': {'key': 'value'}
        })
        self.assertEqual(response['statusCode'], 201)
        self.assertEqual(json.loads(response['body']), {'id': '123'})

    def test_handler_invalid_json(self):
        event = {'body': 'invalid json'}
        context = {}

        response = handler(event, context)

        self.assertEqual(response['statusCode'], 400)
        self.assertEqual(json.loads(response['body']), {'message': 'Invalid JSON body'})

    def test_handler_missing_fields(self):
        event = {
            'body': json.dumps({'id': '123'})
        }
        context = {}

        response = handler(event, context)

        self.assertEqual(response['statusCode'], 400)
        self.assertEqual(json.loads(response['body']), {'message': 'Missing required fields: id, type, payload'})


if __name__ == '__main__':
    unittest.main()
