#!/bin/sh
# Test-Hilfe (laeuft IM Gast als root): seriellen Testkanal auf ttyS1 starten und Hilfsskripte ablegen.
# Wird nur in Test-VMs per Hand gestartet:  doas sh -c "$(wget -qO- 10.0.2.2:8000/k)"
# (tests/vm.sh stellt tests/ im VM-Container per HTTP bereit). Nie Teil der ISO.
wget -qO /usr/local/bin/asuser http://10.0.2.2:8000/guest-asuser.sh && chmod 755 /usr/local/bin/asuser
[ -e /run/edios-testkanal ] && exit 0; : > /run/edios-testkanal
setsid sh -c ': ediOS-Testkanal; while :; do stty -F /dev/ttyS1 raw -echo; sh </dev/ttyS1 >/dev/ttyS1 2>&1; done' >/dev/null 2>&1 &
echo Testkanal bereit
