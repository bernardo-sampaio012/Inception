# Developer documentation

## Prerequisites
- A Linux virtual machine with Docker Engine and Docker Compose
  (`docker-compose`, or the `docker compose` plugin: keep the one used
  in the Makefile).
- `make`, `openssl` and `sudo`.

## Setup from scratch

### 1. Hosts entry
Make the domain point to the local machine:

```bash
echo "127.0.0.1 bsampaio.42.fr" | sudo tee -a /etc/hosts
```

### 2. Configuration file `srcs/.env`
This file holds the non-secret settings. It is ignored by git, so it must be
created by hand. Use `KEY=value` lines with no quotes and no spaces around `=`:

```bash
LOGIN=bsampaio
DOMAIN_NAME=bsampaio.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_TITLE=Inception
WP_ADMIN_USER=boss_bsampaio
WP_ADMIN_EMAIL=boss@bsampaio.42.fr
WP_USER=bernardo
WP_USER_EMAIL=bernardo@bsampaio.42.fr
```

| Variable | Meaning |
|---|---|
| `LOGIN` | 42 login, used for the data path `/home/<LOGIN>/data` |
| `DOMAIN_NAME` | Domain of the website and of the TLS certificate |
| `MYSQL_DATABASE` / `MYSQL_USER` | WordPress database name and its user |
| `WP_TITLE` | Site title |
| `WP_ADMIN_USER` / `WP_ADMIN_EMAIL` | Administrator (the name must not contain "admin") |
| `WP_USER` / `WP_USER_EMAIL` | Second, non-administrator WordPress user |

### 3. Secrets
Passwords live in the `secrets/` folder at the repository root. It is ignored
by git and must be created by hand. One file per password, one line, no quotes:

```bash
mkdir -p secrets
for f in mariadb_password mariadb_root_password wordpress_admin_password wordpress_user_password; do
  openssl rand -hex 16 > secrets/$f.txt
  chmod 600 secrets/$f.txt
done
```

| File | Used for |
|---|---|
| `secrets/mariadb_root_password.txt` | MariaDB root password |
| `secrets/mariadb_password.txt` | Password of `MYSQL_USER` (used by MariaDB and WordPress) |
| `secrets/wordpress_admin_password.txt` | Password of `WP_ADMIN_USER` |
| `secrets/wordpress_user_password.txt` | Password of `WP_USER` |

Docker mounts each one inside the containers as `/run/secrets/<name>`.

## Build and launch
- `make` creates `/home/bsampaio/data/mariadb` and
  `/home/bsampaio/data/wordpress`, then builds the images and starts the
  containers in the background (`up -d --build`).
- `make down` stops and removes the containers (data is kept).
- `make start` / `make stop` start or stop existing containers.
- `make clean` removes containers and images.
- `make fclean` removes containers, images, volumes and all data on the host.
- `make re` rebuilds everything from scratch.

## Useful commands
```bash
make ps                                   # container status
make logs                                 # logs of all services
docker logs <mariadb|wordpress|nginx>     # logs of one service
docker exec -it <service> bash            # shell inside a container
docker-compose --env-file srcs/.env -f srcs/docker-compose.yml config   # check the resolved configuration
docker volume ls                          # list volumes
docker volume inspect srcs_mariadb_data   # show where a volume stores data
docker network inspect srcs_inception     # show containers on the network
```

## Data and persistence
- Database files: `/home/bsampaio/data/mariadb` (volume `srcs_mariadb_data`).
- WordPress files: `/home/bsampaio/data/wordpress` (volume `srcs_wordpress_data`).
- Both are Docker named volumes whose `driver_opts` place the data in those
  host folders. Data survives `make down`, restarts and crashes. Only
  `make fclean` deletes it.
- The init scripts check the existing data first, so they never reinitialize
  a database or reinstall WordPress that already exists.