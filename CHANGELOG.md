# Änderungen / Changelog

## 1.0 (2026-11-14)

Erste öffentliche Version. / First public release.

### Deutsch

**Das bringt ediOS 1.0**
- **Live-System und Installer:** startet vom USB-Stick (UEFI, mit und ohne Secure Boot) und installiert sich mit
  einem grafischen Installer auf eine ganze Platte – auch ohne Internet. Die Plattenliste zeigt Größe, Modell,
  Anschluss und gefundene Systeme (z. B. Windows); geöffnete Platten werden sauber ausgehängt, der ediOS-Stick ist
  nie auswählbar. Bei internen Platten bleibt Windows im Startmenü des PCs an erster Stelle.
- **Deutsch und English:** Sprachwahl als erster Schritt der Einrichtung, mit Vorschlag für Tastatur und Zeitzone.
  Die Wahl gilt sofort für GNOME und alle ediOS-Programme; das Bootmenü hat Einträge für beide Sprachen.
- **Einrichtung:** Sprache, Tastatur, Zeitzone, Schrift (OpenDyslexic, Adwaita, Ubuntu) und Dock-Position. Der
  Installer übernimmt alles ins installierte ediOS; die Einrichtung erscheint dort nicht noch einmal.
- **„Komplett in den RAM laden“** im Bootmenü: Danach kann der USB-Stick abgezogen werden (ab 8 GB RAM).
- **Updates:** „ediOS aktualisieren“ bringt Alpine- und ediOS-Pakete sowie Flatpak-Apps auf den neuesten Stand,
  warnt bei schwachem Akku und erklärt Fehler verständlich. Die signierte ediOS-Paketquelle ist ab Werk aktiv
  (Paket `edios-keyring`); einmal pro Woche kommt ein Hinweis, wenn es Updates gibt.
- **ediOS Apps:** Steam, Discord, Spotify, GIMP und weitere Apps von Flathub mit einem Klick (Gamepads in Steam
  dank `steam-devices`).
- **Sicherheit:** Firewall (nftables) ab Werk an – eingehend zu, ausgehend offen; kein SSH-Dienst.
  `sudo` funktioniert (leitet auf `doas` weiter).
- **Hardware:** Firmware für gängige WLAN-, Bluetooth-, Grafik- (Intel, AMD inkl. RDNA 4, NVIDIA/nouveau) und
  Laptop-Audio-Chips, auch im Live-System; Mesa 26.1; PipeWire; CUPS; zram für PCs mit wenig RAM.
- **Schnell:** Anmeldebildschirm wenige Sekunden nach dem Kernelstart, Ausschalten und Neustart in wenigen Sekunden
  ohne Rückfrage; Uhrzeit automatisch aus dem Internet (chrony).

**Vor der Veröffentlichung behoben (gegenüber den internen Testversionen)**
- Ausschalten hing mit „GNOME Shell antwortet nicht“: Alpines gnome-shell 50 meldet sich bei gnome-session 48 an,
  beantwortet aber dessen Abmelde-Anfragen nicht. Die ediOS-Shell-Erweiterung „ediOS Sitzung“ antwortet dafür.
- Im Live-System war die Firmware im modloop für den Kernel nicht erreichbar.
- Der Start wartete auf manchen PCs/VMs 10 s auf die Hardware-Uhr.
- Logo überall exakt mittig, ohne deutschen Zusatztext.

### English

**What ediOS 1.0 brings**
- **Live system and installer:** starts from a USB stick (UEFI, with and without Secure Boot) and installs onto a
  whole disk with a graphical installer – also without internet. The disk list shows size, model, connection and
  systems found (e.g. Windows); open disks are unmounted cleanly, the ediOS stick can never be selected. On internal
  disks Windows stays first in the PC's boot menu.
- **English and German:** choosing the language is the first setup step, with a suggestion for keyboard and time
  zone. The choice applies right away to GNOME and all ediOS programs; the boot menu has entries for both languages.
- **Setup:** language, keyboard, time zone, font (OpenDyslexic, Adwaita, Ubuntu) and dock position. The installer
  copies everything to the installed ediOS; the setup does not appear there again.
- **"Load completely into RAM"** in the boot menu: afterwards the USB stick can be removed (8 GB RAM or more).
- **Updates:** "Update ediOS" updates Alpine and ediOS packages and Flatpak apps, warns about a low battery and
  explains errors clearly. The signed ediOS package source is enabled out of the box (package `edios-keyring`);
  once a week a notification appears when updates are available.
- **ediOS Apps:** Steam, Discord, Spotify, GIMP and more apps from Flathub with one click (gamepads in Steam thanks
  to `steam-devices`).
- **Security:** firewall (nftables) on by default – incoming closed, outgoing open; no SSH service. `sudo` works
  (forwards to `doas`).
- **Hardware:** firmware for common Wi-Fi, Bluetooth, graphics (Intel, AMD incl. RDNA 4, NVIDIA/nouveau) and laptop
  audio chips, also in the live system; Mesa 26.1; PipeWire; CUPS; zram for PCs with little memory.
- **Fast:** login screen a few seconds after the kernel starts, power off and restart in a few seconds without
  confirmation; time set automatically from the internet (chrony).

**Fixed before the release (compared to the internal test versions)**
- Power off hung with "GNOME Shell is not responding": Alpine's gnome-shell 50 registers with gnome-session 48 but
  does not answer its end-of-session queries. The ediOS shell extension "ediOS Sitzung" now answers them.
- In the live system the firmware in the modloop was not reachable for the kernel.
- Starting waited 10 s for the hardware clock on some PCs/VMs.
- Logo exactly centred everywhere, without German extra text.
