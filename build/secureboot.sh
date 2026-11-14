#!/bin/sh
# ediOS Secure Boot: bereitet die Startkette vor (laeuft im Bau-Container, VOR mkimage). GPL-3.0-or-later
#   Firmware -> shimx64.efi (Debian, Microsoft-signiert) -> grubx64.efi (ediOS-signiert) -> vmlinuz-lts (ediOS-signiert)
# Ergebnis in $1 (Standard $WORK/sb): genau die Dateien, die spaeter unter /usr/share/edios/secureboot liegen.
# Ohne /keys/edios-mok.key wird nichts signiert: die ISO startet dann nur mit Secure Boot AUS.
set -eu
P=/edios
. "$P/config.sh"
OUT="${1:?Zielordner}"
DL="$P/cache/dl"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
# Zielordner frisch anlegen (ganzer Ordner, keine Platzhalter)
rm -rf "${OUT:?}"
mkdir -p "$OUT" "$DL"

KEY=/keys/edios-mok.key
CRT=/keys/edios-mok.crt
DER=/keys/edios-mok.der
SIGN=no
if [ -f "$KEY" ] && [ -f "$CRT" ] && [ -f "$DER" ]; then SIGN=yes; fi
echo "secureboot: signieren = $SIGN"
if [ "$SIGN" = yes ] && openssl x509 -in "$CRT" -noout -ext extendedKeyUsage 2>/dev/null | grep -q '2312\.16\.1\.2'; then
	# shim lehnt Bootloader ab, die mit einem "nur Kernelmodule"-Zertifikat (modsign-EKU) signiert sind
	echo "secureboot: FEHLER - MOK-Zertifikat hat EKU 1.3.6.1.4.1.2312.16.1.2 (modsign); shim wuerde GRUB ablehnen" >&2
	exit 1
fi

check() {   # DATEI SHA256
	h="$(sha256sum "$1" | cut -d' ' -f1)"
	[ "$h" = "$2" ] || { echo "secureboot: FEHLER Pruefsumme ${1##*/}: $h (erwartet $2)" >&2; exit 1; }
}

# --- shim + MOK-Manager (Debian) ---
for d in "$SHIM_DEB:$SHIM_DEB_SHA256" "$SHIM_HELPERS_DEB:$SHIM_HELPERS_DEB_SHA256"; do
	path="${d%%:*}"; sum="${d##*:}"; f="$DL/${path##*/}"
	[ -s "$f" ] || curl -fsSL --retry 3 -o "$f" "$DEBIAN_POOL/$path"
	check "$f" "$sum"
	mkdir -p "$T/ar.$sum" "$T/deb"
	(cd "$T/ar.$sum" && ar x "$f")
	for t in "$T/ar.$sum"/data.tar.xz "$T/ar.$sum"/data.tar.zst "$T/ar.$sum"/data.tar.gz; do
		[ ! -f "$t" ] || tar -C "$T/deb" -xf "$t"
	done
done
cp "$T/deb/usr/lib/shim/shimx64.efi.signed" "$OUT/shimx64.efi"
cp "$T/deb/usr/lib/shim/mmx64.efi.signed" "$OUT/mmx64.efi"
cp "$T/deb/usr/lib/shim/fbx64.efi.signed" "$OUT/fbx64.efi"
check "$OUT/shimx64.efi" "$SHIMX64_SHA256"
check "$OUT/mmx64.efi" "$MMX64_SHA256"

# --- Alpine-Pakete (feste Versionen) holen ---
REPOS="$T/repositories"
printf '%s/%s/main\n%s/%s/community\n' "$MIRROR" "$ALPINE_BRANCH" "$MIRROR" "$ALPINE_BRANCH" > "$REPOS"
mkdir -p "$DL/apk"
# apk fetch (apk-tools 3) kennt keine Versionsangabe: Paket holen, dann die Version pruefen.
for nv in "grub-efi $GRUB_VERSION" "linux-lts $KERNEL_VERSION"; do
	n="${nv% *}"; v="${nv#* }"; p="$n-$v"
	if [ ! -s "$DL/apk/$p.apk" ]; then
		mkdir -p "$T/fetch" "$T/apkcache"
		apk --repositories-file "$REPOS" --cache-dir "$T/apkcache" --update-cache fetch -o "$T/fetch" "$n" >/dev/null
		[ -s "$T/fetch/$p.apk" ] || { echo "secureboot: $p nicht auf dem Mirror (dort: $(ls "$T/fetch")) - config.sh pruefen" >&2; exit 1; }
		mv "$T/fetch/$p.apk" "$DL/apk/$p.apk"
	fi
	apk verify "$DL/apk/$p.apk" >/dev/null || { echo "secureboot: apk verify $p FEHLER" >&2; exit 1; }
