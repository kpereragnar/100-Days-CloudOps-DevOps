#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/prestashop-web-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ ! -f /etc/prestashop-db.env ]]; then
    echo "ERROR: /etc/prestashop-db.env is missing — check the Terraform user_data join()"
    exit 1
fi

source /etc/prestashop-db.env

for v in DB_HOST DB_NAME DB_USER DB_PASS ADMIN_PASS; do
    if [[ -z "${!v:-}" ]]; then
        echo "ERROR: $v is empty in /etc/prestashop-db.env"
        exit 1
    fi
done


apt-get update -y

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    libapache2-mod-php \
    php \
    php-cli \
    php-common \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-mysql \
    php-soap \
    php-xml \
    php-zip \
    php-bcmath \
    php-opcache \
    unzip \
    curl \
    wget \
    mariadb-client

a2enmod rewrite headers expires deflate

PHP_INI=$(php --ini | awk -F': ' '/Loaded Configuration File/ {print $2}')
if [[ -n "$PHP_INI" && -f "$PHP_INI" ]]; then
    sed -i 's/^memory_limit = .*/memory_limit = 512M/'          "$PHP_INI"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 64M/' "$PHP_INI"
    sed -i 's/^post_max_size = .*/post_max_size = 64M/'         "$PHP_INI"
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
fi

cat > /etc/apache2/conf-available/prestashop.conf <<'EOF'
ServerName localhost
DirectoryIndex index.php index.html

<Directory /var/www/html>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

ServerTokens Prod
ServerSignature Off
EOF

a2enconf prestashop

echo "Waiting for MariaDB at ${DB_HOST}:3306 ..."
for i in $(seq 1 60); do
    if mysqladmin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; then
        echo "Database is reachable."
        break
    fi
    if [[ "$i" -eq 60 ]]; then
        echo "ERROR: database at ${DB_HOST} never became reachable after 10 minutes"
        exit 1
    fi
    sleep 10
done

PS_VERSION="8.2.1"
PS_ZIP="prestashop_${PS_VERSION}.zip"
PS_URL="https://github.com/PrestaShop/PrestaShop/releases/download/${PS_VERSION}/${PS_ZIP}"

cd /tmp
rm -f "$PS_ZIP" prestashop.zip
echo "Downloading PrestaShop ${PS_VERSION} ..."
wget -q "$PS_URL" -O "$PS_ZIP"

unzip -q -o "$PS_ZIP"           # produces prestashop.zip
unzip -q -o prestashop.zip -d /var/www/html
rm -f "$PS_ZIP" prestashop.zip

