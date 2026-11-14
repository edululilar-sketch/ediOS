# Building ediOS yourself

[Deutsch](../de/bauen.md)

The ISO is built entirely from this repository. The build runs in a Docker container with Alpine Linux 3.24;
the machine itself only needs Linux (or WSL2), Docker and Git.

## Quick start

```sh
git clone https://github.com/edululilar-sketch/ediOS.git
cd ediOS
./build.sh
```

Result: `out/edios-1.0-x86_64.iso` with `.sha256`, `LIESMICH.txt` and `README.txt`.
The first build downloads all packages (about 2 GB) and takes 15–30 minutes depending on the connection;
later builds with cache take about 8 minutes. Free disk space: about 15 GB.

## With or without the ediOS keys

| | official build | build without keys (anyone) |
|---|---|---|
| keys in `~/ediOS-keys` (or `EDIOS_KEYS=…`) | `edios-repo.rsa`, `edios-mok.key/.crt/.der` | none |
| ediOS packages signed with | the official key | a local throwaway key `cache/local-keys/edios-lokal.rsa` |
| GRUB and kernel for Secure Boot | signed | **not** signed: the ISO only starts with **Secure Boot OFF** |
| updates from the ediOS package source | yes | yes (the public key is in `src/pubkeys/` and in the `edios-keyring` package) |

Without keys `./build.sh` prints the note "inoffizieller, unsignierter Bau" (unofficial, unsigned build).
Private keys never belong in the repository; the container only gets the key folder read-only.

## Repository layout

```
build.sh, config.sh     build the ISO, central settings (version, Alpine, package list)
build/                  build inside the container: Dockerfile, inner.sh, assets.sh (Yaru, Dash to Dock, fonts),
                        secureboot.sh (shim, GRUB, kernel signing)
iso/                    ISO configuration: mkimage profile, overlay, LIESMICH.txt / README.txt
src/                    ediOS itself: files/ (programs, settings), live/ (installer, live system),
                        icons/, pubkeys/ (public keys), files.map (which file goes where)
packages/               APKBUILDs of the ediOS packages, build-repo.sh, publish-repo.sh
tests/                  test VM (QEMU/OVMF in Docker), package test
docs/                   guides (de/en) and pictures
```

## Build and test only the packages

```sh
./packages/build-repo.sh      # needs ~/ediOS-keys/edios-repo.rsa (without keys: ./build.sh, which creates repo/)
tests/repo-test.sh            # package test in a fresh Alpine container (checks the officially signed packages)
```

## Test in a VM

```sh
docker build -t edios-testvm tests/
mkdir -p .testtmp/disks
docker run --rm -v "$PWD/.testtmp/disks:/d" edios-testvm qemu-img create -f qcow2 /d/target.qcow2 40G
tests/vm.sh start test out/edios-1.0-x86_64.iso .testtmp/disks/target.qcow2 nosb
tests/vm.sh q test shot /t/out/picture.png                    # screenshot to .testtmp/vm/test/
```
