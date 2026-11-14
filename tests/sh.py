#!/usr/bin/env python3
"""ediOS Test-VM: Befehl ueber den seriellen Testkanal (ttyS1) als root ausfuehren.
Nur fuer Test-Platten, auf denen tests/disk.sh den Kanal eingerichtet hat (nie in der ISO).
  sh.py 'BEFEHL' [TIMEOUT]   gibt die Ausgabe aus, Rueckgabe = Rueckgabe des Befehls
"""
import re
import socket
import sys
import time
import uuid

cmd = sys.argv[1]
timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 120
mark = "@@END" + uuid.uuid4().hex[:8]
s = socket.socket(socket.AF_UNIX)
s.connect("/t/out/cmd.sock")
s.settimeout(1)
# Befehl als base64 in kurzen Zeilen schicken (die Konsole liest zeilenweise, max. 4096 Zeichen)
import base64
b = base64.b64encode(cmd.encode()).decode()
lines = "\n".join(b[i:i + 64] for i in range(0, len(b), 64))
s.sendall(("base64 -d > /tmp/.edios-cmd <<'@@B64'\n%s\n@@B64\n(sh /tmp/.edios-cmd) 2>&1; echo %s $?\n"
           % (lines, mark)).encode())
buf = b""
t0 = time.time()
while time.time() - t0 < timeout:
    try:
        d = s.recv(65536)
    except socket.timeout:
        continue
    if not d:
        break
    buf += d
    txt = buf.decode("utf-8", "replace")
    m = re.search(re.escape(mark) + r" (\d+)\r?\n", txt)
    if m:
        out = txt[:m.start()]
        # falls die Konsole die Eingabe zurueckgibt: Befehlszeile entfernen
        j = out.rfind(mark + " $?")
        if j >= 0:
            out = out[out.find("\n", j) + 1:]
        sys.stdout.write(out)
        sys.exit(int(m.group(1)))
sys.stdout.write(buf.decode("utf-8", "replace"))
sys.exit("TIMEOUT")
