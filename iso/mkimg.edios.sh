# ediOS mkimage-Profil (wird nach mkimg.base.sh geladen und ersetzt dort einige Funktionen). GPL-3.0-or-later
# Eingaben aus der Umgebung (build/inner.sh): EDIOS_* und die Werte aus config.sh.
# shellcheck shell=sh disable=SC2034,SC2154

profile_edios() {
	profile_base
	title="ediOS"
	desc="ediOS $EDIOS_VERSION (live system with installer)"
	profile_abbrev="edios"
	image_name="edios"
	image_ext="iso"
	arch="x86_64"
	output_format="iso"
	output_filename="edios-$EDIOS_FILEVER-x86_64.iso"
	kernel_addons=
	modloop_addons=
	boot_addons="amd-ucode intel-ucode"
	initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
	initfs_features="$initfs_features kms"
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage quiet"
	kernel_cmdline=""
	apks="$(cat "$EDIOS_APKS")"
	apkovl="genapkovl-edios.sh"
	hostname="edios"
	modloop_sign=yes
	syslinux_timeout=30
}

gen_volid() {
	printf '%s' "$EDIOS_VOLID"
}

# --- Kernel: wie mkimg.base.sh, danach den signierten Kernel einsetzen ---
build_kernel() {
	local _flavor="$2" _modloopsign= _add
	shift 3
	local _pkgs="$@"
	if [ "$modloop_sign" = "yes" ]; then
		_modloopsign="--modloopsign --apk-pubkey $_abuild_pubkey"
	fi
	update-kernel \
		$_hostkeys \
		$_modloopsign \
		--media \
		--cache-dir "$APKROOT/etc/apk/cache" \
		--keys-dir "$APKROOT/etc/apk/keys" \
		--flavor "$_flavor" \
		--arch "$ARCH" \
		--package "$_pkgs" \
		--feature "$initfs_features" \
		--modloopfw "$modloopfw" \
		--repositories-file "$APKROOT/etc/apk/repositories" \
		"$DESTDIR"
	for _add in $boot_addons; do
		apk fetch --root "$APKROOT" --quiet --stdout $_add | tar -C "${DESTDIR}" -zx boot/
	done
	# Nur ersetzen, wenn der Kernel genau die erwartete (unsignierte) Version ist
	local _h
	_h="$(sha256sum < "$DESTDIR/boot/vmlinuz-$_flavor" | cut -d' ' -f1)"
	if [ "$_h" != "$(cat "$EDIOS_SB/vmlinuz-lts.unsigned.sha256")" ]; then
		error "Kernel auf der ISO ist nicht linux-lts $KERNEL_VERSION (Mirror neuer? config.sh pruefen)"
		return 1
	fi
	cp "$EDIOS_SB/vmlinuz-lts" "$DESTDIR/boot/vmlinuz-$_flavor"
}

section_kernels() {
	local _f _pkgs
	for _f in $kernel_flavors; do
		_pkgs="linux-$_f linux-firmware wireless-regdb"
		local id=$( (echo "$initfs_features::$_hostkeys::$(cat "$EDIOS_SB/vmlinuz-lts.signed.sha256")"; \
			apk fetch --root "$APKROOT" --simulate alpine-base $_pkgs | sort) | checksum)
		build_section kernel $ARCH $_f $id $_pkgs
	done
}

# --- GRUB-Menue der ISO (nur ASCII: GRUB hat hier keine Unicode-Schrift) ---
grub_gen_config() {
	cat <<- EOF
	set default=0
	set timeout=8
	insmod all_video
	insmod gfxterm
	if loadfont unicode; then
		terminal_output gfxterm
	fi
	EOF
	cat "$EDIOS_SB/grub-hilfe.cfg"
	local name lang extra
	for entry in "Deutsch|de|" "English|en|" \
		"Deutsch - komplett in den RAM laden|de|edios.toram" \
		"English - load completely into RAM|en|edios.toram" \
		"Deutsch - einfache Grafik (nomodeset)|de|nomodeset" \
		"English - safe graphics (nomodeset)|en|nomodeset"; do
		name="${entry%%|*}"; extra="${entry##*|}"; lang="${entry#*|}"; lang="${lang%%|*}"
		cat <<- EOF

		menuentry "ediOS $EDIOS_VERSION - $name" {
			if linux /boot/vmlinuz-lts $initfs_cmdline $kernel_cmdline edios.lang=$lang $extra; then
				initrd /boot/amd-ucode.img /boot/intel-ucode.img /boot/initramfs-lts
			else
				edios_sb_hilfe
			fi
		}
		EOF
	done
	cat "$EDIOS_SB/grub-extra.cfg"
}

