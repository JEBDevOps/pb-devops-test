"""
Unit tests for the create_event lambda function.
"""
import json
import os
import unittest
from unittest.mock import MagicMock, patch

from create_events.main import handler


class TestCreateEventHandler(unittest.TestCase):
    """
    Test class for the create_event handler.
    """

    @patch('create_events.main.boto3')
    @patch.dict(os.environ, {'TABLE_NAME': 'test_table'})
    def test_handler_success(self, mock_boto3):
        """
        Tests the handler for a successful event creation.
        """
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

        mock_dynamodb.Table.assert_called_once_with('test_table')
        mock_table.put_item.assert_called_once_with(Item={
            'id': '123',
            'type': 'test_event',
            'payload': {'key': 'value'}
        })
        self.assertEqual(response['statusCode'], 201)
        self.assertEqual(json.loads(response['body']), {'id': '123'})

    @patch.dict(os.environ, {'TABLE_NAME': 'test_table'})
    def test_handler_invalid_json(self):
        """
        Tests the handler for an invalid JSON body.
        """
        event = {'body': 'invalid json'}
        context = {}

        response = handler(event, context)

        self.assertEqual(response['statusCode'], 400)
        self.assertEqual(
            json.loads(response['body']),
            {'message': 'Invalid JSON body'}
        )

    @patch.dict(os.environ, {'TABLE_NAME': 'test_table'})
    def test_handler_missing_fields(self):
        """
        Tests the handler for a request with missing fields.
        """
        event = {
            'body': json.dumps({'id': '123'})
        }
        context = {}

        response = handler(event, context)

        self.assertEqual(response['statusCode'], 400)
        self.assertEqual(
            json.loads(response['body']),
            {'message': 'Missing required fields: id, type, payload'}
        )


if __name__ == '__main__':
    unittest.main()
