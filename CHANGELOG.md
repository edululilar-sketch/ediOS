# Änderungen / Changelog

## 1.1 (2026-11-14, noch nicht veröffentlicht / not yet released)

### Deutsch

**Neu**
- **Medien:** spielt gängige Video- und Musikformate ab (H.264, H.265, AAC, MP3, Opus) – mit GStreamer-libav/-ugly;
  neuer Musikplayer **Decibels**. Dateien zeigt Vorschaubilder für Videos und PDFs.
- **Dateien:** Archive öffnen (zip, 7z, rar) und packen (zip, 7z); Windows-Platten (NTFS) und USB-Sticks (exFAT)
  lesen und schreiben; Handys per USB (MTP) erscheinen in Dateien. PDFs öffnen standardmäßig im Dokumentenbetrachter.
- **Schriften:** farbige Emojis; Ersatz für Microsoft-Schriften (Liberation für Arial/Times/Courier, Carlito für
  Calibri, Caladea für Cambria).
- **Tastenkürzel:** Super+E öffnet Dateien, Strg+Umschalt+Esc den Systemmonitor (Druck = Bildschirmfoto,
  Super+L = Sperren wie gehabt). Der Ziffernblock ist nach der Anmeldung an.
- **Wenig Speicherplatz:** Warnung, sobald auf einer Platte weniger als 10 % frei sind.
- **Spiele:** Controller von Xbox, PlayStation und Nintendo Switch (USB und Bluetooth) sind für Steam & Co. nutzbar;
  `vm.max_map_count` erhöht (viele Windows-Spiele unter Proton); **earlyoom** schützt vor einem Einfrieren, wenn der
  Arbeitsspeicher voll läuft.
- **Zeitzone und Uhr** lassen sich jetzt in den GNOME-Einstellungen ändern (openrc-settingsd).
- **LibreOffice** ist nicht mehr fest eingebaut (ISO 198 MB kleiner), sondern im Apps-Helfer unter „Werkzeuge“ als
  Flatpak. Auf schon installierten Systemen bleibt es, wie es ist.
- Neues Paket **edios-system**: bringt diese Neuerungen auch per Update zu installierten 1.0-Systemen.

**Verbessert / behoben**
- Secure-Boot-Hinweis erscheint nur noch **einmal** (danach über die App „Secure Boot“) und im Live-System erst nach
  dem Willkommen-Fenster.
- **GNOME Software entfernt:** Es meldete Fehler zu `apk-polkit-server` und konnte Systemprogramme deinstallieren.
  Apps gibt es über „ediOS Apps“, Updates über „ediOS aktualisieren“. Auf 1.0-Systemen entfernt ein einmaliger
  Schritt beim ersten Start nach dem Update GNOME Software (Flatpak-Apps bleiben).
- **Englische Reste übersetzt:** alle Sprachpakete installiert; Sprach- und Ländernamen in den Einstellungen deutsch
  (Alpines iso-codes-lang enthält die Dateien nicht); Systemmonitor deutsch (Ursache: `LC_COLLATE=C`); ediOS-Dialoge
  haben ein eigenes Symbol statt eines leeren.
- fastfetch, „Info“ und `/etc/os-release` zeigen „ediOS 1.1“, auch nach dem Update.
- Nach einem Sprachwechsel startet die Einrichtung den PC neu, statt abzumelden.

**Bekannt**
- „Abmelden“ im Systemmenü: Danach erscheint kein Passwortfeld; bitte neu starten (seit 1.0, Lösung geplant für 1.2).

### English

**New**
- **Media:** plays common video and music formats (H.264, H.265, AAC, MP3, Opus) via GStreamer libav/ugly; new music
  player **Decibels**. Files shows thumbnails for videos and PDFs.
- **Files:** open archives (zip, 7z, rar) and create them (zip, 7z); read and write Windows drives (NTFS) and USB
  sticks (exFAT); phones connected via USB (MTP) show up in Files. PDFs open in the document viewer by default.
- **Fonts:** colour emoji; replacements for Microsoft fonts (Liberation for Arial/Times/Courier, Carlito for Calibri,
  Caladea for Cambria).
- **Shortcuts:** Super+E opens Files, Ctrl+Shift+Esc the System Monitor (Print = screenshot, Super+L = lock as
  before). Num Lock is on after logging in.
- **Low disk space:** warning as soon as less than 10 % is free on a drive.
- **Games:** Xbox, PlayStation and Nintendo Switch controllers (USB and Bluetooth) work in Steam and others;
  higher `vm.max_map_count` (many Windows games under Proton); **earlyoom** prevents freezes when memory runs full.
- **Time zone and clock** can now be changed in GNOME Settings (openrc-settingsd).
- **LibreOffice** is no longer built in (ISO 198 MB smaller); it is offered as a Flatpak in the apps helper under
  "Tools". Already installed systems keep it.
- New package **edios-system**: brings these changes to installed 1.0 systems via the update.

**Improved / fixed**
- The Secure Boot hint appears only **once** (afterwards via the "Secure Boot" app) and, in the live system, only
  after the welcome window.
- **GNOME Software removed:** it reported errors about `apk-polkit-server` and could uninstall system programs. Apps
  come from "ediOS Apps", updates from "Update ediOS". On 1.0 systems a one-time step at the first start after the
  update removes GNOME Software (Flatpak apps are kept).
- **Remaining English/German mix-ups fixed:** all translation packages installed; language and country names in
  Settings are translated (Alpine's iso-codes-lang lacks the files); System Monitor translated (cause:
  `LC_COLLATE=C`); ediOS dialogs have their own icon instead of an empty one.
- fastfetch, "About" and `/etc/os-release` show "ediOS 1.1", also after updating.
- After changing the language, the setup restarts the PC instead of logging out.

**Known issue**
- "Log Out" in the system menu: no password field appears afterwards; please restart (since 1.0, fix planned for 1.2).

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
