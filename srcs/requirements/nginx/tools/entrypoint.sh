#!/bin/sh
set -e

sed -i "s/__DOMAIN_NAME__/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=AO/L=Luanda/O=42/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME}"
fi

exec nginx -g "daemon off;"