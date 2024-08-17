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
sudo apt install -y a
