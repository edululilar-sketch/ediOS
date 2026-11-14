#!/bin/sh
# ediOS ISO bauen:  ./build.sh        (GPL-3.0-or-later)
# Baut im Docker-Container (Alpine 3.24) als Benutzer 1000. Ergebnis: out/edios-<version>-x86_64.iso
#
# Schluessel: ~/ediOS-keys (oder EDIOS_KEYS=...) wird NUR LESEND eingehaengt und nie ins Projekt kopiert.
#   edios-repo.rsa  signiert Pakete, Paketindex und modloop (offizieller Bau)
#   edios-mok.key   signiert GRUB und Kernel fuer Secure Boot
# Ohne diese Schluessel (z. B. wer das oeffentliche Repo baut): INOFFIZIELLER Bau. Die Pakete werden mit einem
# lokalen Wegwerf-Schluessel (cache/local-keys/edios-lokal.rsa) signiert, GRUB und Kernel sind unsigniert
# (die ISO startet dann nur mit Secure Boot AUS). ediOS-Updates aus dem Internet funktionieren trotzdem,
# weil der oeffentliche ediOS-Schluessel (src/pubkeys) im Paket edios-keyring liegt.
# Log: build-<version>.log (nicht in Git).
set -eu
P="$(cd "$(dirname "$0")" && pwd)"
KEYS="${EDIOS_KEYS:-$HOME/ediOS-keys}"
IMAGE=edios-builder:3.24
. "$P/config.sh"
LOG="$P/build-$EDIOS_FILEVER.log"

# Alpine-mkimage-Skripte (aports, Zweig 3.24-stable) einmalig holen
if [ ! -f "$P/cache/aports/scripts/mkimage.sh" ]; then
	mkdir -p "$P/cache/aports"
	git -C "$P/cache/aports" init -q
	git -C "$P/cache/aports" remote add origin https://gitlab.alpinelinux.org/alpine/aports.git 2>/dev/null || true
	git -C "$P/cache/aports" sparse-checkout set scripts
	git -C "$P/cache/aports" fetch -q --depth 1 --filter=blob:none origin 3.24-stable
	git -C "$P/cache/aports" checkout -q FETCH_HEAD
fi

KEYNAME=edios-repo.rsa
if [ -f "$KEYS/edios-repo.rsa" ]; then
	# offizieller Bau: der private Schluessel muss zum oeffentlichen im Repo passen
	cmp -s "$KEYS/edios-repo.rsa.pub" "$P/src/pubkeys/edios-repo.rsa.pub" || {
		echo "FEHLER: $KEYS/edios-repo.rsa.pub passt nicht zu src/pubkeys/edios-repo.rsa.pub" >&2; exit 1; }
else
	echo "HINWEIS: Kein ediOS-Schluessel in $KEYS -> inoffizieller, unsignierter Bau (Secure Boot AUS noetig)."
	KEYS="$P/cache/local-keys"; KEYNAME=edios-lokal.rsa
	if [ ! -f "$KEYS/$KEYNAME" ]; then
		mkdir -p "$KEYS"; chmod 700 "$KEYS"
		( umask 077; openssl genrsa -out "$KEYS/$KEYNAME" 4096 2>/dev/null )
		openssl rsa -in "$KEYS/$KEYNAME" -pubout -out "$KEYS/$KEYNAME.pub" 2>/dev/null
	fi
fi

docker build -q -t "$IMAGE" --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" "$P/build" >/dev/null

echo "ediOS $EDIOS_VERSION wird gebaut, Log: $LOG"
start="$(date +%s)"
set +e
docker run --rm -u "$(id -u):$(id -g)" --group-add 300 -e EDIOS_REPO_KEYNAME="$KEYNAME" \
	-v "$P:/edios" -v "$KEYS:/keys:ro" \
	"$IMAGE" sh /edios/build/inner.sh 2>&1 | tee "$LOG"
rc=$?
set -e
# Status von docker (nicht von tee)
grep -q '^=== .*FERTIG:' "$LOG" || rc=1
d=$(( $(date +%s) - start ))
echo "Bauzeit: $((d / 60)) min $((d % 60)) s" | tee -a "$LOG"
exit "$rc"
