data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  associate_public_ip_address = true
  key_name                    = null
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.db_server]

  user_data = join("\n", [
    "#!/bin/bash",

    "cat > /etc/prestashop-db.env <<'DBENV'",
    "DB_HOST=${aws_instance.db_server.private_ip}",
    "DB_NAME='${var.db_name}'",
    "DB_USER='${var.db_user}'",
    "DB_PASS='${var.db_password}'",
    "ADMIN_PASS='${var.prestashop_admin_password}'",
    "DBENV",
    "chmod 600 /etc/prestashop-db.env",

    file("${path.module}/../user-data/web-server.sh"),

    "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
    "cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'",
    file("${path.module}/../user-data/cloudwatch-config/web-cloudwatch.json"),
    "CWCONFIG",
    "curl -fsSL https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o /tmp/amazon-cloudwatch-agent.deb",
    "dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y",
    "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
  ])

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "prestashop-web-server"
    Role = "WebServer"
  }
}

resource "aws_instance" "db_server" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  associate_public_ip_address = true
  key_name                    = null
  user_data_replace_on_change = true

  user_data = join("\n", [
    "#!/bin/bash",

    "cat > /etc/prestashop-db.env <<'DBENV'",
    "DB_HOST=localhost",
    "DB_NAME='${var.db_name}'",
    "DB_USER='${var.db_user}'",
    "DB_PASS='${var.db_password}'",
    "ADMIN_PASS='${var.prestashop_admin_password}'",
    "DBENV",
    "chmod 600 /etc/prestashop-db.env",

    file("${path.module}/../user-data/database-server.sh"),

    "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
    "cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'",
    file("${path.module}/../user-data/cloudwatch-config/database-cloudwatch.json"),
    "CWCONFIG",
    "curl -fsSL https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o /tmp/amazon-cloudwatch-agent.deb",
    "dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y",
    "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
  ])

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "prestashop-db-server"
    Role = "DatabaseServer"
  }
}
