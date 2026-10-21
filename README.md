# PHP FPM image

Current build: **PHP 8.2.35**, including the upstream PHP2Shell fixes, on **Alpine 3.24.2**.
Release pins were checked on 2026-10-21.

| Component | Version |
| --- | --- |
| PHP | 8.2.35 |
| Alpine | 3.24.2 |
| Composer | 2.10.3 |
| APCu | 5.1.28 |
| Imagick | 3.8.1 |
| Memcached | 3.4.0 |
| Redis | 6.3.0 |
| Swoole | 6.2.3 |

Alpine packages are upgraded within the selected stable branch on uncached builds.
PECL archives and Composer are pinned with SHA-256 checksums; PHP is verified with
both its published SHA-256 and the release signature. The checked-in
[PHP signing keys](keys/README.md) avoid public keyserver availability problems.
The old pickle installer has been replaced by direct, verified PECL source builds.

### Build

```sh
docker build --pull -t docker-php:8.2.35 .
# Build both supported platforms (also done by GitHub Actions):
docker buildx build --pull --platform linux/amd64,linux/arm64 .
docker run --rm docker-php:8.2.35 php --version
docker run --rm docker-php:8.2.35 php-fpm --test
```

Each final image build reports the PHP version and checks the FPM configuration.
Pull requests build without publishing; successful push builds retain the existing
GHCR tagging scheme.

GD uses the supported PHP 8 configure flags. Swoole 6 enables OpenSSL, sockets,
MySQL native support, HTTP/2 and Brotli; applications using older Swoole APIs should
be checked against the [Swoole release notes](https://github.com/swoole/swoole-src/releases).
The runtime retains the existing `www-data` UID 990 and optional `ENABLE_CRONTAB`
behavior. FPM now receives `SIGQUIT` for graceful shutdown, and its request timeout
is configured in the FPM pool instead of php.ini.

### Updating releases

Update the matching `*_VERSION` and `*_SHA256` build arguments together in
`Dockerfile`. PHP metadata comes from the [PHP release API](https://www.php.net/releases/index.php?json&version=8.2),
Composer from [getcomposer.org](https://getcomposer.org/versions), and extension
versions from [PECL](https://pecl.php.net/). Verify new archives before changing
checksums, refresh the signing keys when needed, then build both platforms.
The `docker-php-*` upstream helpers were refreshed from
[docker-library/php at 9dac3d0](https://github.com/docker-library/php/tree/9dac3d048ebdcdb3b6a27350b7572ddee58c70df).

### Pull

```
$ docker pull ghcr.io/idawnlight/php:[tag]
```

### Extension

```
[PHP Modules]
apcu
bcmath
Core
ctype
curl
date
dom
exif
fileinfo
filter
ftp
gd
gettext
gmp
hash
iconv
imagick
intl
json
libxml
mbstring
memcached
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
pgsql
Phar
posix
random
readline
redis
Reflection
session
shmop
SimpleXML
soap
sockets
sodium
SPL
sqlite3
standard
swoole
sysvsem
tidy
tokenizer
xml
xmlreader
xmlwriter
xsl
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
```
