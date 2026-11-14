#!/bin/sh
# Test-Hilfe (laeuft IM Gast als root, ueber tests/vm.sh sh): Befehl in der grafischen Sitzung eines Benutzers.
#   asuser BENUTZER 'BEFEHL'
u="$1"; shift
P=$(ps -o pid,user,args | awk -v u="$u" '$2==u && $3=="/usr/bin/gnome-shell" {print $1}' | head -n1)
[ -n "$P" ] || { echo "keine gnome-shell fuer $u" >&2; exit 1; }
env="$(tr '\0' '\n' < /proc/$P/environ | grep -E '^(DBUS_SESSION_BUS_ADDRESS|WAYLAND_DISPLAY|XDG_RUNTIME_DIR|DISPLAY|LANG|LANGUAGE|XDG_SESSION_TYPE|XDG_CURRENT_DESKTOP)=' | sed "s/'/'\\\\''/g; s/=\(.*\)/='\1'/" | tr '\n' ' ')"
exec su "$u" -s /bin/sh -c "export $env; $*"
