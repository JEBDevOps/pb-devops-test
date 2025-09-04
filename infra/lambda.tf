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
