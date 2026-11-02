resource "aws_security_group" "web_sg" {
  name        = "prestashop-web-sg"
  description = "Security group for PrestaShop web server"
  vpc_id      = aws_vpc.prestashop_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prestashop-web-sg"
  }
}


resource "aws_security_group" "db_sg" {
  name        = "prestashop-db-sg"
  description = "Security group for MariaDB database server"
  vpc_id      = aws_vpc.prestashop_vpc.id

  ingress {
    description     = "Allow MariaDB from web server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prestashop-db-sg"
  }
}
