output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.training_bucket.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.training_bucket.arn
}

output "bucket_region" {
  description = "AWS region of the bucket"
  value       = var.aws_region
}

output "website_endpoint" {
  description = "Public S3 static website endpoint"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
