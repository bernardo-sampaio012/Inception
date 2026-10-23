*This project has been created as part of the 42 curriculum by bsampaio.*

# Inception

## Description
Inception sets up a small web infrastructure with Docker Compose inside a
virtual machine: NGINX (TLSv1.2/1.3 only, port 443), WordPress with PHP-FPM
and MariaDB, each in its own container, built from our own Dockerfiles on
Debian bookworm. Data persists in two named volumes stored under
`/home/bsampaio/data`. Credentials are handled with Docker secrets and a
`.env` file.

## Instructions
1. Add the domain: `echo "127.0.0.1 bsampaio.42.fr" | sudo tee -a /etc/hosts`
2. Create `srcs/.env` and the files in `secrets/`, as described in DEV_DOC.md.
3. Run `make` to build and start everything.
4. Open https://bsampaio.42.fr (accept the self-signed certificate).
5. `make down` stops it, `make fclean` removes everything including data.

See USER_DOC.md and DEV_DOC.md for details.

## Project description
Sources: one Dockerfile per service under `srcs/requirements/<service>`,
`srcs/docker-compose.yml`, and a `Makefile` at the root. Main design choices:
Debian bookworm base images, no pulled ready-made images, services started as
PID 1 through `exec`, idempotent init scripts, secrets mounted in
`/run/secrets`.

### Virtual Machines vs Docker
A VM virtualizes hardware and runs a full guest OS with its own kernel: heavy,
slow to start, strongly isolated. A container shares the host kernel and only
packages the app and its dependencies: light and fast, with weaker isolation.

### Secrets vs Environment Variables
Environment variables are simple but visible in `docker inspect` and process
environments. Secrets are mounted as files in `/run/secrets`, only for the
services that need them. We use `.env` for non-sensitive settings and secrets
for passwords.

### Docker Network vs Host Network
A bridge network gives containers isolated addressing and DNS by service name;
only published ports are exposed. Host network removes this isolation and is
forbidden by the subject. We use a bridge network named `inception`.

### Docker Volumes vs Bind Mounts
Volumes are managed by Docker; bind mounts map an arbitrary host path
directly. We use named volumes, with `driver_opts` placing their data in
`/home/bsampaio/data` as required by the subject.

## Resources
- Docker documentation: https://docs.docker.com
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- NGINX documentation: https://nginx.org/en/docs/
- WP-CLI handbook: https://make.wordpress.org/cli/handbook/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/

AI usage: an AI assistant as Claude IA was used as a tutor for this project. It was used to
review the project structure against the subject, to propose reference
versions of the Dockerfiles, the init scripts, the Docker Compose file and the
documentation, to explain Docker, NGINX, TLS and PHP-FPM concepts, to suggest
a test checklist and to help diagnose build and runtime errors.