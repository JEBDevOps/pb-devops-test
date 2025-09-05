import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from get_events.main import handler


class TestGetEventHandler(unittest.TestCase):

    @patch('get_events.main.boto3')
    @patch.dict(os.environ, {'TABLE_NAME': 'test_table'})
    def test_handler_success(self, mock_boto3):
        mock_dynamodb = MagicMock()
        mock_table = MagicMock()
        mock_dynamodb.Table.return_value = mock_table
        mock_boto3.resource.return_value = mock_dynamodb

        mock_table.get_item.return_value = {
            'Item': {
                'id': '123',
                'type': 'test_event',
                'payload': {'key': 'value'}
            }
        }

        event = {
            'pathParameters': {
                'id': '123'
            }
        }
        context = {}

        response = handler(event, context)

        mock_dynamodb.Table.assert_called_once_with('test_table')
        mock_table.get_item.assert_called_once_with(Key={'id': '123'})
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(json.loads(response['body']), {
            'id': '123',
            'type': 'test_event',
            'payload': {'key': 'value'}
        })

    @patch('get_events.main.boto3')
    @patch.dict(os.environ, {'TABLE_NAME': 'test_table'})
    def test_handler_not_found(self, mock_boto3):
        mock_dynamodb = MagicMock()
        mock_table = MagicMock()
        mock_dynamodb.Table.return_value = mock_table
        mock_boto3.resource.return_value = mock_dynamodb

        mock_table.get_item.return_value = {}

        event = {
            'pathParameters': {
                'id': '123'
            }
        }
        context = {}

        response = handler(event, context)

        mock_dynamodb.Table.assert_called_once_with('test_table')
        mock_table.get_item.assert_called_once_with(Key={'id': '123'})
        self.assertEqual(response['statusCode'], 404)
        self.assertEqual(json.loads(response['body']), {'message': 'Item not found'})


if __name__ == '__main__':
    unittest.main()
