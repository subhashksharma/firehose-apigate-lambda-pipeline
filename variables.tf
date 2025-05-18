variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
  default     = "nodejs20.x"
}

variable "api_gateway_name" {
  description = "The name of the API Gateway"
  type        = string
  default     = "firehose_api_gateway_connected_to_lambda"
}

variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}


variable "lambda_function_name" {
  default = "firehose-data-reciever-lambda"
}


variable "environment" {
  default = "dev"
}

variable "lambda_log_retention" {
  description = "Log retention in days for Lambda log group"
  type        = number
  default     = 14
}

variable "lambda_handler" {
  description = "The entrypoint for the Lambda function"
  type        = string
  default     = "src/handler.handler"
}

variable "lambda_zip" {
  description = "The path to the Lambda deployment package zip file"
  type        = string
  default     = "lambda_function.zip"
}

variable "firehose_backup_bucket" {
  description = "The name of the S3 bucket for Firehose backup"
  type        = string
}

variable "firehose_stream_name" {
  description = "The name of the Kinesis Firehose delivery stream"
  type        = string
}