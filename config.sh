# ediOS: zentrale Bau-Einstellungen (GPL-3.0-or-later). Wird von build.sh (Host) und build/inner.sh (Container) gelesen.
# shellcheck shell=sh disable=SC2034

# --- Version ---
EDIOS_VERSION="1.1"                     # Anzeigename (os-release, motd, GRUB, Fenster)
EDIOS_FILEVER="1.1"                     # fuer Dateinamen: out/edios-$EDIOS_FILEVER-x86_64.iso
EDIOS_VOLID="EDIOS-1.1"                 # ISO-Datentraegername (GRUB sucht danach)
EDIOS_PKGVER="1.1.0"                    # Version der ediOS-Pakete (packages/*/APKBUILD)
EDIOS_URL="https://github.com/edululilar-sketch/ediOS"
EDIOS_REPO_URL="https://edululilar-sketch.github.io/edios-repo/v3.24/edios"

# --- Alpine ---
ALPINE_BRANCH=v3.24
MIRROR=https://mirror.netcologne.de/alpine
ARCH=x86_64

# Kernel und GRUB sind fest, weil sie mit dem ediOS-Schluessel signiert werden.
KERNEL_VERSION=6.18.63-r0               # linux-lts
GRUB_VERSION=2.14-r0                    # grub-efi

# --- Secure Boot: shim von Debian 13 (von Microsoft signiert). Pruefsummen werden beim Bau kontrolliert. ---
DEBIAN_POOL=https://deb.debian.org/debian/pool/main/s
SHIM_DEB="shim-signed/shim-signed_1.51~1+deb13u1+16.1-2~deb13u1_amd64.deb"
SHIM_DEB_SHA256=3c802fa303c0e6bf126adee74028d1042e3120360d159c2c05181dc9b2f61005
SHIM_HELPERS_DEB="shim-helpers-amd64-signed/shim-helpers-amd64-signed_1+16.1+2~deb13u1_amd64.deb"
SHIM_HELPERS_DEB_SHA256=7e950d75d5a40ecc0a99f727452ce35780b47a04d9a2cc3b1ff7c2bb316c033e
# Erwartete Dateien (Pruefsummen von shimx64.efi und mmx64.efi)
SHIMX64_SHA256=e103c5d02657879f141b086ed703584d28bb9e2721b423333be085ee1b4d397b
MMX64_SHA256=30ea13138310f0819c1d875fcf3a6cdce8a1607cfd7578053a2df894a41630ae

# GRUB laedt mit Secure Boot keine Module nach: alles Noetige wird fest eingebaut.
GRUB_SB_MODULES="part_gpt part_msdos fat iso9660 ext2 normal configfile search search_label search_fs_uuid
	search_fs_file linux echo test true ls cat help gzio xzio all_video efi_gop efi_uga video_bochs
	video_cirrus gfxterm gfxmenu font loadenv chain efifwsetup read sleep reboot halt minicmd regexp
	probe keystatus bli tpm"
# SBAT: shim 16.1 verlangt grub >= 5
GRUB_SBAT_GENERATION=5
GRUB_SBAT_EDIOS=1

