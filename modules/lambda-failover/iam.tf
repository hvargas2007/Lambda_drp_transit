data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Policy Source
data "aws_iam_policy_document" "failover_lambda_policy" {
  statement {
    sid    = "TransitAccess"
    effect = "Allow"
    actions = [
      "ec2:AssociateTransitGatewayRouteTable",
      "ec2:CreateTransitGatewayRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteTransitGatewayRoute",
      "ec2:DeleteTransitGatewayRouteTable",
      "ec2:DisableTransitGatewayRouteTablePropagation",
      "ec2:EnableTransitGatewayRouteTablePropagation"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/alias/aws/ssm"]
  }
}

data "aws_iam_policy_document" "failover_lambda_assume" {
  statement {
    sid    = "LambdaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy
resource "aws_iam_policy" "failover_lambda" {
  name        = "${var.name_prefix}-Failover-Lambda-Policy"
  path        = "/"
  description = "Permissions to trigger the Lambda"
  policy      = data.aws_iam_policy_document.failover_lambda_policy.json
  tags        = { Name = "${var.name_prefix}-Failover-Lambda-Policy" }
}

# IAM Role (Lambda execution role)
resource "aws_iam_role" "failover_lambda" {
  name               = "${var.name_prefix}-Failover-Lambda-Role"
  assume_role_policy = data.aws_iam_policy_document.failover_lambda_assume.json
  tags               = { Name = "${var.name_prefix}-Failover-Lambda-Role" }
}

# Attach Role and Policy
resource "aws_iam_role_policy_attachment" "failover_lambda" {
  role       = aws_iam_role.failover_lambda.name
  policy_arn = aws_iam_policy.failover_lambda.arn
}