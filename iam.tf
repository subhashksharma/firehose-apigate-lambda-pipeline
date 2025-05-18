# IAM Roles
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.lambda_function_name}_lambda_role"
  assume_role_policy = file("${path.module}/policies/lambda_assume_role_policy.json")
}

resource "aws_iam_role" "firehose_delivery_role" {
  name = "firehose_to_apigw_role"
  assume_role_policy = file("${path.module}/policies/firehose_assume_role_policy.json")
}

resource "aws_iam_role_policy" "firehose_policy" {
  name   = "firehose_policy"
  role   = aws_iam_role.firehose_delivery_role.id
  policy = file("${path.module}/policies/firehose_apigw_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
