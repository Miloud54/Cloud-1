#!/bin/bash
set -e # stop si erreur

# recup secrets
if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -f "/run/secrets/credentials" ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)
fi

echo "Starting WordPress setup..."

# prepa env
mkdir -p /run/php
cd /var/www/html

if [ ! -f wp-load.php ]; then
    echo "Downloading WordPress..."
    rm -f index.html
    curl -L -o /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    echo "Extracting WordPress..."
    tar -xzf /tmp/latest.tar.gz -C /var/www/html --strip-components=1
    rm -f /tmp/latest.tar.gz
fi

# attente mariadb pour eviter crash si DB pas prete
echo "Waiting for MariaDB..."
until mariadb -h"${MYSQL_HOSTNAME}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --ssl=false -e "SELECT 1;"; do
    echo "MariaDB not ready yet..."
    sleep 2
done

# config wp-config.php = lien vers DB
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/${MYSQL_DATABASE}/" wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/" wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/" wp-config.php
    sed -i "s/localhost/${MYSQL_HOSTNAME}/" wp-config.php
    sed -i "/'DB_COLLATE'/a define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT);" wp-config.php
fi

# installation site si pas encore fait
if ! wp core is-installed --allow-root --path="/var/www/html" >/dev/null 2>&1; then
    echo "Installing WordPress core..."
    wp core install \
        --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --path="/var/www/html"
fi

# crea second user
if ! wp user get "${WP_USER}" --allow-root --path="/var/www/html" >/dev/null 2>&1; then
    echo "Creating secondary user..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --allow-root \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path="/var/www/html"
fi

# definition URL 
if ! grep -q "WP_HOME" wp-config.php; then
    echo "Setting WP_HOME and WP_SITEURL..."
    sed -i "/<?php/a define('WP_HOME', 'https://${DOMAIN_NAME}');\ndefine('WP_SITEURL', 'https://${DOMAIN_NAME}');" wp-config.php
fi

# lancement 
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
