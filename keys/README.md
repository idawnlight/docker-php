# PHP 8.2 release keys

`php-8.2.asc` contains the following PHP 8.2 release-manager public keys, exported
from https://www.php.net/distributions/php-keyring.gpg on 2026-10-21:

| Release manager | Primary fingerprint |
| --- | --- |
| Pierrick Charron | `1198C0117593497A5EC5C199286AF1F9897469DC` |
| Sergey Panteleev | `E60913E4DF209907D8E30D96659A97C9CF2A795A` |

PHP 8.2.35 is signed by Sergey Panteleev. His refreshed key expires in 2030.
The old Ben Ramsey key (`39B641343D8C104B2B146DC3F9C39DC0B9698544`) expired in
2025 and is no longer included. Keys for unrelated PHP branches are excluded.

To refresh, download the official keyring over HTTPS, inspect the fingerprints
and expiry dates in an isolated GnuPG home, and export only the verified PHP 8.2
release-manager keys. Validate the new PHP archive signature and published
SHA-256 before committing the updated keyring and version pins.
