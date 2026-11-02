#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/prestashop-db-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ ! -f /etc/prestashop-db.env ]]; then
    echo "ERROR: /etc/prestashop-db.env is missing — check the Terraform user_data join()"
    exit 1
fi

source /etc/prestashop-db.env

for v in DB_NAME DB_USER DB_PASS; do
    if [[ -z "${!v:-}" ]]; then
        echo "ERROR: $v is empty in /etc/prestashop-db.env"
        exit 1
    fi
done

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client

systemctl enable mariadb
systemctl start mariadb

TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
             "http://169.254.169.254/latest/meta-data/local-ipv4")

if [[ -z "$PRIVATE_IP" ]]; then
    echo "ERROR: could not retrieve instance private IP"
    exit 1
fi
echo "Database private IP: ${PRIVATE_IP}"

mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

cat > /etc/mysql/mariadb.conf.d/60-prestashop.cnf <<EOF
[mysqld]
bind-address = ${PRIVATE_IP}
port = 3306
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
log_error = /var/log/mysql/error.log
EOF

systemctl restart mariadb
systemctl is-active --quiet mariadb

APP_HOST_PATTERN="10.0.1.%"

echo "Creating database '${DB_NAME}' and user '${DB_USER}'@'${APP_HOST_PATTERN}' ..."

mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'${APP_HOST_PATTERN}'
    IDENTIFIED BY '${DB_PASS}';

ALTER USER '${DB_USER}'@'${APP_HOST_PATTERN}'
    IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.*
    TO '${DB_USER}'@'${APP_HOST_PATTERN}';

FLUSH PRIVILEGES;
SQL

echo "Verifying database and grants ..."
mysql -u "${DB_USER}" -p"${DB_PASS}" -h 127.0.0.1 -e "SHOW DATABASES;"

mysql -u "${DB_USER}" -p"${DB_PASS}" -h 127.0.0.1 \
      -e "SELECT user, host FROM mysql.user WHERE user='${DB_USER}';"

mysql -u "${DB_USER}" -p"${DB_PASS}" -h "${PRIVATE_IP}" \
      -e "SELECT 1 AS reachable_via_private_ip;"

echo "=== Database setup complete ==="
echo "Database: ${DB_NAME}"
echo "User:     ${DB_USER}@${APP_HOST_PATTERN}"
echo "Bound to: ${PRIVATE_IP}:3306"
echo "Log:      /var/log/mysql/error.log"
