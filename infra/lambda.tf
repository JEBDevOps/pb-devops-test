data "archive_file" "create_item_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/create_item"
  output_path = "${path.module}/create_item.zip"
}

data "archive_file" "get_item_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/get_item"
  output_path = "${path.module}/get_item.zip"
}

resource "aws_lambda_function" "create_item_lambda" {
  function_name = "${var.project_name}-create-item"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.9"

  filename         = data.archive_file.create_item_zip.output_path
  source_code_hash = data.archive_file.create_item_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pb_test_table.name
    }
  }
}

resource "aws_lambda_function" "get_item_lambda" {
  function_name = "${var.project_name}-get-item"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.9"

  filename         = data.archive_file.get_item_zip.output_path
  source_code_hash = data.archive_file.get_item_zip.output_base64sha256

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

resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

resource "aws_api_gateway_resource" "item" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_items_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.post_items.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_item_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "get_item_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item.id
  http_method = aws_api_gateway_method.get_item.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_item_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.post_items_integration,
    aws_api_gateway_integration.get_item_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  #stage_name  = "prod"
}

resource "aws_lambda_permission" "api_gateway_permission_post" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_get" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
