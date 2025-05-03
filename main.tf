

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14  # Optional: Set log retention
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_function_name
  handler       = "src/handler.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.lambda_function_name}_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy Attachment for Lambda logs
resource "aws_iam_policy_attachment" "lambda_logs_policy" {
  name       = "${var.lambda_function_name}_logs_policy"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.lambda_function_name}_rest_api"
  description = "API Gateway for Lambda function"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "hello"
}

# API Gateway Method
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# API Gateway Deployment and Stage
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_stage" "prod_stage" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name    = "prod"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

# S3 Bucket for Firehose Backup
resource "aws_s3_bucket" "firehose_backup_bucket" {
  bucket = "firehose-backup-${var.environment}-${var.lambda_function_name}"
}

# IAM Role for Firehose
resource "aws_iam_role" "firehose_delivery_role" {
  name = "firehose_to_apigw_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })
}

# IAM Role Policy for Firehose
resource "aws_iam_role_policy" "firehose_apigw_policy" {
  name   = "firehose_apigw_policy"
  role   = aws_iam_role.firehose_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "execute-api:Invoke",
        Resource = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetBucketLocation"],
        Resource = "${aws_s3_bucket.firehose_backup_bucket.arn}/*"
      }
    ]
  })
}


# Firehose Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "firehose-to-lambda"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com/prod/hello"
    name               = "lambda-api-endpoint"
    buffering_interval = 60
    buffering_size     = 5
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    retry_duration     = 300

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_configuration {
      role_arn           = aws_iam_role.firehose_delivery_role.arn
      bucket_arn         = aws_s3_bucket.firehose_backup_bucket.arn
      buffering_interval = 300
      buffering_size     = 5
      compression_format = "GZIP"
    }
  }

  depends_on = [aws_api_gateway_deployment.api_deployment]
}
