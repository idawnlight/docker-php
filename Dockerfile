ARG ALPINE_VERSION=3.24.2
ARG PHP_VERSION=8.2.35
FROM alpine:${ALPINE_VERSION} AS builder

# Based on metowolf's image and docker-library/php.
LABEL maintainer="idawnlight <idawn@live.com>"

ARG PHP_VERSION
ARG PHP_SHA256=5737b98601fe5ab1b8c5db0c82ed3158acb9283ed3081ffe2faffb9ac81455e6

ENV PHP_INI_DIR=/usr/local/etc/php \
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c" \
    PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" \
    PHP_LDFLAGS="-Wl,-O1 -pie"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"

# Refreshed PHP 8.2 release-manager keys; no dependency on public keyservers.
COPY keys/php-8.2.asc /usr/src/php-keys.asc
RUN set -eux; \
    apk upgrade --no-cache; \
    apk add --no-cache ca-certificates curl gnupg tar xz; \
    cd /usr/src; \
    curl -fsSL --retry 3 -o php.tar.xz "https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz"; \
    echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
    curl -fsSL --retry 3 -o php.tar.xz.asc "https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --import php-keys.asc; \
    gpg --batch --verify php.tar.xz.asc php.tar.xz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" php-keys.asc php.tar.xz.asc

COPY docker-php-source docker-php-ext-* docker-php-entrypoint /usr/local/bin/

RUN set -eux; \
    apk add --no-cache $PHPIZE_DEPS \
        argon2-dev coreutils curl-dev gnu-libiconv-dev libedit-dev \
        libsodium-dev libxml2-dev linux-headers oniguruma-dev openssl-dev \
        sqlite-dev; \
    rm -f /usr/include/iconv.h; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    docker-php-source extract; \
    cd /usr/src/php; \
    mkdir -p "$PHP_INI_DIR/conf.d"; \
    adduser -u 82 -D -S -G www-data www-data; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
        --build="$gnuArch" \
        --sysconfdir=/usr/local/etc \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-mhash \
        --with-pic \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
        --with-sqlite3=/usr \
        --with-curl \
        --with-iconv=/usr \
        --with-libedit \
        --with-openssl \
        --with-zlib \
        --with-pear \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --disable-cgi; \
    make -j "$(nproc)"; \
    make install; \
    strip --strip-all /usr/local/bin/php /usr/local/bin/phpdbg /usr/local/sbin/php-fpm; \
    make clean; \
    cp -v php.ini-* "$PHP_INI_DIR/"; \
    cd /; \
    docker-php-source delete; \
    php --version

# Bundled extensions. Modern configure flags ensure all GD formats are enabled.
RUN set -eux; \
    apk add --no-cache \
        freetype-dev gettext-dev gmp-dev icu-dev libgcrypt-dev libjpeg-turbo-dev \
        libpng-dev libpq-dev libwebp-dev libxpm-dev libxslt-dev libzip-dev tidyhtml-dev
RUN set -eux; \
    ln -sf /usr/include/gnu-libiconv/iconv.h /usr/include/iconv.h; \
    LIBS="-liconv" docker-php-ext-configure gd --enable-option-checking=fatal \
        --with-webp --with-jpeg --with-xpm --with-freetype --enable-gd-jis-conv; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath exif gd gettext gmp intl mysqli opcache pcntl pdo_mysql \
        pdo_pgsql pgsql shmop soap sockets sysvsem tidy xsl zip; \
    docker-php-ext-enable sodium

# Pin PECL releases and verify archives before compiling them.
COPY docker-php-pecl-install /usr/local/bin/
ARG APCU_VERSION=5.1.28
ARG APCU_SHA256=ca9c1820810a168786f8048a4c3f8c9e3fd941407ad1553259fb2e30b5f057bf
RUN docker-php-pecl-install apcu "$APCU_VERSION" "$APCU_SHA256"

