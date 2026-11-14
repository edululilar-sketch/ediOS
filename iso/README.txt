ediOS @VERSION@ - write to a USB stick and start
===============================================

File:     @ISO@
Checksum: SHA256SUMS (SHA-256), signed: SHA256SUMS.sig
Guide with pictures: @URL@ (docs/en/installation.md)
Deutsch: LIESMICH.txt

What you need
-------------
- a USB stick with at least 4 GB (EVERYTHING on it will be deleted)
- a PC with UEFI and at least 4 GB of memory (8 GB recommended)
- Windows: Rufus (https://rufus.ie) or balenaEtcher (https://etcher.balena.io)

Check the checksum (recommended)
--------------------------------
Windows (PowerShell, in the Downloads folder):
   Get-FileHash .\@ISO@ -Algorithm SHA256
Linux/macOS:
   sha256sum -c SHA256SUMS --ignore-missing
The number shown must match the one in SHA256SUMS exactly.

Write with Rufus (GPT / UEFI)
-----------------------------
1. Plug in the stick, start Rufus.
2. "Device": choose the USB stick. Look closely, it must not be a hard disk!
3. "Boot selection": click SELECT and choose @ISO@.
4. "Partition scheme": GPT, "Target system": UEFI (non CSM).
5. Click START. Rufus asks how to write the image:
   choose "Write in DD Image mode" (recommended).
   If the stick does not start: try again with "Write in ISO Image mode".
6. Confirm the warning "all data will be destroyed" with OK, wait until "READY".

balenaEtcher: "Flash from file" -> @ISO@ -> choose the stick -> "Flash!".
Linux terminal:  sudo dd if=@ISO@ of=/dev/sdX bs=4M status=progress conv=fsync
(/dev/sdX is the stick, NOT the hard disk - check with lsblk first.)

Start from the stick
--------------------
- Restart the PC and open the boot menu (depending on the maker F12, F11, F10, F8 or Esc),
  choose the USB stick (prefer "UEFI: ...").
- In the ediOS boot menu choose "English" or "Deutsch".
  "load completely into RAM": ediOS is copied into memory at startup, afterwards the stick can be
  removed (needs at least 8 GB of RAM, otherwise ediOS keeps running from the stick).
- At the first start the setup asks for language, keyboard, time zone, font and dock.
  The installer copies these choices to the installed ediOS.

Secure Boot
-----------
ediOS starts with Secure Boot ON and OFF. With Secure Boot ON the ediOS key has to be enrolled
ONCE per PC (ediOS starts via "shim", Debian's boot loader signed by Microsoft). With Secure Boot
OFF there is nothing to do.

Way A - Secure Boot is ON (enroll the key at startup):
 1. Start from the stick. First "Verification failed: (0x1A) Security Violation" appears.
    That is expected the first time. Press Enter on OK.
 2. A blue screen "Shim UEFI key management" appears: press a key.
 3. Choose "Enroll key from disk".
 4. Choose the drive (usually called "EDIOS"), then the file "edios-mok.der".
 5. Choose "Continue", then "Yes".
 6. Choose "Reboot". ediOS now starts with Secure Boot.

Way B - Secure Boot is OFF (enroll the key from the installed ediOS):
 1. Open "Secure Boot" in the app overview and choose "Enroll key".
    In a terminal:  sudo mokutil --import /usr/share/edios/secureboot/edios-mok.der
 2. Choose a one-time password (only lowercase letters a-x and digits).
 3. Restart. Blue screen "Shim UEFI key management": press a key.
 4. "Enroll MOK" > "Continue" > "Yes" > type the one-time password > "Reboot".
 5. Then turn Secure Boot on in the UEFI setup (usually F2 or Del at startup).

The genuine ediOS key (in the MOK manager under "View key"):
  name "ediOS Secure Boot Signing Key (MOK) 2026-11", SHA-1 2F:82:45:17:37:35:8A:AB:BF:B1 ...
If it does not work: choose "Enroll ediOS key" in the boot menu (way A from step 3) or turn
Secure Boot off in the UEFI setup. Windows keeps starting normally.

Install
-------
In the live system start "Install ediOS" (first icon in the dock). The installer shows every disk
with size, model, connection (USB/internal) and what was found on it (e.g. Windows).
ALL data on the chosen disk is deleted; to confirm you have to type YES.
The ediOS stick itself is never offered. If a disk is currently open (mounted), the installer
unmounts it first.

Dual boot with Windows: the safest way is an EXTERNAL disk (USB). The boot loader only goes onto
that disk; Windows and the PC's boot order stay unchanged.
To start: plug in the disk, open the boot menu (F12/F11/Esc), choose the disk.

After the installation
----------------------
- Updates: "Update ediOS" in the app overview (Alpine and ediOS packages, Flatpak apps).
- Apps like Steam and Discord: "ediOS Apps" (Flathub).
- Commands from guides on the internet that use "sudo" work (sudo forwards to doas).

Known issues
------------
- Secure Boot: the kernel stays at the version of the ISO (it is signed). Kernel updates come
  with a new ediOS version, all other updates as usual.
- NVIDIA: only the free nouveau driver (no proprietary NVIDIA driver).
- Report bugs: @URL@/issues
