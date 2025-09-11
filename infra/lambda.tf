data "archive_file" "create_event_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/create_events"
  output_path = "${path.module}/create_event.zip"
}

data "archive_file" "get_event_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/get_events"
  output_path = "${path.module}/get_event.zip"
}

resource "aws_lambda_function" "create_event_lambda" {
  function_name = "${var.project_name}-create-event"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.9"

  filename         = data.archive_file.create_event_zip.output_path
  source_code_hash = data.archive_file.create_event_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pb_test_table.name
    }
  }
}

resource "aws_lambda_function" "get_event_lambda" {
  function_name = "${var.project_name}-get-event"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.9"

  filename         = data.archive_file.get_event_zip.output_path
  source_code_hash = data.archive_file.get_event_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pb_test_table.name
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api"
  description = "API for the ${var.project_name} project"
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "event" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.events.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "post_events" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_event" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.event.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_events_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_event_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "get_event_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.event.id
  http_method = aws_api_gateway_method.get_event.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_event_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.post_events_integration,
    aws_api_gateway_integration.get_event_integration,
    aws_api_gateway_integration.post_ts_events_integration,
    aws_api_gateway_integration.get_ts_event_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "api_gateway_permission_post" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_get" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_event_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

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
