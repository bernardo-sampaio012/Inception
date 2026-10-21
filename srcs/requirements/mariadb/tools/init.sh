#!/bin/bash

# Faz o script parar se um comando falhar.
set -e

# Verifica se a base de dados ainda não foi inicializada.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing the MariaDB..."

    # Cria as tabelas internas necessárias para o MariaDB funcionar.
    # Define o utilizador e o directório onde os dados serão guardados.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Inicia o MariaDB temporariamente, sem ligações pela rede.
    # O socket permite a comunicação local com o servidor.
    # O & executa o processo em segundo plano.
    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &

    # Guarda o PID (identificador do processo) do MariaDB temporário.
    pid="$!"

    # Espera até o MariaDB estar pronto para receber comandos.
    until mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; do
        # Espera um segundo antes de verificar novamente.
        sleep 1
    done

    # Liga-se ao MariaDB pelo socket e executa os comandos SQL abaixo.
    mariadb --socket=/run/mysqld/mysqld.sock --user=root <<-SQL
        -- Cria a base de dados do WordPress, se ainda não existir.
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

        -- Cria o utilizador que o WordPress usará para aceder à base de dados.
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

        -- Dá ao utilizador permissões sobre a base de dados do WordPress.
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

        -- Define a palavra-passe do administrador root local.
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

        -- Aplica as alterações às permissões.
        FLUSH PRIVILEGES;
SQL

    # Desliga o MariaDB temporário usando a palavra-passe do root.
    mariadb-admin --socket=/run/mysqld/mysqld.sock --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown

    # Espera que o processo temporáio termine.
    # O || true evita que o script pare se o processo terminar com erro.
    wait "$pid" || true
fi

# Inicia o MariaDB em primeiro plano para o container continuar activo.
# O exec substitui o processo do script pelo servidor MariaDB.
exec mariadbd --user=mysql --console