# --- Pakete (= /etc/apk/world des installierten Systems) ---
# 1.0 neu: nftables (Firewall), doas-sudo-shim (Befehl "sudo" -> doas), tzdata (Zeitzonen), accountsservice
# (Sprache je Benutzer), hunspell-en-us (Rechtschreibung Englisch), chrony (Uhrzeit aus dem Internet),
# iproute2-ss (Befehl ss)
# 1.1: GNOME Software (samt apk-Plugin) und LibreOffice sind nicht mehr dabei (Ersatz: "ediOS Apps", LibreOffice
# dort als Flatpak). Neue Programme (Codecs, Schriften, Archive, NTFS/exFAT, MTP, Uebersetzungen, earlyoom,
# openrc-settingsd) kommen ueber das Paket edios-system, damit sie auch per Update ankommen.
PACKAGES="adwaita-fonts adwaita-fonts-mono adwaita-fonts-sans adwaita-icon-theme alpine-base alsa-utils
alsa-utils-openrc amd-ucode avahi chrony chrony-openrc avahi-lang avahi-openrc bash bash-completion bluez bluez-openrc
cups cups-filters cups-lang cups-openrc cups-pk-helper cups-pk-helper-lang curl dbus dbus-openrc
dbus-x11 dconf doas doas-sudo-shim dosfstools e2fsprogs efibootmgr elogind elogind-lang elogind-openrc eudev
eudev-openrc fastfetch firefox firefox-intl flatpak flatpak-lang font-noto-emoji gcr-ssh-agent gdm
gdm-lang gdm-openrc git glib-lang gnome-backgrounds gnome-bluetooth gnome-bluetooth-lang
gnome-calculator gnome-calculator-lang gnome-control-center gnome-control-center-lang
gnome-desktop-lang gnome-disk-utility gnome-disk-utility-lang gnome-extensions-app gnome-keyring
gnome-keyring-lang gnome-keyring-openrc gnome-online-accounts gnome-online-accounts-lang
gnome-session-lang gnome-settings-daemon-lang gnome-shell gnome-shell-extensions
gnome-shell-extensions-lang gnome-shell-lang gnome-system-monitor
gnome-system-monitor-lang gnome-terminal gnome-terminal-lang gnome-text-editor
gnome-text-editor-lang gnome-tweaks gnome-tweaks-lang accountsservice grub-efi gsettings-desktop-schemas
gsettings-desktop-schemas-lang gst-thumbnailers gtk+3.0-lang gtk4.0-lang gvfs gvfs-lang gvfs-openrc
htop hunspell hunspell-de-de iproute2-ss hunspell-en-us hunspell-lang iio-sensor-proxy iio-sensor-proxy-openrc
intel-media-driver intel-ucode libadwaita-lang libnotify
localsearch localsearch-lang loupe
loupe-lang mesa mesa-dri-gallium mesa-va-gallium mesa-vulkan-ati mesa-vulkan-intel mokutil
musl-locales musl-locales-lang nano nautilus nautilus-lang networkmanager networkmanager-lang
networkmanager-openrc networkmanager-wifi nftables nftables-openrc openssl papers papers-lang pinentry-gnome pipewire
pipewire-alsa pipewire-lang pipewire-openrc pipewire-pulse pipewire-pulse-openrc pipewire-spa-bluez
pipx polkit-elogind polkit-gnome polkit-gnome-lang py3-gobject3 python3 showtime showtime-lang
sof-firmware steam-devices tinysparql tzdata tinysparql-lang udev-init-scripts udev-init-scripts-openrc udisks2
udisks2-lang udisks2-openrc util-linux-misc virtualbox-guest-additions
virtualbox-guest-additions-openrc virtualbox-guest-additions-udev virtualbox-guest-additions-x11
vulkan-loader wireplumber wireplumber-lang wireplumber-openrc wpa_supplicant wpa_supplicant-openrc
xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gnome-lang xdg-desktop-portal-gtk
xdg-desktop-portal-gtk-lang xdg-desktop-portal-lang xdg-desktop-portal-openrc xdg-user-dirs
xdg-user-dirs-lang xwayland zenity zenity-lang zram-init zram-init-openrc"

# Eigene Pakete aus packages/ (lokales, signiertes Repo, Schluessel ~/ediOS-keys/edios-repo.rsa).
# Update-Knopf, Einrichtung, Aussehen und Apps-Helfer kommen als Pakete (nicht aus dem Overlay).
EDIOS_PACKAGES="edios-keyring edios-system edios-base edios-theme edios-apps edios-gdm-theme"

# Gruppen aus src/files.map, die (noch) im Overlay liegen (base/theme/apps sind Pakete).
EDIOS_OVL_GROUPS="system live"

# Nur im Live-System (fuer den Installer); auf der ISO, damit ohne Internet installiert werden kann.
LIVE_PACKAGES="sfdisk lsblk grub"

# Firmware: Liste in src/files/firmware.list (im System /etc/edios/firmware). Im Live-System kommt sie
# aus dem modloop, der Installer installiert die Pakete auf die Zielplatte.

# Duerfen NICHT auf der ISO sein (Bau bricht sonst ab): zweite Terminals, Yaru-Icons/-Cursor.
EXCLUDE="gnome-console ptyxis xterm yaru-icon-theme yaru-theme"

# --- Upstream-Teile, die build/assets.sh baut (noch nicht in Paketen) ---
YARU_COMMIT=7f18973e05607c609c4b972f0dd9bff36fa2a13e      # ubuntu/yaru master, 2026-09-14
DASH_TO_DOCK_URL=https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v110/dash-to-dock@micxgx.gmail.com.zip
DASH_TO_DOCK_SHA256=3e60680fe7217b905aac4f10deb042e39fcf49168c9b8fdcc5a711bdd49bd3d2
APPINDICATOR_URL=https://github.com/ubuntu/gnome-shell-extension-appindicator/releases/download/v66/appindicatorsupport@rgcjonas.gmail.com.zip
APPINDICATOR_SHA256=f2b17c7c5590f729853cd353f20a9e59b6e0c32e9c0a561976e09f5a97487730
OPENDYSLEXIC_TAG=v0.91.12                                  # antijingoist/opendyslexic, compiled/*.otf
UBUNTU_FONT_COMMIT=bed55e0de5cfa8f5fb94f9a1f49409b5ec504469   # google/fonts, Pfad ufl/ubuntu (Ubuntu 0.83), 2026-10-15
HYFETCH_VERSION=2.1.0                                      # PyPI, 2026-06-03
