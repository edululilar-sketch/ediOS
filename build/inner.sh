#!/bin/sh
# ediOS ISO-Bau, Teil im Container (Alpine 3.24, Benutzer 1000). Gestartet von build.sh. GPL-3.0-or-later
#   /edios  = Projektordner     /keys = Schluesselordner (nur lesend)
#   EDIOS_REPO_KEYNAME = edios-repo.rsa (offiziell) oder edios-lokal.rsa (inoffizieller Bau ohne Schluessel)
set -eu
P=/edios
. "$P/config.sh"
export EDIOS_P="$P"
KEYNAME="${EDIOS_REPO_KEYNAME:-edios-repo.rsa}"
export EDIOS_REPO_KEYNAME="$KEYNAME"
W="$P/cache/work"                 # Zwischenergebnisse dieses Baus
MKW="$P/cache/mkimage"            # mkimage-Arbeitsordner; apkroot-$ARCH darin = Paket-Cache
OUT="$P/out"
mkdir -p "$W" "$MKW" "$OUT"
t0="$(date +%s)"
say() { echo "=== [$(( $(date +%s) - t0 ))s] $*"; }

# --- 0. Schluessel ---
[ -f "/keys/$KEYNAME" ] && [ -f "/keys/$KEYNAME.pub" ] || {
	echo "FEHLER: /keys/$KEYNAME fehlt (signiert Pakete, Paketindex und modloop)." >&2; exit 1; }
[ -f /keys/edios-mok.key ] || echo "WARNUNG: kein MOK-Schluessel - ISO startet nur mit Secure Boot AUS."
[ "$KEYNAME" = edios-repo.rsa ] || echo "WARNUNG: inoffizieller Bau (Paket-Schluessel $KEYNAME)."

# --- 1. eigene Pakete (signiertes lokales Repo) ---
say "Pakete bauen"
rm -rf "$P/repo"
sh "$P/packages/build-repo.sh" --inner $EDIOS_PACKAGES

# --- 2. Upstream-Teile ---
say "Assets"
sh "$P/build/assets.sh"

# --- Anleitungen fuer die ISO (mit dem echten Dateinamen) ---
ISO="$OUT/edios-$EDIOS_FILEVER-$ARCH.iso"
export EDIOS_DOC="$W/doc"
rm -rf "$EDIOS_DOC"; mkdir -p "$EDIOS_DOC"
for f in LIESMICH.txt README.txt; do
	sed "s/@ISO@/${ISO##*/}/g; s/@VERSION@/$EDIOS_VERSION/g; s|@URL@|$EDIOS_URL|g" "$P/iso/$f" > "$EDIOS_DOC/$f"
done

# --- 3. Secure Boot ---
say "Secure Boot vorbereiten"
export EDIOS_SB="$W/sb"
sh "$P/build/secureboot.sh" "$EDIOS_SB"

# --- 4. Paketlisten ---
FIRMWARE="$(grep -v '^#' "$P/src/files/firmware.list" | tr '\n' ' ')"
export EDIOS_WORLD="$W/world"
# Live-System: Desktop + ediOS-Pakete + Installer-Werkzeuge (Kernel/Firmware kommen aus dem modloop)
printf '%s\n' $PACKAGES $EDIOS_PACKAGES $LIVE_PACKAGES | sort -u > "$EDIOS_WORLD"
# Auf der ISO zusaetzlich: Kernel, Firmware, Bootloader -> der Installer braucht kein Internet
export EDIOS_APKS="$W/apks"
printf '%s\n' $PACKAGES $EDIOS_PACKAGES $LIVE_PACKAGES $FIRMWARE linux-lts mkinitfs grub grub-efi \
	efibootmgr e2fsprogs dosfstools sfdisk | sort -u > "$EDIOS_APKS"
export EDIOS_ASSETS="$P/cache/assets/root"
export EDIOS_REPO_PUB="/keys/$KEYNAME.pub"
export EDIOS_OVL_GROUPS              # aus config.sh
export EDIOS_VERSION EDIOS_FILEVER EDIOS_VOLID KERNEL_VERSION EDIOS_PKGVER EDIOS_URL

# --- 5. mkimage ---
say "ISO bauen (mkimage)"
# abuild-Einstellungen: modloop und /apks-Index mit dem Repo-Schluessel signieren
mkdir -p "$HOME/.abuild" "$HOME/.mkimage"
cat > "$HOME/.abuild/abuild.conf" <<EOF
PACKAGER="ediOS <build@edios.local>"
PACKAGER_PRIVKEY="/keys/$KEYNAME"
EOF
doas cp "/keys/$KEYNAME.pub" "/etc/apk/keys/$KEYNAME.pub"
doas chmod 644 "/etc/apk/keys/$KEYNAME.pub"
# vorhandener Paket-Cache von mkimage: muss dem Schluessel dieses Baus vertrauen (z. B. erst offiziell, dann ohne Schluessel)
if [ -d "$MKW/apkroot-$ARCH/etc/apk/keys" ]; then
	install -m644 "/keys/$KEYNAME.pub" "$MKW/apkroot-$ARCH/etc/apk/keys/$KEYNAME.pub"
