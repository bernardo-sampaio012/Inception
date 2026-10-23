# User documentation

## Services
- **NGINX**: the only public entry point (HTTPS, port 443).
- **WordPress + PHP-FPM**: the website and its administration panel.
- **MariaDB**: the database used by WordPress (internal only).

## Start and stop
- Start: `make`
- Stop (keeps data): `make down`
- Resume stopped containers: `make start`
- Full reset (deletes all data): `make fclean`

## Access
- Website: https://bsampaio.42.fr
- Admin panel: https://bsampaio.42.fr/wp-admin
- The browser warns about the certificate: it is self-signed, accept it.
- Requires `127.0.0.1 bsampaio.42.fr` in `/etc/hosts`.

## Credentials
- Non-secret settings (usernames, domain): `srcs/.env`
- Passwords: files in `secrets/` (never committed to git).
- WordPress users: administrator `boss_bsampaio`, author `visitor`.

## Check that everything works
- `make ps`: three containers should be `Up`.
- `make logs`: no repeated errors.
- `curl -k -I https://bsampaio.42.fr`: should return `HTTP/1.1 200 OK`.