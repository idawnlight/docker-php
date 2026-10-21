# Official PHP 7.4 PHP2Shell mitigation

- Upstream branch: https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619
- Commit: `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`
- Patch source: https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2.patch
- SHA-256: `5fe57ca6ee96d59b36c6e0ca842843c50884f177bef1e85234cf669b577f5e48`
- Upstream commit signature was reported valid by GitHub on 2026-10-21.

The patch is stored unchanged as `CVE-2026-109618-109619.patch`. Upstream describes
it as “Minimal mitigation for EOL version.” It addresses GHSA-w8hw-w9fx-j79w
(CVE-2026-109618) and GHSA-6wmf-4rv5-p3rp (CVE-2026-109619).

The Docker build validates the patch checksum, applies it to the authenticated
PHP 7.4.33 release with `patch --fuzz=0`, and checks that the entire patch can be
reversed. It repacks the patched source for subsequent extension builds.