ARG IMAGICK_VERSION=3.8.1
ARG IMAGICK_SHA256=3a3587c0a524c17d0dad9673a160b90cd776e836838474e173b549ed864352ee
RUN apk add --no-cache imagemagick-dev \
    && docker-php-pecl-install imagick "$IMAGICK_VERSION" "$IMAGICK_SHA256"

ARG MEMCACHED_VERSION=3.4.0
ARG MEMCACHED_SHA256=c163434eb0da97c8f45c7ad41d979d381f8b81c49402b1b90b063987fb37972e
RUN apk add --no-cache libmemcached-dev cyrus-sasl-dev \
    && docker-php-pecl-install memcached "$MEMCACHED_VERSION" "$MEMCACHED_SHA256"

ARG REDIS_VERSION=6.3.0
ARG REDIS_SHA256=0d5141f634bd1db6c1ddcda053d25ecf2c4fc1c395430d534fd3f8d51dd7f0b5
RUN docker-php-pecl-install redis "$REDIS_VERSION" "$REDIS_SHA256"

ARG SWOOLE_VERSION=6.2.3
ARG SWOOLE_SHA256=21dfa1c4a4a09f4d1cb4b154f7defdc91fbabafc8d44a77f8f618b9742c67304
RUN apk add --no-cache brotli-dev nghttp2-dev \
    && docker-php-pecl-install swoole "$SWOOLE_VERSION" "$SWOOLE_SHA256" \
        --with-openssl-dir=/usr --enable-sockets --enable-mysqlnd \
        --enable-brotli --with-nghttp2-dir=/usr

ARG COMPOSER_VERSION=2.10.3
ARG COMPOSER_SHA256=7a2d379d5b8ffdaa028580ef26494c36d2feef4b178d3dd1473a4dbc5e17c8d6
RUN set -eux; \
    curl -fsSL --retry 3 -o /usr/local/bin/composer \
        "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar"; \
    echo "$COMPOSER_SHA256 */usr/local/bin/composer" | sha256sum -c -; \
    chmod +x /usr/local/bin/composer; \
    strip --strip-all "$(php-config --extension-dir)"/*.so; \
    rm -rf /usr/local/lib/php/test /usr/local/lib/php/doc /tmp/pear; \
    composer --version

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="idawnlight <idawn@live.com>"

ENV PHP_INI_DIR=/usr/local/etc/php \
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c"
COPY --from=builder /usr/local/ /usr/local/

RUN set -eux; \
    apk upgrade --no-cache; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache $runDeps ca-certificates curl icu-data-full imagemagick tar unzip xz; \
    adduser -u 990 -D -S -G www-data www-data; \
    cd /usr/local/etc; \
    cp php-fpm.conf.default php-fpm.conf; \
    cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
    sed -i 's/^listen = 127.0.0.1:9000/;listen = 127.0.0.1:9000/' php-fpm.d/www.conf; \
    { \
        echo '[global]'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo 'log_limit = 8192'; \
        echo '[www]'; \
        echo 'access.log = /proc/self/fd/2'; \
        echo 'clear_env = no'; \
        echo 'catch_workers_output = yes'; \
        echo 'decorate_workers_output = no'; \
        echo 'listen = 9000'; \
        echo 'request_terminate_timeout = 600'; \
    } > php-fpm.d/docker.conf; \
    { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo '[www]'; \
    } > php-fpm.d/zz-docker.conf; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.jit=1255'; \
        echo 'opcache.jit_buffer_size=100M'; \
    } > "$PHP_INI_DIR/conf.d/opcache-recommended.ini"; \
    { \
        echo 'memory_limit=256M'; \
        echo 'upload_max_filesize=50M'; \
        echo 'post_max_size=100M'; \
        echo 'max_execution_time=600'; \
        echo 'default_socket_timeout=3600'; \
        echo 'fastcgi.logging=Off'; \
    } > "$PHP_INI_DIR/conf.d/options.ini"; \
    php --version; \
    php-fpm --test

COPY --from=builder /usr/src/php.tar.xz /usr/src/php.tar.xz
WORKDIR /var/www/html
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
STOPSIGNAL SIGQUIT
EXPOSE 9000
CMD ["php-fpm"]
