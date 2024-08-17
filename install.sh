#!/bin/bash

# Exit script on error
set -e

# Variables
ROUND_CUBE_VERSION="1.6.0"
DB_NAME="roundcube"
DB_USER="roundcube"
DB_PASSWORD="password"
DB_HOST="localhost"
MAIL_IMAP_SERVER="imap.yourmailserver.com"
MAIL_SMTP_SERVER="smtp.yourmailserver.com"
DOMAIN="roundcube.yourdomain.com"

# Update and install dependencies
echo "Updating and installing dependencies..."
sudo apt update
sudo apt install -y apache2 php php-mysql php-mbstring php-xml php-intl php-zip mysql-server wget tar

# Download and extract Roundcube
echo "Downloading and extracting Roundcube..."
cd /var/www/
sudo wget -q https://github.com/roundcube/roundcubemail/releases/download/${ROUND_CUBE_VERSION}/roundcubemail-${ROUND_CUBE_VERSION}-complete.tar.gz
sudo tar -xzf roundcubemail-${ROUND_CUBE_VERSION}-complete.tar.gz
sudo mv roundcubemail-${ROUND_CUBE_VERSION} roundcube
sudo chown -R www-data:www-data roundcube
rm roundcubemail-${ROUND_CUBE_VERSION}-complete.tar.gz

# Configure Apache
echo "Configuring Apache..."
sudo bash -c "cat > /etc/apache2/sites-available/roundcube.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@${DOMAIN}
    DocumentRoot /var/www/roundcube
    ServerName ${DOMAIN}

    <Directory /var/www/roundcube>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/roundcube_error.log
    CustomLog \${APACHE_LOG_DIR}/roundcube_access.log combined
</VirtualHost>
EOF"

sudo a2ensite roundcube.conf
sudo a2enmod rewrite
sudo systemctl reload apache2

# Configure Roundcube
echo "Configuring Roundcube..."
sudo cp /var/www/roundcube/config/config.inc.php.sample /var/www/roundcube/config/config.inc.php
sudo sed -i "s/\$config\['db_dsnw'\] = 'mysql:\/\/localhost\/roundcube';/\$config\['db_dsnw'\] = 'mysql:\/\/${DB_USER}:${DB_PASSWORD}@${DB_HOST}/${DB_NAME}';/" /var/www/roundcube/config/config.inc.php
sudo sed -i "s/\$config\['default_host'\] = 'localhost';/\$config\['default_host'\] = 'ssl:\/\/${MAIL_IMAP_SERVER}';/" /var/www/roundcube/config/config.inc.php
sudo sed -i "s/\$config\['smtp_server'\] = 'localhost';/\$config\['smtp_server'\] = 'tls:\/\/${MAIL_SMTP_SERVER}';/" /var/www/roundcube/config/config.inc.php

# Create the database and user
echo "Creating the database and user..."
sudo mysql -u root -p <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';
FLUSH PRIVILEGES;
EXIT;
EOF

# Initialize Roundcube database
echo "Initializing Roundcube database..."
sudo /var/www/roundcube/bin/installto.sh

echo "Roundcube installation completed. Access it at http://${DOMAIN}"
