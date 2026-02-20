#!/bin/sh
set -e

: "${CLIENT_DOMAIN:=app.localhost}"
: "${ADMIN_DOMAIN:=admin.localhost}"
: "${SSL_ENABLED:=false}"

echo "EndPlan reverse proxy"
echo "  Client domain: $CLIENT_DOMAIN"
echo "  Admin domain:  $ADMIN_DOMAIN"
echo "  SSL:           $SSL_ENABLED"

if [ "$SSL_ENABLED" = "true" ]; then
    TEMPLATE_FILE="/etc/nginx/templates/nginx-ssl.conf.template"
    mkdir -p /etc/nginx/ssl

    if [ ! -f /etc/nginx/ssl/cert.pem ] || [ ! -f /etc/nginx/ssl/key.pem ]; then
        echo "Generating self-signed certificate for $CLIENT_DOMAIN and $ADMIN_DOMAIN..."
        if touch /etc/nginx/ssl/.write-test 2>/dev/null; then
            rm -f /etc/nginx/ssl/.write-test
            # SAN: each space-separated CLIENT_DOMAIN and ADMIN_DOMAIN as DNS:, plus localhost and 127.0.0.1
            SAN=""
            for d in $CLIENT_DOMAIN $ADMIN_DOMAIN; do
                [ -n "$d" ] && SAN="${SAN}DNS:${d},"
            done
            SAN="${SAN}DNS:localhost,IP:127.0.0.1"
            CN=$(echo "$CLIENT_DOMAIN" | awk '{print $1}')
            [ -z "$CN" ] && CN="localhost"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/nginx/ssl/key.pem \
                -out /etc/nginx/ssl/cert.pem \
                -subj "/CN=${CN}/O=EndPlan/C=US" \
                -addext "subjectAltName=$SAN"
            echo "Self-signed certificate created."
        else
            echo "ERROR: Cannot write to /etc/nginx/ssl/"
            exit 1
        fi
    fi
else
    TEMPLATE_FILE="/etc/nginx/templates/nginx.conf.template"
fi

export CLIENT_DOMAIN
export ADMIN_DOMAIN
echo "Generating nginx config..."
envsubst '${CLIENT_DOMAIN} ${ADMIN_DOMAIN}' < "$TEMPLATE_FILE" > /etc/nginx/conf.d/default.conf

nginx -t
exec nginx -g "daemon off;"
