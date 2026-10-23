#!/bin/bash

# Faz o script parar se um comando falhar.
set -e

# Lê as passwords dos Docker secrets (ficheiros em /run/secrets).
MYSQL_PASSWORD="$(cat /run/secrets/mariadb_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/mariadb_root_password)"

# O volume vem do host e pode pertencer a outro utilizador.
# O MariaDB corre como "mysql" e precisa de escrever aqui.
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# 1) Cria as tabelas internas do MariaDB, se ainda não existirem.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Installing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# 2) Configura a base de dados do WordPress, se ainda não existir.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Configuring database and users..."

    # Servidor temporário, só por socket local (sem rede).
    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    pid="$!"

    # Espera até 30 segundos que o servidor responda.
    tries=0
    until mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; do
        tries=$((tries + 1))
        if [ "$tries" -ge 30 ]; then
            echo "MariaDB did not start" >&2
            exit 1
        fi
        sleep 1
    done

    mariadb --socket=/run/mysqld/mysqld.sock --user=root <<-SQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
SQL

    mariadb-admin --socket=/run/mysqld/mysqld.sock --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid" || true
fi

# Servidor definitivo em primeiro plano. O exec faz dele o PID 1.
exec mariadbd --user=mysql --console