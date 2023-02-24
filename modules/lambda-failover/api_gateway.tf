# In this demo no quota_settings neither throttle_settings are set up
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan

# Capture the AWS Account ID:
data "aws_caller_identity" "currents" {}

# API Gateway definition:
resource "aws_api_gateway_rest_api" "FailoverVPN_DXC_api" {
  name        = "AwsFailoverVPN-DXC"
  description = "AWS Failover VPC-DXC"
  endpoint_configuration {
    types = ["EDGE"]
  }

  depends_on = [
    aws_lambda_function.failover_lambda
  ]
}

# ---------------------------------------------------
# API Resources definition:
# ---------------------------------------------------

# /FailoverVPN_DXC Resource
resource "aws_api_gateway_resource" "FailoverVPN_DXC" {
  rest_api_id = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  parent_id   = aws_api_gateway_rest_api.FailoverVPN_DXC_api.root_resource_id
  path_part   = "FailoverVPN_DXC"
}

# API Model Schema definition:
resource "aws_api_gateway_model" "json_schema" {
  rest_api_id  = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  name         = "passthrough"
  description  = "a JSON schema"
  content_type = "application/json"

  schema = file("${path.module}/templates/passthrough.template")
}

# ---------------------------------------------------
# GET Method:
# ---------------------------------------------------

# GET Request method:
resource "aws_api_gateway_method" "get" {
  rest_api_id      = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  resource_id      = aws_api_gateway_resource.FailoverVPN_DXC.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

# GET Request integration:
resource "aws_api_gateway_integration" "integration-get" {
  rest_api_id             = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  resource_id             = aws_api_gateway_resource.FailoverVPN_DXC.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST" // Lambda function only accepts POST
  type                    = "AWS"
  uri                     = aws_lambda_function.failover_lambda.invoke_arn

  request_templates = {
    "application/json" = "${file("${path.module}/templates/GET.template")}"
  }
}

# GET Method Response
resource "aws_api_gateway_method_response" "get_response_200" {
  rest_api_id = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  resource_id = aws_api_gateway_resource.FailoverVPN_DXC.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# GET Integration Response
resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  resource_id = aws_api_gateway_resource.FailoverVPN_DXC.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.get_response_200.status_code

  response_templates = {
    "application/json" = "${file("${path.module}/templates/lambda-response.template")}"
  }

  depends_on = [
    aws_api_gateway_integration.integration-get
  ]
}

# ---------------------------------------------------
# Stages, API-Key and Usage Plan
# ---------------------------------------------------

# Stage PROD definition:
resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.FailoverVPN_DXC_api.id
  rest_api_id   = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
  stage_name    = "v1"
}

# API-Key generation: 
resource "aws_api_gateway_api_key" "FailoverVPN_DXC_api_key" {
  name        = "FailoverVPN_DXC_api_key"
  description = "AWS FailoverVpn-DXC API-Key"
  enabled     = true
  tags        = { Name = "${var.name_prefix}-api-key" }
}

# Usage plan definition:
resource "aws_api_gateway_usage_plan" "FailoverVPN_DXC_api_usage_plan" {
  name = "FailoverVPN_DXC_api_usage_plan"
  tags = { Name = "${var.name_prefix}-usage_plan" }

  api_stages {
    api_id = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id
    stage  = aws_api_gateway_stage.v1.stage_name
  }
}

# Declare the API key in the usage plan:
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.FailoverVPN_DXC_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.FailoverVPN_DXC_api_usage_plan.id
}

# ---------------------------------------------------
# Lambda Triggers:
# ---------------------------------------------------

# GET Trigger:
resource "aws_lambda_permission" "lambda_get_permission" {
  statement_id  = "InvokeAwsFailoverVPN-DXC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.currents.account_id}:${aws_api_gateway_rest_api.FailoverVPN_DXC_api.id}/*/${aws_api_gateway_method.get.http_method}/${aws_api_gateway_resource.FailoverVPN_DXC.path_part}"

  depends_on = [
    aws_lambda_function.failover_lambda,
    aws_api_gateway_rest_api.FailoverVPN_DXC_api
  ]
}

# ---------------------------------------------------
# Deploy the API
# ---------------------------------------------------
resource "aws_api_gateway_deployment" "FailoverVPN_DXC_api" {
  rest_api_id = aws_api_gateway_rest_api.FailoverVPN_DXC_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get.id,
      aws_api_gateway_integration.integration-get.id
    ]))
  }

  depends_on = [
    aws_api_gateway_method.get,
    aws_api_gateway_integration.integration-get
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------
# Printing the outputs:
# ---------------------------------------------------
output "complete_invoke_url" {
  value = [
    "${aws_api_gateway_deployment.FailoverVPN_DXC_api.invoke_url}${aws_api_gateway_stage.v1.stage_name}/${aws_api_gateway_resource.FailoverVPN_DXC.path_part}"
  ]
  description = "API Gateway Invoke URL"
}

# Use the "-raw" command to view the API key: "terraform output -raw api_key"
output "api_key" {
  value       = aws_api_gateway_api_key.FailoverVPN_DXC_api_key.value
  sensitive   = true
  description = "API-Key"
}