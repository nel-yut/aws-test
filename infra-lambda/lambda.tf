locals {
  function_name = "nel-lambda-test"
}

# src/ フォルダを ZIP 化
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# Lambda 実行ロール (最小限: Lambda サービスが AssumeRole できるだけ)
resource "aws_iam_role" "lambda_exec" {
  name = "${local.function_name}-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Lambda 本体
resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.12"
  handler       = "hello.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 便利アウトプット
output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}
output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}
