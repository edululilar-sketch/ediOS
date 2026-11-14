# ediOS selbst bauen

[English](../en/building.md)

Die ISO entsteht komplett aus diesem Repository. Gebaut wird in einem Docker-Container mit Alpine Linux 3.24,
der Rechner selbst braucht nur Linux (oder WSL2), Docker und Git.

## Schnellstart

```sh
git clone https://github.com/edululilar-sketch/ediOS.git
cd ediOS
./build.sh
```

Ergebnis: `out/edios-1.0-x86_64.iso` mit `.sha256`, `LIESMICH.txt` und `README.txt`.
Der erste Bau lädt alle Pakete (etwa 2 GB) und dauert je nach Internet 15–30 Minuten, weitere Baue
mit Cache etwa 8 Minuten. Freier Platz: etwa 15 GB.

## Mit oder ohne ediOS-Schlüssel

| | offizieller Bau | Bau ohne Schlüssel (jeder) |
|---|---|---|
| Schlüssel in `~/ediOS-keys` (oder `EDIOS_KEYS=…`) | `edios-repo.rsa`, `edios-mok.key/.crt/.der` | keine |
| ediOS-Pakete signiert mit | offiziellem Schlüssel | lokalem Wegwerf-Schlüssel `cache/local-keys/edios-lokal.rsa` |
| GRUB und Kernel für Secure Boot | signiert | **nicht** signiert: die ISO startet nur mit **Secure Boot AUS** |
| Updates aus der ediOS-Paketquelle | ja | ja (der öffentliche Schlüssel liegt in `src/pubkeys/` und im Paket `edios-keyring`) |

Ohne Schlüssel zeigt `./build.sh` den Hinweis „inoffizieller, unsignierter Bau“. Private Schlüssel gehören nie
ins Repository; der Container bekommt den Schlüsselordner nur lesend.

## Aufbau des Repositorys

```
build.sh, config.sh     ISO bauen, zentrale Einstellungen (Version, Alpine, Paketliste)
build/                  Bau im Container: Dockerfile, inner.sh, assets.sh (Yaru, Dash to Dock, Schriften),
                        secureboot.sh (shim, GRUB, Kernel signieren)
iso/                    ISO-Konfiguration: mkimage-Profil, Overlay, LIESMICH.txt / README.txt
src/                    ediOS selbst: files/ (Programme, Einstellungen), live/ (Installer, Live-System),
                        icons/, pubkeys/ (öffentliche Schlüssel), files.map (welche Datei wohin)
packages/               APKBUILDs der ediOS-Pakete, build-repo.sh, publish-repo.sh
tests/                  Test-VM (QEMU/OVMF in Docker), Pakettest
docs/                   Anleitungen (de/en) und Bilder
```

## Nur die Pakete bauen und testen

```sh
./packages/build-repo.sh      # braucht ~/ediOS-keys/edios-repo.rsa (ohne Schlüssel: ./build.sh, das legt repo/ an)
tests/repo-test.sh            # Pakettest in einem frischen Alpine-Container (prüft die offiziell signierten Pakete)
```

## In einer VM testen

```sh
docker build -t edios-testvm tests/
mkdir -p .testtmp/disks
docker run --rm -v "$PWD/.testtmp/disks:/d" edios-testvm qemu-img create -f qcow2 /d/ziel.qcow2 40G
tests/vm.sh start test out/edios-1.0-x86_64.iso .testtmp/disks/ziel.qcow2 nosb
tests/vm.sh q test shot /t/out/bild.png                      # Bildschirmfoto nach .testtmp/vm/test/
```
