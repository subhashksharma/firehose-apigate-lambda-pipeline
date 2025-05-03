

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