#!/bin/sh
# ediOS Test-VM (QEMU 10 + OVMF in Docker, mit KVM).
#   tests/vm.sh start NAME ISO|- ZIEL.qcow2|- sb|nosb [usb|intern]   VM starten (im Hintergrund)
#        Umgebung: VMRES=1920x1080 (Bildschirm), VMRAM=4096 (MB)
#   tests/vm.sh q NAME qmp-Argumente...                             z. B. "shot /t/out/a.png", "key ret"
#   tests/vm.sh sh NAME 'BEFEHL' [TIMEOUT]                         Befehl als root (nur Test-Platten mit Testkanal)
#   tests/vm.sh stop NAME
# Arbeitsordner: .testtmp/vm/NAME (nicht in Git). Darin: vars.fd, serial.log, Screenshots.
# Die Zielplatte haengt als USB-Platte (Standard) oder als interne virtio-Platte.
set -eu
P="$(cd "$(dirname "$0")/.." && pwd)"
cmd="$1"; name="$2"; shift 2
D="$P/.testtmp/vm/$name"
case "$cmd" in
start)
	iso="$1"; ziel="$2"; sb="$3"; art="${4:-usb}"
	mkdir -p "$D"
	if [ "$sb" = sb ]; then code=OVMF_CODE_4M.secboot.fd; vars=OVMF_VARS_4M.ms.fd; else code=OVMF_CODE_4M.fd; vars=OVMF_VARS_4M.fd; fi
	[ -f "$D/vars.fd" ] || docker run --rm -v "$D:/t/out" edios-testvm cp "/usr/share/OVMF/$vars" /t/out/vars.fd
	res="${VMRES:-1280x800}"; ram="${VMRAM:-6144}"
	args="-enable-kvm -machine q35,smm=on -cpu host -smp 4 -m $ram
		-global driver=cfi.pflash01,property=secure,value=on
		-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/$code
		-drive if=pflash,format=raw,unit=1,file=/t/out/vars.fd
		-device virtio-vga,edid=on,xres=${res%x*},yres=${res#*x} -display none -device qemu-xhci -device usb-tablet -device usb-kbd
		-netdev user,id=n0 -device virtio-net-pci,netdev=n0
		-qmp unix:/run/qmp.sock,server,nowait -serial file:/t/out/serial.log
		-chardev socket,id=cmd,path=/t/out/cmd.sock,server=on,wait=off -device isa-serial,chardev=cmd ${VMOPTS:-}"
	vols="-v $D:/t/out -v $P/tests:/t/tests:ro"
	if [ "$iso" != - ]; then
		vols="$vols -v $(cd "$(dirname "$iso")" && pwd)/$(basename "$iso"):/t/stick.iso:ro"
		args="$args -drive if=none,id=stick,format=raw,readonly=on,file=/t/stick.iso -device usb-storage,drive=stick,bootindex=1"
	fi
	if [ "$ziel" != - ]; then
		vols="$vols -v $(cd "$(dirname "$ziel")" && pwd):/t/disks"
		zf="/t/disks/$(basename "$ziel")"
		case "$zf" in *.raw) zf="$zf,format=raw" ;; *) zf="$zf,format=qcow2" ;; esac
		if [ "$art" = intern ]; then
			args="$args -drive if=none,id=ziel,file=$zf -device virtio-blk-pci,drive=ziel,bootindex=2"
		else
			args="$args -drive if=none,id=ziel,file=$zf -device usb-storage,drive=ziel,bootindex=2"
		fi
	fi
	# shellcheck disable=SC2086
	docker run -d --rm --name "edios-vm-$name" --device /dev/kvm -e VMRES="$res" $vols edios-testvm \
		qemu-system-x86_64 $args >/dev/null
	# tests/ per HTTP fuer den Gast (10.0.2.2:8000), z. B. fuer guest-kanal.sh
	docker exec -d "edios-vm-$name" python3 -m http.server 8000 -d /t/tests >/dev/null 2>&1
	echo "VM $name gestartet ($sb, Ziel $art, $res, $ram MB)" ;;
q)
	docker exec "edios-vm-$name" python3 /t/tests/qmp.py "$@" ;;
sh)
	docker exec "edios-vm-$name" python3 /t/tests/sh.py "$@" ;;
stop)
	docker exec "edios-vm-$name" python3 /t/tests/qmp.py quit 2>/dev/null || docker stop "edios-vm-$name" >/dev/null 2>&1 || true ;;
esac
