#!/bin/sh
# ediOS: Dateien fuer ein GitHub-Release vorbereiten (GPL-3.0-or-later).
#   build/release-dateien.sh            -> out/release-<Version>/  (ab 1.1 je Version ein eigener Ordner)
# Inhalt: ISO, SHA256SUMS (ISO + oeffentliche Schluessel), SHA256SUMS.sig (signiert mit ~/ediOS-keys/edios-repo.rsa,
# pruefbar mit dem oeffentlichen edios-repo.rsa.pub), edios-mok.der/.crt (Secure-Boot-Zertifikat), LIESMICH/README.
# Pruefen:  openssl dgst -sha256 -verify edios-repo.rsa.pub -signature SHA256SUMS.sig SHA256SUMS
set -eu
P="$(cd "$(dirname "$0")/.." && pwd)"
. "$P/config.sh"
KEYS="${EDIOS_KEYS:-$HOME/ediOS-keys}"
ISO="edios-$EDIOS_FILEVER-x86_64.iso"
R="$P/out/release-$EDIOS_FILEVER"
[ -f "$P/out/$ISO" ] || { echo "out/$ISO fehlt (erst ./build.sh)" >&2; exit 1; }
[ -f "$KEYS/edios-repo.rsa" ] || { echo "$KEYS/edios-repo.rsa fehlt" >&2; exit 1; }
cmp -s "$KEYS/edios-repo.rsa.pub" "$P/src/pubkeys/edios-repo.rsa.pub" || { echo "Schluessel passt nicht zu src/pubkeys" >&2; exit 1; }
rm -rf "$R"; mkdir -p "$R"
ln "$P/out/$ISO" "$R/$ISO" 2>/dev/null || cp "$P/out/$ISO" "$R/$ISO"
cp "$P/src/pubkeys/edios-repo.rsa.pub" "$P/src/pubkeys/edios-mok.der" "$P/src/pubkeys/edios-mok.crt" "$R/"
cp "$P/out/LIESMICH.txt" "$P/out/README.txt" "$R/"
(cd "$R" && sha256sum "$ISO" edios-repo.rsa.pub edios-mok.der edios-mok.crt > SHA256SUMS)
openssl dgst -sha256 -sign "$KEYS/edios-repo.rsa" -out "$R/SHA256SUMS.sig" "$R/SHA256SUMS"
openssl dgst -sha256 -verify "$R/edios-repo.rsa.pub" -signature "$R/SHA256SUMS.sig" "$R/SHA256SUMS"
(cd "$R" && sha256sum -c SHA256SUMS)
# nie ein privater Schluessel im Release
# (die ISO selbst prueft build/inner.sh beim Bau; libcrypto enthaelt den Text "PRIVATE KEY" als Programmtext)
for f in "$R"/*; do
	[ "${f##*/}" = "$ISO" ] && continue
	if grep -qaE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$f"; then echo "FEHLER: privater Schluessel in ${f##*/}" >&2; exit 1; fi
done
ls -l "$R"
