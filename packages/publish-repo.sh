#!/bin/sh
# ediOS: signiertes Paket-Repository veroeffentlichen (GitHub Pages, Repo "edios-repo", Branch gh-pages).
#
#   GPL-3.0-or-later. Erstmals benutzt am 2026-11-14.
#
#   ./packages/publish-repo.sh --pruefen      nur pruefen und anzeigen, was hochgeladen wuerde (aendert nichts)
#   ./packages/publish-repo.sh --hochladen    wirklich veroeffentlichen (fragt vorher noch einmal nach "JA")
#   EDIOS_OHNE_BAU=1 ./packages/publish-repo.sh ...   Pakete aus repo/ (letzter ISO-Bau) statt neu zu bauen
#
# Ablauf: build-repo.sh -> apk verify -> Inhalt von repo/edios/x86_64 in einen Checkout von
# edios-repo (gh-pages) unter v3.24/edios/x86_64 kopieren -> commit -> push.
# Alte Paketversionen bleiben liegen (nichts wird geloescht). Aeltere Testpakete (4.x) haben eine HOEHERE
# Versionsnummer als die aktuelle Reihe 1.x; sie bleiben als Dateien liegen, kommen aber nicht in den Index.
# Ausserdem landen .nojekyll und eine kleine Startseite (packages/edios-repo-index.html) im Repo.
# Signiert wird nur lokal; der private
# Schluessel verlaesst diesen Rechner nie (nicht in GitHub Actions/Secrets).
# Voraussetzungen (einmalig, von Hand):
#   - GitHub-Repo <konto>/edios-repo existiert (oeffentlich, damit apk ohne Anmeldung laden kann)
#   - Branch gh-pages, GitHub Pages fuer gh-pages eingeschaltet
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="$(dirname "$HERE")"
. "$PROJ/config.sh"
KONTO="${EDIOS_GH_KONTO:-edululilar-sketch}"
PAGES_REPO="${EDIOS_PAGES_REPO:-$KONTO/edios-repo}"
ZIELPFAD="$ALPINE_BRANCH/edios/$ARCH"
CHECKOUT="$PROJ/cache/edios-repo-pages"
SRC="$PROJ/repo/edios/$ARCH"

mode="${1:-}"
case "$mode" in --pruefen|--hochladen) ;; *) sed -n '2,20p' "$0"; exit 64 ;; esac

# 1. Pakete frisch bauen und pruefen (build-repo.sh prueft apk verify + Index-Signatur).
#    EDIOS_OHNE_BAU=1: genau die Pakete aus repo/ nehmen, die der letzte ISO-Bau erzeugt hat (gleiche Dateien
#    wie auf der ISO).
if [ "${EDIOS_OHNE_BAU:-0}" != 1 ]; then
	"$PROJ/packages/build-repo.sh"
fi
[ -f "$SRC/APKINDEX.tar.gz" ] || { echo "Kein APKINDEX in $SRC" >&2; exit 1; }

# 2. Sicherheitspruefungen: nur .apk und APKINDEX, kein privater Schluessel
for f in "$SRC"/*; do
	case "${f##*/}" in *.apk|APKINDEX.tar.gz) ;; *) echo "Unerwartete Datei: $f" >&2; exit 1 ;; esac
	if tar -xzOf "$f" 2>/dev/null | grep -aq "PRIVATE KEY"; then echo "PRIVATE KEY in $f - Abbruch" >&2; exit 1; fi
done
if git -C "$PROJ" grep -qE -- '-{5}BEGIN [A-Z ]*PRIVATE KEY-{5}' . ; then
	echo "Im Quelltext-Git steht ein privater Schluessel - Abbruch" >&2; exit 1
fi

echo "Wuerde nach https://github.com/$PAGES_REPO (gh-pages) unter $ZIELPFAD hochladen:"
(cd "$SRC" && ls -l)
URL="https://${KONTO}.github.io/${PAGES_REPO#*/}/$ALPINE_BRANCH/edios"
echo "Spaetere Paketquelle (fuer /etc/apk/repositories.d/edios.list): $URL"
[ "$mode" = --hochladen ] || { echo "(nur geprueft, nichts hochgeladen)"; exit 0; }

