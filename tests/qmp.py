#!/usr/bin/env python3
"""ediOS Test-VM steuern (QMP). Laeuft im Container edios-testvm.
  qmp.py shot DATEI.png          Bildschirmfoto
  qmp.py key ctrl-alt-t          Tastenkombination (QEMU-Namen, mit - verbunden)
  qmp.py type "text"             Text tippen (deutsche Tastatur im Gast: y/z, Sonderzeichen beachten)
  qmp.py typeus "text"           Text tippen mit US-Tastatur (GRUB, MOK-Manager, Konsole)
  qmp.py click X Y [right]       Mausklick an Bildschirmposition (Pixel, bei 1280x800)
  qmp.py move X Y
  qmp.py hmp "info status"       beliebiger Monitor-Befehl
  qmp.py quit
"""
import json
import socket
import sys
import time

SOCK = "/run/qmp.sock"
import os
W, H = (int(v) for v in os.environ.get("VMRES", "1280x800").split("x"))


class QMP:
    def __init__(self):
        self.s = socket.socket(socket.AF_UNIX)
        self.s.connect(SOCK)
        self.f = self.s.makefile("rw")
        json.loads(self.f.readline())
        self.cmd("qmp_capabilities")

    def cmd(self, name, **args):
        self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
        self.f.flush()
        while True:
            r = json.loads(self.f.readline())
            if "return" in r or "error" in r:
                if "error" in r:
                    sys.exit("QMP-Fehler: %s" % r["error"])
                return r["return"]


# Zeichen -> QEMU-Tastenname fuer DEUTSCHE Tastaturbelegung im Gast
DE = {" ": "spc", "\n": "ret", "-": "slash", ".": "dot", ",": "comma", "_": "shift-slash",
      "y": "z", "z": "y", "Y": "shift-z", "Z": "shift-y", "!": "shift-1", "?": "shift-minus",
      "/": "shift-7", ":": "shift-dot", "@": "alt_r-q", "+": "bracket_right", "#": "backslash",
      ";": "shift-comma", "|": "alt_r-less", "'": "shift-backslash", '"': "shift-2", "=": "shift-0",
      "(": "shift-8", ")": "shift-9", "*": "shift-bracket_right", "&": "shift-6", "$": "shift-4",
      ">": "shift-less", "<": "less", "~": "alt_r-bracket_right", "%": "shift-5",
      "[": "alt_r-8", "]": "alt_r-9", "{": "alt_r-7", "}": "alt_r-0", "\\": "alt_r-minus"}


def keys_for(ch):
    if ch in DE:
        return DE[ch]
    if ch.isdigit() or ("a" <= ch <= "z"):
        return ch
    if "A" <= ch <= "Z":
        return "shift-" + ch.lower()
    raise SystemExit("Zeichen nicht unterstuetzt: %r" % ch)


def send(q, combo):
    keys = [{"type": "qcode", "data": k} for k in combo.split("-")]
    q.cmd("send-key", keys=keys)
    time.sleep(0.08)


def main():
    a = sys.argv[1:]
    q = QMP()
    if a[0] == "shot":
        q.cmd("screendump", filename=a[1], format="png")
    elif a[0] == "key":
        for combo in a[1:]:
            send(q, combo)
    elif a[0] == "type":
        for ch in a[1]:
            send(q, keys_for(ch))
    elif a[0] == "typeus":
        us = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash", ",": "comma",
              ":": "shift-semicolon", ";": "semicolon", '"': "shift-apostrophe", "'": "apostrophe",
              "|": "shift-backslash", "$": "shift-4", "(": "shift-9", ")": "shift-0", "=": "equal",
              "_": "shift-minus", "&": "shift-7", ">": "shift-dot", "<": "shift-comma", "*": "shift-8",
              "@": "shift-2", "!": "shift-1", "?": "shift-slash", "+": "shift-equal", "#": "shift-3"}
        for ch in a[1]:
            send(q, us.get(ch) or ("shift-" + ch.lower() if ch.isupper() else ch))
    elif a[0] == "size":
        print(W, H)
    elif a[0] in ("click", "move"):
        x, y = int(a[1]), int(a[2])
        ev = [{"type": "abs", "data": {"axis": "x", "value": int(x * 32767 / (W - 1))}},
              {"type": "abs", "data": {"axis": "y", "value": int(y * 32767 / (H - 1))}}]
        q.cmd("input-send-event", events=ev)
        if a[0] == "click":
            btn = "right" if len(a) > 3 and a[3] == "right" else "left"
            time.sleep(0.1)
            q.cmd("input-send-event", events=[{"type": "btn", "data": {"down": True, "button": btn}}])
            time.sleep(0.08)
            q.cmd("input-send-event", events=[{"type": "btn", "data": {"down": False, "button": btn}}])
    elif a[0] == "hmp":
        print(q.cmd("human-monitor-command", **{"command-line": a[1]}))
    elif a[0] == "quit":
        q.cmd("quit")


if __name__ == "__main__":
    main()
