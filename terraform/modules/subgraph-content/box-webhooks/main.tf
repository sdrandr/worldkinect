resource "aws_api_gatewayv2_api" "webhook_api" {
  name          = "${var.name_prefix}-box-webhook"
  protocol_type = "HTTP"
}

resource "aws_lambda_function" "webhook_handler" {
  function_name = "${var.name_prefix}-box-webhook"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = var.lambda_role_arn
  filename      = var.lambda_package

  environment {
    variables = {
      QUEUE_URL       = var.queue_url
      BOX_WEBHOOK_KEY = var.box_webhook_secret_arn
    }
  }
}

resource "aws_lambda_permission" "apigw_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gatewayv2_api.webhook_api.execution_arn}/*/*"
}

resource "aws_api_gatewayv2_integration" "lambda_integration" {
  api_id                 = aws_api_gatewayv2_api.webhook_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.webhook_handler.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_api_gatewayv2_route" "webhook_route" {
  api_id    = aws_api_gatewayv2_api.webhook_api.id
  route_key = "POST /"
  target    = "integrations/${aws_api_gatewayv2_integration.lambda_integration.id}"
}

resource "aws_api_gatewayv2_stage" "default" {
  api_id      = aws_api_gatewayv2_api.webhook_api.id
  name        = "$default"
  auto_deploy = true
}

output "webhook_url" {
  value = aws_api_gatewayv2_stage.default.invoke_url
}
