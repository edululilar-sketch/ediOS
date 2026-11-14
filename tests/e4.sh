#!/bin/sh
# INTERN: Mess-Hilfe aus den Tests zu 1.0 (feste Klickpositionen, Testbenutzer, braucht das Werkzeug-Image
# "edios-tools" mit Pillow und .testtmp/region.py). Nicht fuer den allgemeinen Gebrauch gedacht.
# E4-Test: installierte Platte starten, anmelden, ueber das GNOME-Menue ausschalten bzw. neu starten,
# Zeit vom Klick bis zum Ende der VM messen (Neustart mit -no-reboot = VM endet beim Neustart).
#   tests/e4.sh PLATTE.raw PASSWORT aus|neu NAME
P="$(cd "$(dirname "$0")/.." && pwd)"; cd "$P"
disk="$1"; pw="$2"; art="$3"; n="$4"
[ "$art" = neu ] && export VMOPTS="-no-reboot"
tests/vm.sh start "$n" - "$disk" nosb usb >/dev/null
sleep 45
V="tests/vm.sh q $n"
$V click 640 351; sleep 2; $V type "$pw"; $V key ret; sleep 30
$V key esc; sleep 1
$V click 1258 13; sleep 1.5; $V click 1237 68; sleep 1.5
$V shot /t/out/menue.png
if [ "$art" = aus ]; then y=261; else y=220; fi
t0=$(date +%s.%N); $V click 1036 $y
dialog=nein
for i in $(seq 1 120); do
	sleep 0.25
	docker ps -q -f name="edios-vm-$n" | grep -q . || break
	[ "$i" = 8 ] && $V shot /t/out/nach2s.png 2>/dev/null
done
echo "$art: $(python3 -c "import time;print(round(time.time()-$t0,1))") s"
