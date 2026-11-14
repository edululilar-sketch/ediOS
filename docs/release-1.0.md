# ediOS 1.0

**Deutsch** · [English](#english)

Erste öffentliche Version von ediOS: ein einfaches Linux mit GNOME auf Basis von Alpine Linux 3.24, auf Deutsch
und Englisch, mit Secure Boot, grafischem Installer und Updates mit einem Klick.

**Download:** `edios-1.0-x86_64.iso` (1,9 GB) · Prüfsummen: `SHA256SUMS` · Signatur: `SHA256SUMS.sig`
(prüfbar mit `edios-repo.rsa.pub`) · Secure-Boot-Zertifikat: `edios-mok.der`

**Anleitung:** [docs/de/installation.md](https://github.com/edululilar-sketch/ediOS/blob/main/docs/de/installation.md)

**Prüfsumme kontrollieren (Windows PowerShell):** `Get-FileHash .\edios-1.0-x86_64.iso -Algorithm SHA256`
und mit `SHA256SUMS` vergleichen.

**Secure Boot:** Beim ersten Start einmal den Schlüssel „ediOS Secure Boot Signing Key (MOK) 2026-11“ eintragen
(SHA-1 `2F:82:45:17:37:35:8A:AB:BF:B1:07:86:45:B9:BA:88:E6:AF:B0:3C`).

Neu in 1.0: Deutsch/English mit Sprachwahl beim ersten Start, Übernahme aller Einstellungen in die Installation,
„komplett in den RAM laden“, Updates ohne Handarbeit, Firewall, `sudo`, automatische Uhrzeit, schnelles
Ausschalten ohne Hänger. Alle Änderungen: [CHANGELOG.md](https://github.com/edululilar-sketch/ediOS/blob/main/CHANGELOG.md).

Bekannte Probleme: Kernel-Updates nur mit neuen ediOS-Versionen (Secure Boot); NVIDIA nur mit nouveau;
Zeitzone nur über die ediOS-Einrichtung änderbar; Bootmenü ohne Umlaute.

---

<a id="english"></a>
**English**

First public release of ediOS: a simple Linux with GNOME based on Alpine Linux 3.24, in English and German, with
Secure Boot, a graphical installer and one-click updates.

**Download:** `edios-1.0-x86_64.iso` (1.9 GB) · checksums: `SHA256SUMS` · signature: `SHA256SUMS.sig`
(verify with `edios-repo.rsa.pub`) · Secure Boot certificate: `edios-mok.der`

**Guide:** [docs/en/installation.md](https://github.com/edululilar-sketch/ediOS/blob/main/docs/en/installation.md)

**Check the checksum (Windows PowerShell):** `Get-FileHash .\edios-1.0-x86_64.iso -Algorithm SHA256` and compare
with `SHA256SUMS`.

**Secure Boot:** at the first start enroll the key "ediOS Secure Boot Signing Key (MOK) 2026-11" once
(SHA-1 `2F:82:45:17:37:35:8A:AB:BF:B1:07:86:45:B9:BA:88:E6:AF:B0:3C`).

New in 1.0: English/German with language choice at the first start, all settings carried over into the
installation, "load completely into RAM", updates without manual work, firewall, `sudo`, automatic time, fast
power off without hangs. All changes: [CHANGELOG.md](https://github.com/edululilar-sketch/ediOS/blob/main/CHANGELOG.md).

Known issues: kernel updates only with new ediOS versions (Secure Boot); NVIDIA only with nouveau; time zone only
changeable in ediOS Setup; boot menu without umlauts.
