#!/bin/sh
# ediOS: Test der eigenen Pakete in einem frischen Alpine-3.24-Container (als root im Container). GPL-3.0-or-later
#   tests/repo-test.sh            (auf dem Host; braucht repo/edios/x86_64 von build-repo.sh oder build.sh)
# Prueft:
#   - Signatur: ohne Schluessel UNTRUSTED, mit Schluessel OK; eine falsch signierte Kopie wird abgelehnt
#   - Installation edios-keyring/base/theme/apps, post-install (dconf, D-Bus-Override), keine .apk-new
#   - edios.list ist ab Werk eingeschaltet (URL der ediOS-Paketquelle)
#   - apk del edios-base: Schluessel und Quelle bleiben (Paket edios-keyring), Quelle bleibt vertrauenswuerdig
#   - Update-Knopf root-Teil: B) ediOS-Quelle weg -> RC 0 + Hinweis, D) alles weg -> Fehler 10
set -eu
P="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$P/repo/edios/x86_64/APKINDEX.tar.gz" ] || { echo "erst ./packages/build-repo.sh" >&2; exit 1; }
. "$P/config.sh"
exec docker run --rm -i -e URL="$EDIOS_REPO_URL" -v "$P:/edios:ro" \
	alpine:3.24 sh -s <<'EOS'
set -u
ok() { echo "  OK   $*"; }
bad() { echo "  FEHLER $*"; FAIL=1; }
FAIL=0
M=https://mirror.netcologne.de/alpine/v3.24
printf '%s/main\n%s/community\n' "$M" "$M" > /etc/apk/repositories
apk update -q >/dev/null
apk add -q openssl abuild >/dev/null 2>&1
R=/edios/repo/edios
X="--repository $R"

echo "== Signatur"
if apk $X update 2>&1 | grep -qi 'untrusted'; then ok "ohne Schluessel: UNTRUSTED"; else bad "ohne Schluessel nicht abgelehnt"; fi
apk $X add -q edios-keyring >/dev/null 2>&1 && bad "ohne Schluessel installiert" || ok "ohne Schluessel keine Installation"
cp /edios/src/pubkeys/edios-repo.rsa.pub /etc/apk/keys/
for f in "$R"/x86_64/*.apk; do apk verify "$f" >/dev/null 2>&1 && ok "apk verify ${f##*/}" || bad "apk verify ${f##*/}"; done
# falsch signierte Kopie (Wegwerf-Schluessel mit GLEICHEM Namen)
mkdir -p /tmp/fake /tmp/fk
openssl genrsa -out /tmp/fk/edios-repo.rsa 2048 2>/dev/null
openssl rsa -in /tmp/fk/edios-repo.rsa -pubout -out /tmp/fk/edios-repo.rsa.pub 2>/dev/null
f="$(ls "$R"/x86_64/edios-base-*.apk | head -n1)"
# Kopie mit dem falschen Schluessel signieren (abuild-sign setzt eine neue Signatur davor)
cp "$f" /tmp/fake/edios-base-falsch.apk
abuild-sign -k /tmp/fk/edios-repo.rsa -p edios-repo.rsa.pub /tmp/fake/edios-base-falsch.apk >/dev/null 2>&1
if apk verify /tmp/fake/edios-base-falsch.apk 2>&1 | grep -qi 'BAD\|UNTRUSTED\|error'; then ok "falsch signierte Kopie: abgelehnt ($(apk verify /tmp/fake/edios-base-falsch.apk 2>&1 | head -n1))"
else bad "falsch signierte Kopie wurde akzeptiert"; fi

echo "== Installation"
mkdir -p /etc/edios/dconf-src
printf "[org/gnome/desktop/input-sources]\nsources=[('xkb', 'de')]\n" > /etc/edios/dconf-src/01-generated.ini
if apk $X add -q edios-keyring edios-base edios-theme edios-apps >/tmp/add.log 2>&1; then ok "edios-keyring edios-base edios-theme edios-apps installiert"; else bad "Installation"; cat /tmp/add.log; fi
apk info -e edios-keyring edios-base edios-theme edios-apps | tr '\n' ' '; echo
[ -f /etc/dconf/db/local ] && ok "post-install: /etc/dconf/db/local erzeugt" || bad "dconf db fehlt"
cmp -s /usr/share/edios/dbus/org.gnome.Terminal.service /usr/local/share/dbus-1/services/org.gnome.Terminal.service \
	&& ok "post-install: D-Bus-Override in /usr/local" || bad "D-Bus-Override fehlt"
[ -x /usr/bin/edios-update ] && [ -x /usr/bin/edios-apps ] && [ -x /usr/libexec/edios-sprache-root ] && [ -f /usr/share/edios/i18n.sh ] \
	&& ok "Programme da" || bad "Dateien fehlen"
owner="$(apk info --who-owns /etc/apk/keys/edios-repo.rsa.pub 2>/dev/null | sed 's/.* by //')"
case "$owner" in edios-keyring-*) ok "Schluessel gehoert zu $owner" ;; *) bad "Schluessel gehoert zu '$owner'" ;; esac
grep -qx "$URL" /etc/apk/repositories.d/edios.list && ok "edios.list ab Werk eingeschaltet: $URL" || bad "edios.list ohne URL"
find / -name '*.apk-new' -not -path '/proc/*' 2>/dev/null | grep -q . && bad ".apk-new gefunden" || ok "keine .apk-new"

