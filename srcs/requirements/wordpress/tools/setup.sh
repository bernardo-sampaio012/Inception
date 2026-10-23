#!/bin/bash
set -e

WP_PATH=/var/www/html

DB_PASS="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASS="$(cat /run/secrets/wp_user_password)"

# Espera (no máximo ~60s) que o MariaDB aceite ligações.
tries=0
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${DB_PASS}" "${MYSQL_DATABASE}" -e "SELECT 1" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 30 ]; then
        echo "MariaDB not reachable" >&2
        exit 1
    fi
    sleep 2
done

mkdir -p /run/php
cd "${WP_PATH}"

# Descarrega o WordPress se o volume estiver vazio.
if [ ! -f wp-settings.php ]; then
    wp core download --allow-root
fi

# Cria o wp-config.php.
if [ ! -f wp-config.php ]; then
    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost="mariadb:3306"
fi

# Instala o site e cria o administrador.
if ! wp core is-installed --allow-root; then
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
fi

# Cria o segundo utilizador.
if ! wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --allow-root \
        --user_pass="${WP_USER_PASS}" --role=author
fi

chown -R www-data:www-data "${WP_PATH}"

# PHP-FPM em primeiro plano, como PID 1.
exec php-fpm8.2 -F