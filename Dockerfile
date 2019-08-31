#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="1.0.3"
ARG plugins="git,cors,realip,expires,cache,cloudflare"
ARG enable_telemetry="true"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM hydrawork/alpine:3.10
LABEL maintainer="hydrawork <alex@hydra.work>"

ARG version="1.0.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false" \
    ENABLE_TELEMETRY="$enable_telemetry"

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy
# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

VOLUME /root/.caddy /srv

RUN apk add --no-cache \
    git \
    mailcap \
    openssh-client && \
    /usr/bin/caddy -version && \
    /usr/bin/caddy -plugins && \
    echo "Caddy Ok" > /srv/index.html \
    echo -e "0.0.0.0\nbrowse\nlog stdout\nerrors stdout" > /etc/Caddyfile

EXPOSE 80 443 2015
WORKDIR /srv

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]