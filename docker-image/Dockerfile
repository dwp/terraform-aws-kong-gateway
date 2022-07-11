FROM alpine:3.15.4@sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454

ARG KONG
ENV KONG_VERSION $KONG

# Upgrade packages
RUN apk update --no-cache

RUN set -eux; \
    apk add --no-cache curl wget tar ca-certificates libstdc++ libgcc openssl pcre perl tzdata libcap zip bash zlib zlib-dev \
    && curl -kfL "https://download.konghq.com/gateway-${KONG_VERSION%%.*}.x-alpine/kong-enterprise-edition-${KONG_VERSION}.apk.tar.gz" -o /tmp/kong.tar.gz \
    && mkdir /kong \
    && tar -C /kong -xzf /tmp/kong.tar.gz \
    && cp -r /kong/usr/local/* /usr/local \
    && cp -r /kong/etc/* /etc \
    && rm -rf /kong \
    && adduser -S kong \
    && addgroup -S kong \
    && mkdir -p "/usr/local/kong" \
    && chown -R kong:0 /usr/local/kong \
    && chown kong:0 /usr/local/bin/kong \
    && chmod -R g=u /usr/local/kong \
    && rm -rf /tmp/kong.tar.gz \
    && ln -s /usr/local/openresty/bin/resty /usr/local/bin/resty \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && echo $(date) > built-on.txt \
    && kong version

#Copy entrypoint files across
COPY *entrypoint.sh /
RUN chmod +x /*entrypoint.sh

USER kong

# Description of each port available here: https://docs.konghq.com/gateway/2.8.x/plan-and-deploy/default-ports
EXPOSE 8000 8443 8001 8444 8005 8006 8002 8445 8003 8446 8004 8447

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

# Set entrypoint
ENTRYPOINT ["/kong-entrypoint.sh"]
CMD ["kong", "docker-start"]
