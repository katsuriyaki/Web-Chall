FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ─── System packages ─────────────────────────────────────
RUN apt-get update && apt-get install -y \
    apache2 \
    php7.4 \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-xml \
    php7.4-mbstring \
    php7.4-zip \
    php7.4-imagick \
    mysql-server \
    openssh-server \
    samba \
    smbclient \
    wget \
    curl \
    unzip \
    sudo \
    gcc \
    nano \
    net-tools \
    && rm -rf /var/lib/apt/lists/* \
    rm -rf /var/lib/mysql/*

# ─── WP-CLI ──────────────────────────────────────────────
RUN curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# ─── WordPress 5.0.0 ─────────────────────────────────────
RUN wget -q https://github.com/WordPress/WordPress/archive/refs/tags/5.0.zip \
    -O /tmp/wordpress.zip \
    && unzip -q /tmp/wordpress.zip -d /tmp/ \
    && rm -f /var/www/html/index.html \
    && cp -r /tmp/WordPress-5.0/. /var/www/html/ \
    && rm -rf /tmp/WordPress-5.0 /tmp/wordpress.zip

# ─── Copy files ──────────────────────────────────────────
COPY syscheck.c /usr/bin/syscheck.c
COPY cyscom-logo.png /opt/cyscom-logo.png
COPY smb.conf /etc/smb.conf
COPY entrypoint.sh /entrypoint.sh
RUN apt-get update && apt-get install -y dos2unix && dos2unix /entrypoint.sh && rm -rf /var/lib/apt/lists/*
RUN chmod +x /entrypoint.sh

# ─── Apache modules ──────────────────────────────────────
RUN a2enmod rewrite

# ─── Expose ports ────────────────────────────────────────
# 22   = SSH
# 80   = HTTP (WordPress)
# 139  = NetBIOS (SMB)
# 445  = SMB
EXPOSE 22 80 139 445

ENTRYPOINT ["/entrypoint.sh"]
