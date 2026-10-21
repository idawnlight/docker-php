# PHP 7.4 release key

`php-7.4.asc` contains Derick Rethans's refreshed public key, exported from
https://www.php.net/distributions/php-keyring.gpg on 2026-10-21.

Primary fingerprint: `5A52880781F755608BF815FC910DEB46F53EA312`.
This key signs the PHP 7.4.33 source archive and is valid through 2029.

The build verifies both the original archive's published SHA-256 and its detached
signature before applying the separately pinned upstream backport patch.
To refresh this key, download the official keyring over HTTPS, inspect the full
fingerprint and expiry in an isolated GnuPG home, and export only this key.
