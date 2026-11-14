#!/bin/sh
# ediOS: installiert Dateien laut files.map.
#   install-map.sh ZIELWURZEL GRUPPE...      z. B. install-map.sh "$pkgdir" base
#   install-map.sh --list GRUPPE...          nur die Zielpfade ausgeben
# Benutzt vom Overlay (genapkovl-edios.sh) und von den APKBUILDs, damit es nur EINE Liste gibt.
set -eu
S="$(cd "$(dirname "$0")" && pwd)"
MAP="$S/files.map"
list=no
[ "${1:-}" != "--list" ] || { list=yes; shift; }
if [ "$list" = no ]; then DEST="${1:?Zielwurzel}"; shift; fi
[ $# -gt 0 ] || { echo "install-map: keine Gruppe angegeben" >&2; exit 64; }

n=0
for g in "$@"; do
	grep -q "^$g[[:space:]]" "$MAP" || { echo "install-map: unbekannte Gruppe $g" >&2; exit 1; }
	# shellcheck disable=SC2034
	grep "^$g[[:space:]]" "$MAP" | while read -r grp mode src dst; do
		if [ "$list" = yes ]; then echo "$dst"; continue; fi
		[ -f "$S/$src" ] || { echo "install-map: Quelle fehlt: src/$src" >&2; exit 1; }
		install -D -m "$mode" "$S/$src" "$DEST$dst"
	done
	n=$((n + 1))
done
