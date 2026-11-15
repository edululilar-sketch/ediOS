# ediOS 1.1

**Deutsch** · [English](#english)

Kleines Pflege-Update für ediOS 1.0. Wer ediOS 1.0 installiert hat, bekommt alles über „ediOS aktualisieren“ –
eine neue Installation ist nicht nötig.

**Download:** `edios-1.1-x86_64.iso` (1,7 GB) · Prüfsummen: `SHA256SUMS` · Signatur: `SHA256SUMS.sig`
(prüfbar mit `edios-repo.rsa.pub`) · Secure-Boot-Zertifikat: `edios-mok.der` (unverändert gegenüber 1.0)

**Anleitung:** [docs/de/installation.md](https://github.com/edululilar-sketch/ediOS/blob/main/docs/de/installation.md)

**Prüfsumme kontrollieren (Windows PowerShell):** `Get-FileHash .\edios-1.1-x86_64.iso -Algorithm SHA256`
und mit `SHA256SUMS` vergleichen.

Neu in 1.1: gängige Video- und Musikformate (H.264, H.265, AAC, MP3, Opus) und Musikplayer Decibels;
Vorschaubilder für Videos und PDFs; Archive (zip, 7z, rar); Windows-Platten (NTFS), USB-Sticks (exFAT) und Handys
(MTP); farbige Emojis und Ersatz für Microsoft-Schriften; Super+E, Strg+Umschalt+Esc, NumLock an; Warnung bei
wenig Speicherplatz; Controller von Xbox, PlayStation und Switch, Schutz vor vollem Arbeitsspeicher; Zeitzone in
den Einstellungen änderbar; viele englische Reste übersetzt; Secure-Boot-Hinweis nur noch einmal. GNOME Software
und das fest eingebaute LibreOffice sind entfallen (LibreOffice gibt es in „ediOS Apps“).
Alle Änderungen: [CHANGELOG.md](https://github.com/edululilar-sketch/ediOS/blob/main/CHANGELOG.md).

Bekannte Probleme: Nach „Abmelden“ erscheint kein Passwortfeld – bitte neu starten (Lösung für 1.2 geplant);
Kernel-Updates nur mit neuen ediOS-Versionen (Secure Boot); NVIDIA nur mit nouveau; Bootmenü ohne Umlaute.

---

<a id="english"></a>
**English**

Small maintenance update for ediOS 1.0. If you installed ediOS 1.0, you get everything through "Update ediOS" –
no new installation needed.

**Download:** `edios-1.1-x86_64.iso` (1.7 GB) · checksums: `SHA256SUMS` · signature: `SHA256SUMS.sig`
(verify with `edios-repo.rsa.pub`) · Secure Boot certificate: `edios-mok.der` (unchanged since 1.0)

**Guide:** [docs/en/installation.md](https://github.com/edululilar-sketch/ediOS/blob/main/docs/en/installation.md)

**Check the checksum (Windows PowerShell):** `Get-FileHash .\edios-1.1-x86_64.iso -Algorithm SHA256` and compare
with `SHA256SUMS`.

New in 1.1: common video and music formats (H.264, H.265, AAC, MP3, Opus) and the Decibels music player; thumbnails
for videos and PDFs; archives (zip, 7z, rar); Windows drives (NTFS), USB sticks (exFAT) and phones (MTP); colour
emoji and replacements for Microsoft fonts; Super+E, Ctrl+Shift+Esc, Num Lock on; low disk space warning; Xbox,
PlayStation and Switch controllers, protection against running out of memory; time zone changeable in Settings;
many untranslated texts fixed; Secure Boot hint shown only once. GNOME Software and the built-in LibreOffice were
removed (LibreOffice is available in "ediOS Apps").
All changes: [CHANGELOG.md](https://github.com/edululilar-sketch/ediOS/blob/main/CHANGELOG.md).

Known issues: after "Log Out" no password field appears – please restart (fix planned for 1.2); kernel updates only
with new ediOS versions (Secure Boot); NVIDIA only with nouveau; boot menu without umlauts.