done
mkdir -p "$T/grub" "$T/kernel"
tar -C "$T/grub" -xzf "$DL/apk/grub-efi-$GRUB_VERSION.apk" usr/lib/grub 2>/dev/null
tar -C "$T/kernel" -xzf "$DL/apk/linux-lts-$KERNEL_VERSION.apk" boot/vmlinuz-lts 2>/dev/null

# --- GRUB: eigenes EFI-Image, alle Module fest eingebaut, SBAT grub,5 ---
cat > "$T/sbat.csv" <<EOF
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
grub,$GRUB_SBAT_GENERATION,Free Software Foundation,grub,${GRUB_VERSION%-r*},https://www.gnu.org/software/grub/
grub.edios,$GRUB_SBAT_EDIOS,ediOS,grub,$GRUB_VERSION,$EDIOS_URL
EOF
# Eingebaute Startkonfiguration: zuerst grub.cfg neben grubx64.efi (EFI-Partition), sonst die ISO suchen.
cat > "$T/early.cfg" <<EOF
set edios_efidir=\$cmdpath
export edios_efidir
if [ -f \$cmdpath/grub.cfg ]; then
	configfile \$cmdpath/grub.cfg
fi
search --no-floppy --set=root --label "$EDIOS_VOLID"
set prefix=(\$root)/boot/grub
configfile (\$root)/boot/grub/grub.cfg
EOF
# shellcheck disable=SC2086
grub-mkimage --directory="$T/grub/usr/lib/grub/x86_64-efi" --format=x86_64-efi \
	--prefix="" --config="$T/early.cfg" --sbat="$T/sbat.csv" \
	--output="$T/grubx64.efi" $GRUB_SB_MODULES
objdump -h "$T/grubx64.efi" | grep -q '\.sbat' || { echo "secureboot: .sbat fehlt im GRUB-Image" >&2; exit 1; }

# --- Kernel ---
cp "$T/kernel/boot/vmlinuz-lts" "$T/vmlinuz-lts.unsigned"
sha256sum < "$T/vmlinuz-lts.unsigned" | cut -d' ' -f1 > "$OUT/vmlinuz-lts.unsigned.sha256"
echo "$KERNEL_VERSION" > "$OUT/kernel-version"

if [ "$SIGN" = yes ]; then
	sbsign --key "$KEY" --cert "$CRT" --output "$OUT/grubx64.efi" "$T/grubx64.efi" 2>&1 | grep -v '^Signing' || true
	sbsign --key "$KEY" --cert "$CRT" --output "$OUT/vmlinuz-lts" "$T/vmlinuz-lts.unsigned" 2>&1 | grep -v '^Signing' || true
	for f in grubx64.efi vmlinuz-lts; do
		sbverify --cert "$CRT" "$OUT/$f" >/dev/null 2>&1 || { echo "secureboot: sbverify FEHLER $f" >&2; exit 1; }
	done
	install -m644 "$DER" "$OUT/edios-mok.der"
	openssl x509 -inform DER -in "$DER" -noout -fingerprint -sha256 | sed 's/^.*=//' > "$OUT/edios-mok.sha256"
	subj="$(openssl x509 -inform DER -in "$DER" -noout -subject | sed 's/^subject=//')"
else
	cp "$T/grubx64.efi" "$OUT/grubx64.efi"
	cp "$T/vmlinuz-lts.unsigned" "$OUT/vmlinuz-lts"
	subj="(kein ediOS-Schluessel beim Bau: nicht signiert)"
fi
sha256sum < "$OUT/vmlinuz-lts" | cut -d' ' -f1 > "$OUT/vmlinuz-lts.signed.sha256"

cp "$P/src/files/grub-hilfe.cfg" "$P/src/files/grub-extra.cfg" "$OUT/"
cp "$EDIOS_DOC/LIESMICH.txt" "$EDIOS_DOC/README.txt" "$OUT/"
cat > "$OUT/VERSIONEN.txt" <<EOF
shim:   Debian shim-signed $(v="${SHIM_DEB##*shim-signed_}"; echo "${v%_amd64.deb}") (shimx64.efi, Microsoft UEFI CA 2011 + 2023)
        Debian shim-helpers-amd64-signed $(v="${SHIM_HELPERS_DEB##*signed_}"; echo "${v%_amd64.deb}") (mmx64.efi)
GRUB:   Alpine grub-efi $GRUB_VERSION, SBAT grub,$GRUB_SBAT_GENERATION / grub.edios,$GRUB_SBAT_EDIOS, signiert mit dem ediOS-MOK
Kernel: Alpine linux-lts $KERNEL_VERSION, signiert mit dem ediOS-MOK
MOK:    $subj
        SHA-256 $(cat "$OUT/edios-mok.sha256" 2>/dev/null || echo -)
EOF
echo "$SIGN" > "$OUT/.signed"
echo "secureboot: fertig ($(ls "$OUT" | tr '\n' ' '))"
