FROM nginx:alpine

RUN apk add --no-cache curl openssl gettext

RUN mkdir -p /etc/nginx/ssl /etc/nginx/templates

COPY nginx.conf.template /etc/nginx/templates/
COPY nginx-ssl.conf.template /etc/nginx/templates/

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV CLIENT_DOMAIN=demo.endplan.com
ENV ADMIN_DOMAIN=admin.endplan.com
ENV SSL_ENABLED=true

EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]