echo "== Update-Faelle (edios-update-root)"
cp /etc/apk/repositories.d/edios.list /tmp/edios.list.orig
echo "http://127.0.0.1:9/edios" > /etc/apk/repositories.d/edios.list
/usr/libexec/edios-update-root >/tmp/b.log 2>&1; rc=$?
[ "$rc" = 0 ] && grep -q '^@@HINWEIS edios-weg' /tmp/b.log && ok "B: ediOS-Quelle weg -> RC 0 mit Hinweis" || { bad "B: RC $rc"; tail -5 /tmp/b.log; }
cp /etc/apk/repositories /tmp/repos.bak
printf 'http://127.0.0.1:9/alpine/main\n' > /etc/apk/repositories
/usr/libexec/edios-update-root >/tmp/d.log 2>&1; rc=$?
[ "$rc" = 10 ] && ok "D: alles weg -> Fehler 10" || { bad "D: RC $rc"; tail -5 /tmp/d.log; }
cp /tmp/repos.bak /etc/apk/repositories
cp /tmp/edios.list.orig /etc/apk/repositories.d/edios.list

echo "== apk del edios-base (A8)"
apk del -q edios-apps edios-theme edios-base >/dev/null 2>&1 && ok "edios-base entfernt" || bad "Entfernen"
[ ! -e /usr/local/share/dbus-1/services/org.gnome.Terminal.service ] && ok "pre-deinstall: D-Bus-Override entfernt" || bad "D-Bus-Override noch da"
[ -f /etc/apk/keys/edios-repo.rsa.pub ] && ok "Schluessel bleibt (edios-keyring)" || bad "Schluessel weg"
[ -f /etc/apk/repositories.d/edios.list ] && ok "Paketquelle bleibt" || bad "edios.list weg"
if apk $X update 2>&1 | grep -qi untrusted; then bad "Quelle nach apk del edios-base UNTRUSTED"; else ok "Quelle weiter vertrauenswuerdig"; fi
apk $X add -q edios-base >/tmp/re.log 2>&1 && ok "edios-base laesst sich wieder installieren ($(apk info -v edios-base 2>/dev/null | head -n1))" || { bad "Neuinstallation"; tail -3 /tmp/re.log; }
[ "$FAIL" = 0 ] && echo "ERGEBNIS: alles OK" || { echo "ERGEBNIS: FEHLER"; exit 1; }
EOS
