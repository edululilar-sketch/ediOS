#!/bin/sh -e
# ediOS: erzeugt das Overlay (apkovl) der Live-ISO. Aufgerufen von mkimage (unter fakeroot) mit dem Hostnamen.
# GPL-3.0-or-later
# Eingaben (Umgebung, gesetzt von build/inner.sh):
#   EDIOS_P            Projektordner im Container (/edios)
#   EDIOS_OVL_GROUPS   Gruppen aus files.map, die ins Overlay kommen (system live)
#   EDIOS_WORLD        Datei mit der Paketliste des Live-Systems (/etc/apk/world)
#   EDIOS_SB           vorbereitete Secure-Boot-Dateien (build/secureboot.sh)
#   EDIOS_ASSETS       Upstream-Teile (build/assets.sh)
#   EDIOS_REPO_PUB     oeffentlicher Schluessel, mit dem die ediOS-Pakete dieser ISO signiert sind
HOSTNAME="$1"
[ -n "$HOSTNAME" ] || { echo "usage: $0 hostname"; exit 1; }
P="${EDIOS_P:-/edios}"
. "$P/config.sh"
OUTDIR="$PWD"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
R="$tmp"

rc_add() {
	mkdir -p "$R/etc/runlevels/$2"
	ln -sf "/etc/init.d/$1" "$R/etc/runlevels/$2/$1"
}

# --- ediOS-Dateien laut files.map ---
# shellcheck disable=SC2086
sh "$P/src/install-map.sh" "$R" $EDIOS_OVL_GROUPS
case " $EDIOS_OVL_GROUPS " in
*" base "*)
	# Ohne Paket edios-base: D-Bus-Override direkt an die Stelle, die dbus liest
	install -Dm644 "$P/src/files/org.gnome.Terminal.service" "$R/usr/local/share/dbus-1/services/org.gnome.Terminal.service"
	rm -f "$R/usr/share/edios/dbus/org.gnome.Terminal.service"; rmdir "$R/usr/share/edios/dbus" ;;
esac

# --- Upstream-Teile (Yaru, Dash to Dock, AppIndicator, Schriften, hyfetch) ---
cp -a "$EDIOS_ASSETS/." "$R/"

# --- Secure Boot ---
mkdir -p "$R/usr/share/edios/secureboot"
for f in LIESMICH.txt README.txt VERSIONEN.txt edios-mok.der edios-mok.sha256 grub-extra.cfg grub-hilfe.cfg grubx64.efi \
	kernel-version mmx64.efi shimx64.efi vmlinuz-lts vmlinuz-lts.signed.sha256 vmlinuz-lts.unsigned.sha256; do
	[ ! -f "$EDIOS_SB/$f" ] || install -m644 "$EDIOS_SB/$f" "$R/usr/share/edios/secureboot/$f"
done

# --- Name und Version ---
install -d "$R/etc/apk" "$R/etc/edios"
echo "$HOSTNAME" > "$R/etc/hostname"
cat > "$R/etc/os-release" <<EOF
NAME="ediOS"
PRETTY_NAME="ediOS $EDIOS_VERSION"
VERSION="$EDIOS_VERSION"
ID=edios
ID_LIKE=alpine
VERSION_ID="$EDIOS_VERSION"
HOME_URL="$EDIOS_URL"
DOCUMENTATION_URL="$EDIOS_URL#readme"
SUPPORT_URL="$EDIOS_URL/issues"
BUG_REPORT_URL="$EDIOS_URL/issues"
LOGO=edios-logo
EOF
printf 'Welcome to ediOS %s\nKernel \\r on an \\m (\\l)\n\n' "$EDIOS_VERSION" > "$R/etc/issue"
printf 'ediOS %s (Alpine Linux)\n' "$EDIOS_VERSION" > "$R/etc/motd"

# --- Pakete ---
cp "$EDIOS_WORLD" "$R/etc/apk/world"
printf '%s/%s/main\n%s/%s/community\n' "$MIRROR" "$ALPINE_BRANCH" "$MIRROR" "$ALPINE_BRANCH" > "$R/etc/apk/repositories"
echo "$MIRROR/$ALPINE_BRANCH" > "$R/etc/edios/mirror"
install -Dm644 "$EDIOS_REPO_PUB" "$R/etc/apk/keys/${EDIOS_REPO_PUB##*/}"

# --- dconf: Desktop-, Anmelde- und Live-Voreinstellungen ---
install -d "$R/etc/edios/dconf-src" "$R/etc/edios/dconf-gdm"
cat > "$R/etc/edios/dconf-src/01-generated.ini" <<EOF
[org/gnome/desktop/input-sources]
sources=[('xkb', 'de')]

[org/gnome/system/locale]
region='de_DE.UTF-8'
EOF
cat > "$R/etc/edios/dconf-gdm/01-generated.ini" <<EOF
[org/gnome/desktop/input-sources]
sources=[('xkb', 'de')]
EOF
install -d "$R/etc/dconf/profile" "$R/etc/dconf/db"
[ -f "$R/etc/dconf/profile/user" ] || printf 'user-db:user\nsystem-db:local\n' > "$R/etc/dconf/profile/user"
printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' > "$R/etc/dconf/profile/gdm"
# db/local: das Paket edios-theme baut sie selbst (post-install); im Overlay nur, wenn theme hier liegt
if [ -f "$R/etc/edios/dconf-src/00-edios.ini" ]; then
	dconf compile "$R/etc/dconf/db/local" "$R/etc/edios/dconf-src"
fi
dconf compile "$R/etc/dconf/db/gdm" "$R/etc/edios/dconf-gdm"
if [ -d "$R/etc/edios/dconf-live" ]; then
	dconf compile "$R/etc/dconf/db/live" "$R/etc/edios/dconf-live"
fi

# --- Dienste ---
# modloop nur live (der Installer entfernt ihn)
for s in devfs dmesg udev udev-trigger udev-settle modloop; do rc_add $s sysinit; done
for s in bootmisc hostname hwclock loopback modules swap sysctl syslog zram-init nftables; do rc_add $s boot; done
for s in dbus elogind networkmanager chronyd udev-postmount avahi-daemon bluetooth cupsd cgroups gdm \
	edios-gdm-theme edios-vbox; do rc_add $s default; done
for s in mount-ro killprocs savecache; do rc_add $s shutdown; done
[ ! -f "$R/etc/init.d/edios-live" ] || rc_add edios-live default
[ ! -f "$R/etc/init.d/edios-toram" ] || rc_add edios-toram boot
[ ! -f "$R/etc/init.d/edios-firmware" ] || rc_add edios-firmware sysinit
# Systemsprache (Standard Deutsch; das Live-System stellt beim Start nach edios.lang= um)
printf 'SPRACHE=de\nTASTATUR=de\nZEITZONE=Europe/Berlin\n' > "$R/etc/edios/sprache.conf"
ln -sfn /usr/share/zoneinfo/Europe/Berlin "$R/etc/localtime"
echo Europe/Berlin > "$R/etc/timezone"

# --- Kontrolle: keine privaten Schluessel im Overlay ---
if grep -rlq "PRIVATE KEY" "$R"; then
	echo "genapkovl: FEHLER - privater Schluessel im Overlay:" >&2; grep -rl "PRIVATE KEY" "$R" >&2; exit 1
fi

tar -c -C "$R" --owner=0 --group=0 --numeric-owner . | gzip -9n > "$OUTDIR/$HOSTNAME.apkovl.tar.gz"
