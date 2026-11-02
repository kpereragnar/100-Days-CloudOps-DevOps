variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "db_name" {
  description = "Name of the PrestaShop database"
  type        = string
  default     = "prestashop"
}

variable "db_user" {
  description = "Database application user for PrestaShop"
  type        = string
  default     = "prestashop"
}

variable "db_password" {
  description = "Password for the PrestaShop database user"
  type        = string
  sensitive   = true
}

variable "prestashop_admin_password" {
  description = "Admin password for the PrestaShop back office"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the PrestaShop VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the PrestaShop servers"
  type        = string
  default     = "t3.micro"
}
