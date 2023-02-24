data "archive_file" "failover_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/"
  output_path = "${path.module}/output_lambda_zip/failover_lambda.zip"
}

resource "aws_lambda_function" "failover_lambda" {
  filename      = data.archive_file.failover_lambda.output_path
  function_name = "${var.name_prefix}-Failover"
  role          = aws_iam_role.failover_lambda.arn
  handler       = "main_handler.lambda_handler"
  description   = "Lambda-Failover"
  tags          = merge(var.project-tags, { Name = "${var.name_prefix}-Failover" }, )

  source_code_hash = data.archive_file.failover_lambda.output_path
  runtime          = "python3.9"
  timeout          = "900"

  environment {
    variables = {
      route_table_id = "tgw-rtb-01c2c602a519651e0"
      attach_vpn     = var.attach_vpn,
      attach_dxc     = var.attach_dxc,
      cidr_block     = var.cidr_block
    }
  }
}

