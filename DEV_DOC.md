# Developer documentation

## Prerequisites
A Linux VM with Docker Engine, the Docker Compose plugin, `make` and `sudo`.

## Setup from scratch
1. Hosts entry: `echo "127.0.0.1 bsampaio.42.fr" | sudo tee -a /etc/hosts`
2. Configuration: copy `srcs/.env.example` to `srcs/.env` and edit it.
3. Secrets:
   mkdir -p secrets
   for f in db_password db_root_password wp_admin_password wp_user_password; do
     openssl rand -hex 16 > secrets/$f.txt; chmod 600 secrets/$f.txt
   done

## Build and launch
- `make` creates `/home/bsampaio/data/{mariadb,wordpress}` and runs
  `docker compose -f srcs/docker-compose.yml up -d --build`.

## Useful commands
- `docker compose -f srcs/docker-compose.yml ps | logs | config`
- `docker exec -it wordpress bash` / `docker exec -it mariadb bash`
- `docker volume ls`, `docker volume inspect srcs_mariadb_data`
- `docker network inspect srcs_inception`

## Data and persistence
- Database: `/home/bsampaio/data/mariadb` (volume `srcs_mariadb_data`)
- Website files: `/home/bsampaio/data/wordpress` (volume `srcs_wordpress_data`)
- Both are Docker named volumes with `driver_opts` pointing to those host
  paths. Data survives `make down` and container restarts; only `make fclean`
  deletes it. Init scripts check the existing data and skip initialization.