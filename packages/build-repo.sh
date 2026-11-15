#!/bin/sh
# ediOS: eigene apk-Pakete bauen und als signiertes Repository ablegen.
#
#   ./packages/build-repo.sh                    alle Pakete in packages/*/APKBUILD bauen (Container, Benutzer 1000)
#   ./packages/build-repo.sh edios-base ...     nur diese Pakete
#   ./packages/build-repo.sh --neuer-schluessel neuen Repo-Schluessel anlegen (ueberschreibt NIE einen vorhandenen)
#
# Ergebnis: repo/edios/x86_64/*.apk + APKINDEX.tar.gz, signiert mit ~/ediOS-keys/edios-repo.rsa
# (bzw. im inoffiziellen Bau ohne Schluessel mit cache/local-keys/edios-lokal.rsa, siehe build.sh). GPL-3.0-or-later
# Der Schluesselordner wird nur lesend in den Container gehaengt. Die Paketdateien werden aus src/
# kopiert (packages/.build/), es gibt keine zweite Kopie im Projekt.
# Intern: "--inner" (im Container, auch von build/inner.sh benutzt).
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="$(dirname "$HERE")"
KEYS="${EDIOS_KEYS:-$HOME/ediOS-keys}"
KEYNAME="${EDIOS_REPO_KEYNAME:-edios-repo.rsa}"
IMAGE=edios-builder:3.24

if [ "${1:-}" = "--neuer-schluessel" ]; then
	umask 077
	mkdir -p "$KEYS"; chmod 700 "$KEYS"
	if [ -e "$KEYS/$KEYNAME" ] || [ -e "$KEYS/$KEYNAME.pub" ]; then
		echo "Es gibt schon einen Repo-Schluessel in $KEYS - nichts geaendert." >&2; exit 1
	fi
	openssl genrsa -out "$KEYS/$KEYNAME" 4096 2>/dev/null
	openssl rsa -in "$KEYS/$KEYNAME" -pubout -out "$KEYS/$KEYNAME.pub" 2>/dev/null
	chmod 600 "$KEYS/$KEYNAME" "$KEYS/$KEYNAME.pub"
	echo "Neuer Repo-Schluessel: $KEYS/$KEYNAME (+ .pub). Auf die Sicherungs-Sticks kopieren!"
	exit 0
fi

if [ "${1:-}" != "--inner" ]; then
	[ -f "$KEYS/$KEYNAME" ] || { echo "Repo-Schluessel fehlt: $KEYS/$KEYNAME (anlegen mit --neuer-schluessel)" >&2; exit 1; }
	cmp -s "$KEYS/$KEYNAME.pub" "$PROJ/src/pubkeys/edios-repo.rsa.pub" || {
		echo "Repo-Schluessel $KEYS/$KEYNAME.pub passt nicht zu src/pubkeys/edios-repo.rsa.pub" >&2; exit 1; }
	docker build -q -t "$IMAGE" --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" "$PROJ/build" >/dev/null
	exec docker run --rm -u "$(id -u):$(id -g)" --group-add 300 -e EDIOS_REPO_KEYNAME="$KEYNAME" \
		-v "$PROJ:/edios" -v "$KEYS:/keys:ro" \
		"$IMAGE" sh /edios/packages/build-repo.sh --inner "$@"
fi

# ======================= im Container =======================
shift
P=/edios
. "$P/config.sh"
B="$P/packages/.build/edios"           # Ordnername "edios" = Name des Repos fuer abuild
REPODEST="$P/repo"
[ -f /keys/$KEYNAME ] || { echo "build-repo: /keys/$KEYNAME fehlt" >&2; exit 1; }

# abuild: signiert mit dem ediOS-Repo-Schluessel; Container vertraut dem oeffentlichen Teil
mkdir -p "$HOME/.abuild"
cat > "$HOME/.abuild/abuild.conf" <<EOF
PACKAGER="ediOS <build@edios.local>"
PACKAGER_PRIVKEY="/keys/$KEYNAME"
REPODEST="$REPODEST"
SRCDEST="$P/cache/distfiles"
EOF
mkdir -p "$P/cache/distfiles"
doas cp "/keys/$KEYNAME.pub" "/etc/apk/keys/$KEYNAME.pub"
doas chmod 644 "/etc/apk/keys/$KEYNAME.pub"
doas apk update -q >/dev/null       # Paketindex fuer die Abhaengigkeiten (Image hat keinen Cache)

pkgs="$*"
# edios-keyring zuerst: edios-base haengt davon ab (abuild installiert die Abhaengigkeiten aus dem lokalen Repo)
[ -n "$pkgs" ] || pkgs="edios-keyring $(cd "$P/packages" && for d in */APKBUILD; do d="${d%/APKBUILD}"; [ "$d" = edios-keyring ] || printf '%s ' "$d"; done)"

for p in $pkgs; do
	[ -f "$P/packages/$p/APKBUILD" ] || { echo "build-repo: unbekanntes Paket $p" >&2; exit 1; }
	echo "build-repo: === $p ==="
	rm -rf "${B:?}/$p"
	mkdir -p "$B/$p/edios-src"
	cp -a "$P/packages/$p/." "$B/$p/"
	cp -a "$P/src/files" "$P/src/icons" "$P/src/pubkeys" "$P/src/iso-codes-de" "$P/src/files.map" "$P/src/install-map.sh" "$B/$p/edios-src/"
	# inoffizieller Bau: den lokalen oeffentlichen Schluessel zusaetzlich mitliefern (nie den privaten)
	[ "$KEYNAME" = edios-repo.rsa ] || cp "/keys/$KEYNAME.pub" "$B/$p/edios-src/pubkeys/$KEYNAME.pub"
	find "$B/$p/edios-src" -name __pycache__ -type d -exec rm -rf {} +
	# Nur Pakete mit makedepends brauchen beim Bau weitere Pakete (-r). Die anderen ohne (-d): sonst wuerde
	# abuild z. B. edios-keyring installieren und danach samt Repo-Schluessel wieder entfernen.
	if grep -q '^makedepends=' "$B/$p/APKBUILD"; then mode=-r; else mode=-d; fi
	(cd "$B/$p" && abuild $mode) || { echo "build-repo: $p FEHLGESCHLAGEN" >&2; exit 1; }
	doas install -m644 "/keys/$KEYNAME.pub" "/etc/apk/keys/$KEYNAME.pub"
done

# Index pruefen: jede Datei muss mit dem Repo-Schluessel verifizierbar sein
R="$REPODEST/edios/$ARCH"
[ -f "$R/APKINDEX.tar.gz" ] || { echo "build-repo: kein APKINDEX" >&2; exit 1; }
for f in "$R"/*.apk; do
	apk verify --keys-dir /etc/apk/keys "$f" >/dev/null || { echo "build-repo: apk verify FEHLER $f" >&2; exit 1; }
done
tar -tzf "$R/APKINDEX.tar.gz" | grep -q "^.SIGN.RSA.*$KEYNAME.pub$" || { echo "build-repo: Index nicht mit $KEYNAME signiert" >&2; exit 1; }
echo "build-repo: OK, $(ls "$R"/*.apk | wc -l) Pakete in repo/edios/$ARCH, alle mit $KEYNAME verifiziert:"
(cd "$R" && ls -1 ./*.apk | sed 's|^\./|  |')