fi
cp "$P/iso/mkimg.edios.sh" "$P/iso/genapkovl-edios.sh" "$HOME/.mkimage/"
chmod 755 "$HOME/.mkimage/genapkovl-edios.sh"
# alte Abschnitte weg (nur der Paket-Cache apkroot-$ARCH bleibt); keine Platzhalter bei rm
find "$MKW" -mindepth 1 -maxdepth 1 ! -name "apkroot-$ARCH" -exec rm -rf {} +
rm -f "$ISO" "$ISO.sha256"
cd "$P/cache/aports/scripts"
sh ./mkimage.sh --tag "$EDIOS_FILEVER" --outdir "$OUT" --workdir "$MKW" --arch "$ARCH" \
	--profile edios --hostkeys \
	--repository "$MIRROR/$ALPINE_BRANCH/main" \
	--repository "$MIRROR/$ALPINE_BRANCH/community" \
	--repository "$P/repo/edios"
[ -f "$ISO" ] || { echo "FEHLER: ISO wurde nicht erzeugt" >&2; exit 1; }

# --- 6. Pruefungen ---
say "Pruefen"
T="$W/check"; rm -rf "$T"; mkdir -p "$T"
xorriso -osirrox on -indev "$ISO" -extract /apks "$T/apks" -extract /edios.apkovl.tar.gz "$T/ovl.tgz" \
	-extract /boot/grub/efi.img "$T/efi.img" >/dev/null 2>&1
for x in $EXCLUDE; do
	if ls "$T/apks/$ARCH" | grep -q "^$x-[0-9]"; then echo "FEHLER: $x ist auf der ISO (EXCLUDE)" >&2; exit 1; fi
done
for x in $EDIOS_PACKAGES; do
	ls "$T/apks/$ARCH" | grep -q "^$x-$EDIOS_PKGVER-r[0-9]*\.apk$" || { echo "FEHLER: $x-$EDIOS_PKGVER fehlt auf der ISO" >&2; exit 1; }
done
if xorriso -indev "$ISO" -find / -type f 2>/dev/null | grep -qi "\.\(key\|pem\|rsa\|p12\|pfx\)'$"; then
	echo "FEHLER: Schluesseldatei auf der ISO" >&2; exit 1
fi
mkdir -p "$T/ovl"; tar -C "$T/ovl" -xzf "$T/ovl.tgz"
if grep -rlsq "PRIVATE KEY" "$T/ovl" "$T/efi.img"; then echo "FEHLER: privater Schluessel im Overlay/EFI" >&2; exit 1; fi
for f in "$T/apks/$ARCH"/edios-*.apk; do
	if tar -xzOf "$f" 2>/dev/null | grep -aq "PRIVATE KEY"; then echo "FEHLER: PRIVATE KEY in ${f##*/}" >&2; exit 1; fi
done
if [ "$(cat "$EDIOS_SB/.signed")" = yes ]; then
	mdir -i "$T/efi.img" ::/EFI/BOOT >/dev/null && mcopy -o -i "$T/efi.img" ::/EFI/BOOT/grubx64.efi "$T/grub.efi"
	xorriso -osirrox on -indev "$ISO" -extract /boot/vmlinuz-lts "$T/vmlinuz" >/dev/null 2>&1
	for f in "$T/grub.efi" "$T/vmlinuz"; do
		sbverify --cert /keys/edios-mok.crt "$f" >/dev/null 2>&1 || { echo "FEHLER: sbverify ${f##*/}" >&2; exit 1; }
	done
	echo "sbverify: GRUB und Kernel auf der ISO mit dem ediOS-Schluessel signiert: OK"
fi
echo "Pakete auf der ISO: $(ls "$T/apks/$ARCH" | grep -c '\.apk$')"
size="$(stat -c %s "$ISO")"
[ "$size" -lt 2147483648 ] || { echo "FEHLER: ISO ist groesser als 2 GiB ($size Byte) - GitHub-Grenze" >&2; exit 1; }
chmod -R u+w "$T"; rm -rf "$T"         # xorriso legt Ordner schreibgeschuetzt an

cp "$EDIOS_DOC/LIESMICH.txt" "$EDIOS_DOC/README.txt" "$OUT/"
(cd "$OUT" && sha256sum "${ISO##*/}" > "${ISO##*/}.sha256")
say "FERTIG: $ISO ($(du -h "$ISO" | cut -f1), $size Byte)"
cat "$ISO.sha256"
