

resource "aws_iam_role" "lambda_exec" {
  name = "my_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the necessary permissions to the IAM Role for Lambda execution
resource "aws_iam_policy_attachment" "lambda_exec_policy_attach" {
  name       = "lambda-exec-policy-attach"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles       = [aws_iam_role.lambda_exec.name]
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "utils" {
  layer_name         = "utils"
  compatible_runtimes = ["python3.8"]
  filename            = "${var.layers_path}/utils.zip"
  source_code_hash    = filebase64("${var.layers_path}/utils.zip")
}

# Create the Get Energy Production Lambda function
resource "aws_lambda_function" "get_energy_production" {
  function_name      = "getEnergyProduction"
  runtime            = "python3.8"
  handler            = "getEnergyProduction.lambda_handler"
  source_code_hash   = filebase64("${var.lambdas_path}/API/getEnergyProduction.zip")
  filename           = "${var.lambdas_path}/API/getEnergyProduction.zip"
  role               = aws_iam_role.lambda_exec.arn
  memory_size        = 256
  timeout            = 10
  layers             = [aws_lambda_layer_version.utils.arn]
}

# Create the Aggregate Energy Production Lambda function
resource "aws_lambda_function" "aggregate_energy_production" {
  function_name      = "aggregateEnergyProduction"
  runtime            = "python3.8"
  handler            = "aggregateEnergyProduction.lambda_handler"
  source_code_hash   = filebase64("${var.lambdas_path}/API/aggregateEnergyProduction.zip")
  filename           = "${var.lambdas_path}/API/aggregateEnergyProduction.zip"
  role               = aws_iam_role.lambda_exec.arn
  memory_size        = 256
  timeout            = 10
  layers             = [aws_lambda_layer_version.utils.arn]
}

# Package the Get Energy Production Lambda function code
data "archive_file" "get_energy_production_code" {
  type        = "zip"
  output_path = "${var.lambdas_path}/API/getEnergyProduction.zip"
  source_dir  = "${var.lambdas_path}/API/getEnergyProduction/"
}

# Package the Aggregate Energy Production Lambda function code
data "archive_file" "aggregate_energy_production_code" {
  type        = "zip"
  output_path = "${var.lambdas_path}/API/aggregateEnergyProduction.zip"
  source_dir  = "${var.lambdas_path}/API/aggregateEnergyProduction/"
}

# Package the Lambda layer code
data "archive_file" "utils_code" {
  type        = "zip"
  output_path = "${var.layers_path}/utils.zip"
  source_dir  = "${var.layers_path}/utils"
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name        = "energy-production"
  description = "API for Energy Production"
}

resource "aws_api_gateway_resource" "get_energy_production" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "energy-production-data"
}

resource "aws_api_gateway_method" "get_energy_production" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.get_energy_production.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.park_ids"         = true
    "method.request.querystring.start_timestamp" =  true
    "method.request.querystring.end_timestamp"   =  true
  }
}

resource "aws_api_gateway_integration" "get_energy_production_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.get_energy_production.id
  http_method             = aws_api_gateway_method.get_energy_production.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_energy_production.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway_get_energy_production" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_energy_production.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}

resource "aws_api_gateway_resource" "aggregate_energy_production" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "aggregate-energy-production"
}

resource "aws_api_gateway_method" "aggregate_energy_production" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.aggregate_energy_production.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.park_ids"         = true
    "method.request.querystring.start_timestamp" =  true
    "method.request.querystring.end_timestamp"   =  true
    "method.request.querystring.energy_types"   =  true
  }
}

resource "aws_api_gateway_integration" "aggregate_energy_production_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.aggregate_energy_production.id
  http_method             = aws_api_gateway_method.aggregate_energy_production.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.aggregate_energy_production.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway_aggregate_energy_production" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aggregate_energy_production.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}