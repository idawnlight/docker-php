# PHP 7.4 FPM image with the PHP2Shell backport

This branch builds **PHP 7.4.33** with the official mitigation for
**CVE-2026-109618 and CVE-2026-109619**, from
[php/php-src commit 712e60f9edfd](https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2).

The upstream backport branch still identifies itself as `7.4.31-dev`. We apply
its fix to the final signed 7.4.33 release, retaining the later release fixes.
The patch is checked in unchanged, verified with SHA-256 and applied with zero
fuzz. The bundled source archive also contains the patch for downstream
`docker-php-ext-install` builds. `php --version` continues to report `7.4.33`;
the image description label identifies the backport commit.

PHP 7.4 and Alpine 3.16 are end of life. This is the upstream's limited mitigation
for these two CVEs, not renewed security support. Alpine remains at **3.16.9**,
the final patch release of the existing branch, because this PHP build requires
OpenSSL 1.1. Moving to current Alpine/OpenSSL requires a separate compatibility
port; the main branch uses current Alpine and PHP 8.2.

| Component | Version |
| --- | --- |
| PHP | 7.4.33 + official backport |
| Alpine | 3.16.9 |
| Composer | 2.10.3 |
| APCu | 5.1.28 |
| Imagick | 3.8.1 |
| Memcached | 3.4.0 |
| Redis | 6.3.0 |
| Swoole | 4.8.13 (latest stable compatible with PHP 7.4) |

Version pins were checked on 2026-10-21. PHP, Composer and PECL downloads use
SHA-256 checksums. PHP also uses its release signature and a refreshed, bundled
[release key](keys/README.md); public keyservers and pickle are no longer needed.
The upstream Docker PHP helper scripts and GitHub Actions have also been refreshed.

### Build

```sh
docker build --pull -t docker-php:7.4.33-backport .
docker buildx build --pull --platform linux/amd64,linux/arm64 .
docker run --rm docker-php:7.4.33-backport php --version
docker run --rm docker-php:7.4.33-backport php-fpm --test
```

Each final image build reports the PHP version and checks the FPM configuration.
CI builds both architectures before publishing and only builds pull requests. The existing `www-data` UID 990
and optional `ENABLE_CRONTAB` behavior are retained. FPM uses graceful `SIGQUIT`
shutdown and its request timeout is now set in the FPM pool configuration.

See [patch provenance](patches/README.md) before updating the mitigation.
Update version and checksum arguments together, using the
[PHP release API](https://www.php.net/releases/index.php?json&version=7.4.33),
[Composer versions](https://getcomposer.org/versions) and [PECL](https://pecl.php.net/).
The Docker PHP helpers are from
[docker-library/php at 9dac3d0](https://github.com/docker-library/php/tree/9dac3d048ebdcdb3b6a27350b7572ddee58c70df).

### Pull

```
$ docker pull ghcr.io/idawnlight/php:php7
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
xmlrpc
xmlwriter
xsl
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
```
