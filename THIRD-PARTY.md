# Fremde Bestandteile / Third-party components

**Deutsch:** ediOS besteht zum größten Teil aus fremder freier Software. Der ediOS-eigene Code in diesem
Repository (Skripte, Programme, Paketbeschreibungen, Einstellungen) steht unter der
[GPL-3.0-or-later](LICENSE). Für alle anderen Teile gelten ihre eigenen Lizenzen. Die folgende Liste nennt die
Teile, die ediOS selbst holt, verändert oder mitliefert, mit Lizenz und Quelle.

**English:** ediOS consists mostly of third-party free software. The ediOS code in this repository (scripts,
programs, package descriptions, settings) is licensed under the [GPL-3.0-or-later](LICENSE). All other parts
keep their own licenses. The list below names the parts that ediOS fetches, modifies or ships itself, with
license and source.

## Basis / Base system

| Teil / Part | Version | Lizenz / License | Quelle / Source |
|---|---|---|---|
| Alpine Linux (alle Pakete der ISO / all packages on the ISO) | 3.24 | je Paket, siehe `apk info -L` bzw. `/usr/share/licenses` / per package | https://alpinelinux.org, https://gitlab.alpinelinux.org/alpine/aports |
| Linux-Kernel `linux-lts` (von ediOS für Secure Boot signiert / signed by ediOS for Secure Boot) | 6.18.63-r0 | GPL-2.0-only | https://kernel.org, Alpine aports |
| GRUB `grub-efi` (EFI-Abbild von ediOS gebaut und signiert / EFI image built and signed by ediOS) | 2.14-r0 | GPL-3.0-or-later | https://www.gnu.org/software/grub/ |
| shim (`shimx64.efi`, `mmx64.efi`), von Microsoft signiert / signed by Microsoft | Debian 16.1 (shim-signed 1.51~1+deb13u1) | BSD-2-Clause | https://github.com/rhboot/shim, https://packages.debian.org/trixie/shim-signed |
| GNOME (Shell 50, Mutter, GDM, Einstellungen, Apps …) | Alpine 3.24 | GPL-2.0-or-later / LGPL-2.1-or-later (je Programm) | https://www.gnome.org |
| Mesa (Grafiktreiber / graphics drivers) | 26.1 | MIT | https://mesa3d.org |
| linux-firmware (WLAN, Bluetooth, Grafik / Wi-Fi, Bluetooth, graphics) | 20260519 | je Datei, siehe `WHENCE` / per file | https://gitlab.com/kernel-firmware/linux-firmware |
| Firefox | Alpine 3.24 | MPL-2.0 | https://www.mozilla.org/firefox/ |
| LibreOffice (ab 1.1 nicht mehr auf der ISO; im Apps-Helfer als Flatpak, installiert der Benutzer selbst / since 1.1 not on the ISO; offered as Flatpak in the apps helper, installed by the user) | Flathub | MPL-2.0 | https://www.libreoffice.org |
| Flatpak (Apps von Flathub installiert der Benutzer selbst / apps from Flathub are installed by the user) | Alpine 3.24 | LGPL-2.1-or-later | https://flatpak.org, https://flathub.org |
| doas, doas-sudo-shim (`sudo` → `doas`) | Alpine 3.24 | ISC | https://github.com/Duncaen/OpenDoas, https://github.com/jirutka/doas-sudo-shim |
| nftables (Firewall) | 1.1.6 | GPL-2.0-only | https://netfilter.org/projects/nftables/ |
| GLib-Werkzeuge `gresource`, `glib-compile-resources` (im Paket `edios-gdm-theme` mitgeliefert / shipped in `edios-gdm-theme`) | Alpine 3.24 | LGPL-2.1-or-later | https://gitlab.gnome.org/GNOME/glib |

## Von ediOS beim Bau geholt / Fetched by the ediOS build (`build/assets.sh`, Prüfsummen in `build/assets.sha256`)

| Teil / Part | Version | Lizenz / License | Quelle / Source |
|---|---|---|---|
| Yaru (nur GTK-Fensterstil, keine Icons, keine Logos / GTK theme only, no icons, no logos) | Commit `7f18973e` | GPL-3.0-or-later und / and CC-BY-SA-4.0 | https://github.com/ubuntu/yaru |
| Dash to Dock (GNOME-Shell-Erweiterung / extension) | v110 | GPL-2.0-or-later | https://github.com/micheleg/dash-to-dock |
| AppIndicator and KStatusNotifierItem Support | v66 | GPL-2.0-or-later | https://github.com/ubuntu/gnome-shell-extension-appindicator |
| Ubuntu Font Family (Schrift / font, unverändert / unmodified) | 0.83 | Ubuntu Font Licence 1.0 | https://github.com/google/fonts/tree/main/ufl/ubuntu |
| OpenDyslexic (Schrift / font) | v0.91.12 | SIL Open Font License 1.1 | https://github.com/antijingoist/opendyslexic |
| hyfetch / neowofetch | 2.1.0 | MIT | https://github.com/hykilpikonna/hyfetch |

