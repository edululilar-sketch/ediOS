#!/bin/sh
# INTERN: Mess-Hilfe aus den Tests zu 1.0 (feste Klickpositionen, Testbenutzer, braucht das Werkzeug-Image
# "edios-tools" mit Pillow und .testtmp/region.py). Nicht fuer den allgemeinen Gebrauch gedacht.
# A4: Logo-Lage bei einer Bildschirmaufloesung messen (installierte Platte, Benutzer erika).
#   tests/a4.sh PLATTE PASSWORT BREITExHOEHE
P="$(cd "$(dirname "$0")/.." && pwd)"; cd "$P"
disk="$1"; pw="$2"; res="$3"; W=${res%x*}; H=${res#*x}; n="a4-$res"
rm -rf ".testtmp/vm/$n"
VMRES="$res" tests/vm.sh start "$n" - "$disk" nosb usb >/dev/null
export VMRES="$res"
V="tests/vm.sh q $n"; M="docker run --rm -v $P:/p -w /p edios-tools python3 .testtmp/region.py"
sleep 45; $V shot /t/out/gdm.png
echo "== $res"
$M ".testtmp/vm/$n/gdm.png" $((W/2-120)) $((H-80)) $((W/2+120)) $((H-4)) | sed 's/^/GDM-Logo: /'
$V click $((W/2)) $((H/2-49)); sleep 2; $V typeus "$pw"; $V key ret; sleep 30
$V key esc; sleep 1; $V key esc; sleep 2      # Uebersicht zu, Secure-Boot-Hinweis "Spaeter"
$V shot /t/out/desktop.png
$M ".testtmp/vm/$n/desktop.png" $((W/2-W/5)) $((H/2-H/4)) $((W/2+W/5)) $((H/2+H/4)) 30 | sed 's/^/Hintergrund-Logo: /'
# Info-Seite (Einstellungen -> System -> Info), maximiert; Inhaltsbereich rechts der Seitenleiste
$V key alt-f2; sleep 2; $V typeus "gnome-control-center system about"; $V key ret; sleep 8
$V key meta_l-up; sleep 3; $V shot /t/out/info.png
docker run --rm -v $P:/p -w /p edios-tools python3 -c "
from PIL import Image, ImageChops
im=Image.open('.testtmp/vm/$n/info.png').convert('RGB'); W,H=im.size; px=im.load()
y=H//2
# Seitenleiste: erster Spaltenwechsel von grau (Seitenleiste) zu hell (Inhalt) in Bildmitte
xs=[x for x in range(60,W//2) if abs(sum(px[x,y])-sum(px[x-1,y]))>25]
x0=xs[-1] if xs else 0
# Dock rechts: Ende des Inhalts = erste dunkle Spalte von rechts
x1=W-1
while x1>W//2 and sum(px[x1,y])<300: x1-=1
r=im.crop((x0+5,60,x1-5,int(H*0.45))); bg=r.getpixel((0,0))
d=ImageChops.difference(r,Image.new('RGB',r.size,bg)).convert('L').point(lambda v:255 if v>40 else 0).getbbox()
l=d[0]+x0+5; rr=d[2]+x0+5-1
print('Info-Logo: Inhaltsbereich %d-%d (Mitte %.1f), Logo %d-%d (Mitte %.1f) -> Versatz %+.1f px' % (x0,x1,(x0+x1)/2,l,rr,(l+rr)/2,(l+rr)/2-(x0+x1)/2))
"
tests/vm.sh stop "$n"
