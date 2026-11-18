#!/bin/bash
set -e

# recup secrets
if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -f "/run/secrets/db_root_password" ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi

# droits acces
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# si pas DB existante on initialise
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

# création fichier SQL temp pour config users
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Creating temporary SQL file..."
    cat << EOF > /tmp/db_setup.sql
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # on lance mysqld juste juste pour exécuter ce fichier puis il s'arrête
    echo "Running initial setup..."
    mysqld --user=mysql --bootstrap < /tmp/db_setup.sql
    rm -f /tmp/db_setup.sql
fi

echo "Starting MariaDB..."
exec mysqld_safe
