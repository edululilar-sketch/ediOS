#!/bin/sh
# ediOS Test: installierte Test-Platte (raw) offline einhaengen und einen Befehl darin ausfuehren.
#   tests/disk.sh PLATTE.raw 'BEFEHL'      Befehl laeuft im Container, Root-Partition unter /mnt,
#                                          EFI-Partition unter /mnt/boot/efi
#   tests/disk.sh PLATTE.raw testkanal     root-Shell auf ttyS1 + rc_logger (nur Test-Kopien), siehe tests/sh.py
# Nur fuer Test-Platten (nie fuer echte Laufwerke). Braucht einen privilegierten Container (losetup).
set -eu
img="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cmd="$2"
if [ "$cmd" = testkanal ]; then
	# root-Shell auf ttyS1 (nur Test-Kopien!), dazu rc_logger fuer Start-/Stopp-Protokolle
	cmd='grep -q ttyS1 /mnt/etc/inittab || echo "ttyS1::respawn:/bin/sh -c \"stty -F /dev/ttyS1 raw -echo; exec /bin/sh </dev/ttyS1 >/dev/ttyS1 2>&1\"" >> /mnt/etc/inittab
	grep -q "^rc_logger=" /mnt/etc/rc.conf || echo "rc_logger=\"YES\"" >> /mnt/etc/rc.conf
	tail -n1 /mnt/etc/inittab'
fi
docker run --rm -i --privileged -v "$img:/img.raw" edios-testvm sh -c '
	set -eu
	L="$(losetup -f --show -P /img.raw)"
	trap "umount -R /mnt 2>/dev/null; losetup -d $L" EXIT
	# Partitionsknoten anlegen (im Container gibt es kein udev)
	for p in 1 2 3; do
		n="$(cat /sys/block/${L#/dev/}/${L#/dev/}p$p/dev 2>/dev/null)" || continue
		mknod "${L}p$p" b "${n%:*}" "${n#*:}" 2>/dev/null || true
	done
	mount "${L}p3" /mnt
	mount "${L}p1" /mnt/boot/efi 2>/dev/null || true
	'"$cmd"'
'
