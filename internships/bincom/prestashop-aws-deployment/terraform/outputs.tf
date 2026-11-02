output "web_server_public_ip" {
  description = "Public IPv4 address of the PrestaShop web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "Public DNS name of the PrestaShop web server"
  value       = aws_instance.web_server.public_dns
}

output "database_private_ip" {
  description = "Private IPv4 address of the MariaDB server"
  value       = aws_instance.db_server.private_ip
}

output "database_public_ip" {
  description = "Public IPv4 address of the database server"
  value       = aws_instance.db_server.public_ip
}

output "prestashop_url" {
  description = "Initial HTTP address of the PrestaShop application"
  value       = "http://${aws_instance.web_server.public_dns}"
}
