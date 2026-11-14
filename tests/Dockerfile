# ediOS Test-VM: QEMU + OVMF (Debian 13, mit Secure-Boot-Firmware und Microsoft-Schluesseln)
FROM debian:trixie
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
	qemu-system-x86 qemu-utils ovmf python3 mtools dosfstools fdisk e2fsprogs xorriso ca-certificates \
	&& rm -rf /var/lib/apt/lists/*