syslinux_gen_config() {
	echo "TIMEOUT ${syslinux_timeout:-30}"
	echo "PROMPT 1"
	echo "DEFAULT edios"
	cat <<- EOF

	LABEL edios
		MENU LABEL ediOS $EDIOS_VERSION - Deutsch
		KERNEL /boot/vmlinuz-lts
		INITRD /boot/amd-ucode.img,/boot/intel-ucode.img,/boot/initramfs-lts
		APPEND $initfs_cmdline $kernel_cmdline edios.lang=de

	LABEL english
		MENU LABEL ediOS $EDIOS_VERSION - English
		KERNEL /boot/vmlinuz-lts
		INITRD /boot/amd-ucode.img,/boot/intel-ucode.img,/boot/initramfs-lts
		APPEND $initfs_cmdline $kernel_cmdline edios.lang=en
	EOF
}

# --- EFI: shim -> signiertes GRUB (statt des unsignierten GRUB von mkimg.base.sh) ---
build_edios_efi() {
	local d
	for d in efi/boot efi/edios; do
		mkdir -p "$DESTDIR/$d"
		cp "$EDIOS_SB/grubx64.efi" "$EDIOS_SB/mmx64.efi" "$DESTDIR/$d/"
		printf 'search --no-floppy --set=root --label "%s"\nset prefix=($root)/boot/grub\nconfigfile ($root)/boot/grub/grub.cfg\n' \
			"$EDIOS_VOLID" > "$DESTDIR/$d/grub.cfg"
	done
	cp "$EDIOS_SB/shimx64.efi" "$DESTDIR/efi/boot/bootx64.efi"
	cp "$EDIOS_SB/shimx64.efi" "$DESTDIR/efi/edios/shimx64.efi"
	if [ -f "$EDIOS_SB/edios-mok.der" ]; then
		cp "$EDIOS_SB/edios-mok.der" "$DESTDIR/efi/edios/edios-mok.der"
		cp "$EDIOS_SB/edios-mok.der" "$DESTDIR/edios-mok.der"
	fi
	cp "$EDIOS_DOC/LIESMICH.txt" "$EDIOS_DOC/README.txt" "$DESTDIR/"
}

section_grub_efi() {
	[ "$ARCH" = x86_64 ] || return 0
	build_section grub_cfg boot/grub/grub.cfg $(grub_gen_config | checksum)
	build_section edios_efi $( (cat "$EDIOS_SB"/*.sha256; sha256sum "$EDIOS_SB/grubx64.efi" "$EDIOS_DOC/LIESMICH.txt" "$EDIOS_DOC/README.txt"; echo "$EDIOS_VOLID") | checksum)
}

# --- ISO: wie mkimg.base.sh, aber EFI-Abbild gross genug und mit Namen "EDIOS" (MOK-Manager) ---
create_image_iso() {
	local ISO="${OUTDIR}/${output_filename}"
	local img="${DESTDIR}/boot/grub/efi.img"
	rm -f "$img"
	mkdir -p "${DESTDIR}/boot/grub"
	dd if=/dev/zero of="$img" bs=1M count=16 status=none
	mkfs.vfat -n EDIOS "$img" >/dev/null
	mmd -i "$img" ::/EFI ::/EFI/BOOT ::/EFI/edios
	mcopy -i "$img" "${DESTDIR}"/efi/boot/bootx64.efi ::/EFI/BOOT/BOOTX64.EFI
	mcopy -i "$img" "${DESTDIR}"/efi/boot/grubx64.efi "${DESTDIR}"/efi/boot/mmx64.efi "${DESTDIR}"/efi/boot/grub.cfg ::/EFI/BOOT/
	mcopy -i "$img" "${DESTDIR}"/efi/edios/shimx64.efi "${DESTDIR}"/efi/edios/grubx64.efi \
		"${DESTDIR}"/efi/edios/mmx64.efi "${DESTDIR}"/efi/edios/grub.cfg ::/EFI/edios/
	if [ -f "${DESTDIR}/edios-mok.der" ]; then
		mcopy -i "$img" "${DESTDIR}"/efi/edios/edios-mok.der ::/EFI/edios/
		mcopy -i "$img" "${DESTDIR}"/edios-mok.der ::/edios-mok.der
	fi
	mcopy -i "$img" "${DESTDIR}"/LIESMICH.txt ::/LIESMICH.txt
	mcopy -i "$img" "${DESTDIR}"/README.txt ::/README.txt

	xorrisofs \
		-quiet \
		-output "$ISO" \
		-full-iso9660-filenames \
		-joliet \
		-rational-rock \
		-sysid LINUX \
		-volid "$(gen_volid)" \
		-isohybrid-mbr "${DESTDIR}/boot/syslinux/isohdpfx.bin" \
		-eltorito-boot boot/syslinux/isolinux.bin \
		-eltorito-catalog boot/syslinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		-eltorito-alt-boot \
		-e boot/grub/efi.img \
		-no-emul-boot \
		-isohybrid-gpt-basdat \
		-follow-links \
		${iso_opts} \
		"${DESTDIR}"
}