if [[ ! -f /var/www/html/index.php && -d /var/www/html/prestashop ]]; then
    echo "Flattening nested prestashop/ directory ..."
    shopt -s dotglob
    mv /var/www/html/prestashop/* /var/www/html/
    rmdir /var/www/html/prestashop
    shopt -u dotglob
fi

if [[ ! -f /var/www/html/index.php ]]; then
    echo "ERROR: index.php not found at /var/www/html after unzip — aborting"
    ls -la /var/www/html
    exit 1
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod -R 775 /var/www/html/var
chmod 644 /var/www/html/index.php

TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
            "http://169.254.169.254/latest/meta-data/public-ipv4")

echo "Running PrestaShop CLI installer (domain=${PUBLIC_IP}) ..."
php /var/www/html/install-dev/index_cli.php \
    --domain="$PUBLIC_IP" \
    --db_server="$DB_HOST" \
    --db_name="$DB_NAME" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASS" \
    --name="PrestaShop" \
    --email="admin@example.com" \
    --password="$ADMIN_PASS" \
    --language=en \
    --country=NG \
    --rewrite=1 \
    --ssl=0

rm -rf /var/www/html/install /var/www/html/install-dev

cat > /var/www/html/portfolio.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Cloud, DevOps, Infrastructure and Cybersecurity portfolio.">
    <title>Samuel Asukwo Daniel | Cloud &amp; Cybersecurity</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, Helvetica, sans-serif; background: #0b1220;
               color: #e5e7eb; line-height: 1.7; }
        .container { width: min(100% - 40px, 1050px); margin: auto; }
        header { padding: 28px 0; border-bottom: 1px solid #253247; }
        nav { display: flex; justify-content: space-between; align-items: center; gap: 15px; }
        .logo { font-size: 1.25rem; font-weight: bold; color: #ffffff; }
        .status { color: #86efac; font-size: 0.85rem; }
        .hero { padding: 100px 0 75px; }
        .eyebrow { color: #60a5fa; text-transform: uppercase; letter-spacing: 2px;
                   font-size: 0.8rem; font-weight: bold; }
        h1 { color: #ffffff; font-size: clamp(2.4rem, 6vw, 4.5rem);
             line-height: 1.15; margin: 20px 0; }
        .hero p { max-width: 680px; color: #aab8cc; font-size: 1.1rem; }
        .tags { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 30px; }
        .tag { border: 1px solid #344761; background: #152238; color: #bfdbfe;
               padding: 7px 14px; border-radius: 20px; font-size: 0.85rem; }
        section { padding: 35px 0; }
        h2 { color: #ffffff; margin-bottom: 16px; font-size: 1.5rem; }
        .card { background: #111d30; border: 1px solid #26364e; border-radius: 12px;
                padding: 25px; margin-top: 18px; }
        .card p, li { color: #aab8cc; }
        ul { padding-left: 22px; }
        li { margin: 8px 0; }
        footer { border-top: 1px solid #253247; margin-top: 50px; padding: 25px 0;
                 color: #8291a8; font-size: 0.85rem; }
        @media (max-width: 600px) { .hero { padding-top: 65px; } }
    </style>
</head>
<body>
<header>
    <div class="container">
        <nav>
            <div class="logo">SAMUEL ASUKWO DANIEL</div>
            <div class="status">&#9679; Cloud &amp; Security</div>
        </nav>
    </div>
</header>

<main class="container">
    <div class="hero">
        <div class="eyebrow">Technology &bull; Infrastructure &bull; Security</div>
        <h1>Building secure systems.<br>Automating infrastructure.</h1>
        <p>
            I am Samuel Asukwo Daniel, a cybersecurity professional
            developing practical expertise in cloud computing,
            DevOps engineering, infrastructure administration
            and security testing.
        </p>
        <div class="tags">
            <span class="tag">AWS &amp; Cloud</span>
            <span class="tag">DevOps</span>
            <span class="tag">Cybersecurity</span>
            <span class="tag">Linux</span>
            <span class="tag">Infrastructure as Code</span>
        </div>
    </div>

    <section>
        <h2>About Me</h2>
        <div class="card">
            <p>
                My interests sit at the intersection of cybersecurity and
                infrastructure engineering. I enjoy understanding how systems
                work, identifying weaknesses, automating repetitive tasks and
                building reliable environments.
            </p>
        </div>
    </section>

    <section>
        <h2>Technical Focus</h2>
        <div class="card">
            <ul>
                <li>AWS cloud infrastructure and administration</li>
                <li>Terraform and Infrastructure as Code</li>
                <li>Docker and containerization</li>
                <li>Linux system administration</li>
                <li>Ansible and configuration management</li>
                <li>Cybersecurity and penetration testing</li>
                <li>CI/CD and deployment automation</li>
            </ul>
        </div>
    </section>

    <section>
        <h2>Current Project</h2>
        <div class="card">
            <h3>PrestaShop on AWS</h3>
            <p>
                A two-tier cloud deployment featuring an Apache/PHP web server,
                a separate MariaDB database server, Terraform-managed
                infrastructure, AWS Systems Manager and CloudWatch monitoring.
            </p>
            <p style="margin-top:12px">
                <a href="/" style="color:#60a5fa">View the storefront &rarr;</a>
            </p>
        </div>
    </section>
</main>

<footer>
    <div class="container">
        Demonstration website hosted on AWS EC2.<br>
        &copy; 2026 Samuel Asukwo Daniel.
    </div>
</footer>
</body>
</html>
HTML

chown www-data:www-data /var/www/html/portfolio.html
chmod 644 /var/www/html/portfolio.html

systemctl enable apache2
systemctl restart apache2
apache2ctl configtest
systemctl is-active --quiet apache2

TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
            "http://169.254.169.254/latest/meta-data/public-ipv4")

STORE_CODE=$(curl -sS -o /dev/null -w "%{http_code}" "http://${PUBLIC_IP}/" || echo "000")
PORT_CODE=$(curl -sS -o /dev/null -w "%{http_code}" "http://${PUBLIC_IP}/portfolio.html" || echo "000")

echo "=== Setup complete ==="
echo "Storefront  http://${PUBLIC_IP}/            -> HTTP ${STORE_CODE}"
echo "Portfolio   http://${PUBLIC_IP}/portfolio.html -> HTTP ${PORT_CODE}"
echo "Admin       http://${PUBLIC_IP}/admin/"

if [[ "$STORE_CODE" != "200" && "$STORE_CODE" != "302" ]]; then
    echo "WARNING: storefront did not return 200/302 — check /var/log/apache2/error.log"
fi
