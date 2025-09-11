data "archive_file" "create_event_ts_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src_ts/dist/create_events_ts"
  output_path = "${path.module}/create_event_ts.zip"
}

data "archive_file" "get_event_ts_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src_ts/dist/get_events_ts"
  output_path = "${path.module}/get_event_ts.zip"
}

resource "aws_lambda_function" "create_event_ts_lambda" {
  function_name = "${var.project_name}-create-event-ts"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.create_event_ts_zip.output_path
  source_code_hash = data.archive_file.create_event_ts_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pb_test_table.name
    }
  }
}

resource "aws_lambda_function" "get_event_ts_lambda" {
  function_name = "${var.project_name}-get-event-ts"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.get_event_ts_zip.output_path
  source_code_hash = data.archive_file.get_event_ts_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pb_test_table.name
    }
  }
}

resource "aws_api_gateway_resource" "ts_events" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ts"
}

resource "aws_api_gateway_resource" "ts_events_sub" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.ts_events.id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "ts_event" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.ts_events_sub.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "post_ts_events" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ts_events_sub.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_ts_event" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ts_event.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_ts_events_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ts_events_sub.id
  http_method = aws_api_gateway_method.post_ts_events.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_event_ts_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "get_ts_event_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ts_event.id
  http_method = aws_api_gateway_method.get_ts_event.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_event_ts_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_permission_post_ts" {
  statement_id  = "AllowAPIGatewayInvokeTS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event_ts_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_get_ts" {
  statement_id  = "AllowAPIGatewayInvokeTSGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_event_ts_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
