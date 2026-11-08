output "api_url" {
  description = "The public URL to access the Lambda function"
  value       = "${aws_apigatewayv2_stage.default_stage.invoke_url}/hello"
}
