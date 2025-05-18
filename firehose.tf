# Firehose, S3, and related resources

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = var.firehose_stream_name
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
