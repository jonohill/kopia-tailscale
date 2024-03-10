FROM alpine AS downloads

RUN apk add --no-cache \
        ca-certificates \
        curl \
        gpg

RUN mkdir -p /usr/share/keyrings && curl -fsSL https://kopia.io/signing-key | gpg --dearmor -o /usr/share/keyrings/kopia-keyring.gpg

# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION=v1.66.0

ARG TARGETPLATFORM

RUN case $TARGETPLATFORM in \
        "linux/amd64") \
            RCLONE_ARCH="amd64" \
            ;; \
        "linux/arm64") \
            RCLONE_ARCH="arm64" \
            ;; \
        "linux/arm/v7") \
            RCLONE_ARCH="arm-v7" \
            ;; \
        default) \
            echo "Unsupported platform: $TARGETPLATFORM" && exit 1 \
            ;; \
    esac && \
    echo Download https://downloads.rclone.org/$RCLONE_VERSION/rclone-$RCLONE_VERSION-linux-$RCLONE_ARCH.deb && \
    curl -fsSL https://downloads.rclone.org/$RCLONE_VERSION/rclone-$RCLONE_VERSION-linux-$RCLONE_ARCH.deb -o /tmp/rclone.deb

RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    mkdir -p /etc/apt/sources.list.d && curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

FROM debian:12.5-slim

# renovate: datasource=github-releases depName=kopia/kopia
ARG KOPIA_VERSION=0.15.0

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm-256color" \
    LC_ALL="C.UTF-8" \
    KOPIA_CONFIG_PATH=/config/repository.config \
    KOPIA_LOG_DIR=/data/logs \
    KOPIA_CACHE_DIRECTORY=/data/cache \
    RCLONE_CONFIG=/config/rclone/rclone.conf \
    KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=false \
    KOPIA_CHECK_FOR_UPDATES=false

COPY --from=downloads /usr/share/keyrings/kopia-keyring.gpg /usr/share/keyrings/kopia-keyring.gpg
COPY --from=downloads /tmp/rclone.deb /tmp/rclone.deb
COPY --from=downloads /usr/share/keyrings/tailscale-archive-keyring.gpg /usr/share/keyrings/tailscale-archive-keyring.gpg
COPY --from=downloads /etc/apt/sources.list.d/tailscale.list /etc/apt/sources.list.d/tailscale.list

RUN echo "deb [signed-by=/usr/share/keyrings/kopia-keyring.gpg] http://packages.kopia.io/apt/ stable main" | tee /etc/apt/sources.list.d/kopia.list

RUN apt-get update && \
    apt-get upgrade -y --with-new-pkgs && \
    apt-get install -y ca-certificates && apt-get update && \
    dpkg -i /tmp/rclone.deb && rm /tmp/rclone.deb && \
    apt-get install -y --no-install-recommends \
        curl \
        fuse3 \
        kopia=$KOPIA_VERSION \
        tailscale \
        && \
    apt-get clean autoclean -y && \
    apt-get autoremove -y && \
        rm -rf /var/lib/apt/* /var/lib/cache/* /var/lib/log/* \
        /var/tmp/* /usr/share/doc/ /usr/share/man/ /usr/share/locale/ \
        /root/.cache /root/.local /root/.gnupg /root/.config /tmp/*

COPY --from=ghcr.io/jonohill/docker-multirun:1.1.3 / /

COPY /root /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