printf 'Wirklich veroeffentlichen? Dann JA eintippen: '
read -r ok
[ "$ok" = JA ] || { echo "Abgebrochen."; exit 1; }

# Commits im oeffentlichen Repo ohne persoenliche Kennung
export GIT_AUTHOR_NAME=ediOS GIT_AUTHOR_EMAIL=build@edios.local GIT_COMMITTER_NAME=ediOS GIT_COMMITTER_EMAIL=build@edios.local

# 3. Checkout von gh-pages holen/aktualisieren
if [ ! -d "$CHECKOUT/.git" ]; then
	git clone --branch gh-pages "https://github.com/$PAGES_REPO.git" "$CHECKOUT"
else
	git -C "$CHECKOUT" fetch origin gh-pages && git -C "$CHECKOUT" checkout -q gh-pages \
		&& git -C "$CHECKOUT" reset -q --hard origin/gh-pages
fi
mkdir -p "$CHECKOUT/$ZIELPFAD"
# Aeltere Testpakete (4.x) bleiben als Dateien liegen (nichts wird geloescht), kommen aber NICHT in den Index:
# sie haben eine hoehere Versionsnummer als 1.x, apk wuerde sie sonst bevorzugen.
# neue Pakete dazu (vorhandene Versionen werden NIE ueberschrieben: gleiche Version = gleiche Datei)
for f in "$SRC"/*.apk; do
	n="${f##*/}"
	if [ -f "$CHECKOUT/$ZIELPFAD/$n" ] && ! cmp -s "$f" "$CHECKOUT/$ZIELPFAD/$n"; then
		echo "FEHLER: $n gibt es schon mit anderem Inhalt. pkgrel erhoehen!" >&2; exit 1
	fi
	cp "$f" "$CHECKOUT/$ZIELPFAD/"
done
# Index ueber ALLE Pakete im Zielordner neu erzeugen und signieren (im Container, Schluessel nur lesend)
docker run --rm -u "$(id -u):$(id -g)" -v "$CHECKOUT/$ZIELPFAD:/r" -v "${EDIOS_KEYS:-$HOME/ediOS-keys}:/keys:ro" \
	edios-builder:3.24 sh -c '
		set -e; cd /r
		# nur der oeffentliche Schluessel als Vertrauensbasis, damit apk index die Paket-Signaturen prueft
		mkdir -p /tmp/pubkeys && cp /keys/edios-repo.rsa.pub /tmp/pubkeys/
		apk index --keys-dir /tmp/pubkeys --rewrite-arch '"$ARCH"' -o APKINDEX.tar.gz.neu $(ls ./*.apk | grep -v -- "-4\.[0-9.]*-r[0-9]*\.apk$")
		mv APKINDEX.tar.gz.neu APKINDEX.tar.gz
		abuild-sign -k /keys/edios-repo.rsa -p edios-repo.rsa.pub APKINDEX.tar.gz'
touch "$CHECKOUT/.nojekyll"
cp "$HERE/edios-repo-index.html" "$CHECKOUT/index.html"
# Nur erlaubte Dateien im Checkout (keine Schluessel, kein Quelltext)
bad="$(cd "$CHECKOUT" && git ls-files -o -c --exclude-standard | grep -v -E "^(\.nojekyll|index\.html|$ZIELPFAD/(APKINDEX\.tar\.gz|[A-Za-z0-9._+-]+\.apk))$" || true)"
[ -z "$bad" ] || { echo "Unerwartete Dateien im Pages-Repo: $bad" >&2; exit 1; }
git -C "$CHECKOUT" add -A
git -C "$CHECKOUT" commit -q -m "ediOS-Pakete $(date +%Y-%m-%d)"
git -C "$CHECKOUT" push origin gh-pages
echo "Veroeffentlicht: $URL"