## Über das Paket `edios-system` nachgezogene Alpine-Pakete (Auswahl) / Alpine packages pulled in by `edios-system` (selection)

| Teil / Part | Version | Lizenz / License | Quelle / Source |
|---|---|---|---|
| GStreamer libav (FFmpeg) und / and gst-plugins-ugly (u. a. H.264/H.265-Dekoder; Patente je nach Land / patents depend on the country) | Alpine 3.24 | LGPL-2.1-or-later / GPL-2.0-or-later | https://gstreamer.freedesktop.org, https://ffmpeg.org |
| 7-Zip (enthält unRAR-Code mit eigener Lizenzbedingung / contains unRAR code with its own license restriction) | 26.01 | LGPL-2.1 + unRAR-Einschränkung / restriction | https://7-zip.org |
| Decibels (Musik / music) | Alpine 3.24 | GPL-3.0-or-later | https://gitlab.gnome.org/GNOME/Incubator/decibels |
| earlyoom, openrc-settingsd, ntfs-3g, exfatprogs, file-roller, gvfs-mtp, Liberation/Carlito-Schriften / fonts | Alpine 3.24 | je Paket / per package | Alpine aports |

## Im Paket `edios-system` mitgeliefert (ab 1.1) / Shipped in the `edios-system` package (since 1.1)

| Teil / Part | Version | Lizenz / License | Quelle / Source |
|---|---|---|---|
| Caladea (Schrift, metrisch gleich wie Cambria / font, metric-compatible with Cambria; unverändert / unmodified) | 1.002, google/fonts Commit `bed55e0d` | SIL Open Font License 1.1 | https://github.com/google/fonts/tree/main/ofl/caladea |
| iso-codes, deutsche Übersetzungen (Sprach-/Ländernamen; unverändert, nur mit `msgfmt` übersetzt / German translations of language and country names; unmodified, only compiled with `msgfmt`) | 4.20.1 | LGPL-2.1-or-later | https://salsa.debian.org/iso-codes-team/iso-codes |

Die Lizenztexte der Schriften liegen im System unter `/usr/share/licenses/ubuntu-font/` und
`/usr/share/licenses/opendyslexic/`, ab 1.1 auch `/usr/share/licenses/font-caladea/` und `/usr/share/licenses/edios-iso-codes-de/`. / The font license texts are installed in `/usr/share/licenses/`.

Hinweis zu Marken / Note on trademarks: „Ubuntu“ ist eine Marke von Canonical Ltd. ediOS verwendet die
unveränderte Schrift „Ubuntu“ (erlaubt durch die Ubuntu Font Licence) und den freien GTK-Stil Yaru, aber
keine Ubuntu-Logos oder -Markenzeichen und ist kein Produkt von Canonical. / “Ubuntu” is a trademark of
Canonical Ltd. ediOS uses the unmodified “Ubuntu” font (permitted by the Ubuntu Font Licence) and the free
Yaru GTK theme, but no Ubuntu logos or trademarks, and is not a Canonical product.
„Alpine Linux“, „GNOME“, „Firefox“ und „Steam“ sind Marken ihrer Inhaber. / are trademarks of their owners.

## ediOS-eigene Bilder / ediOS artwork

| Datei / File | Lizenz / License |
|---|---|
| `src/icons/edios-logo.png`, `edios-logo-login.png`, `edios-wallpaper.png`, `edios-login-bg.jpg` (ediOS-Logo und Hintergrund / logo and wallpaper) | Teil von ediOS, GPL-3.0-or-later / part of ediOS |
| `src/icons/*.svg` (ediOS-App-Icons im Adwaita-Stil, selbst gezeichnet / drawn for ediOS) | GPL-3.0-or-later |
| `src/files/edios.txt`, `edios-hyfetch.txt` (Text-Logo für fastfetch / text logo) | GPL-3.0-or-later |

Alle übrigen Icons kommen aus dem Adwaita-Icon-Theme von GNOME (LGPL-3.0-or-later / CC-BY-SA-3.0).
All other icons come from GNOME's Adwaita icon theme (LGPL-3.0-or-later / CC-BY-SA-3.0).
