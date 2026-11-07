variable "aws_region" {
  description = "AWS region where S3 resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
  default     = "codomax-s3-training-kpere-2026"
}
