# ediOS: Shell-Anmeldungen (Konsole, SSH) bekommen die Systemsprache aus /etc/locale.conf, wenn keine gesetzt ist.
case "${LANG:-}" in
''|C|C.UTF-8|POSIX)
	_l="$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null | tr -d '"' | head -n 1)"
	export LANG="${_l:-en_US.UTF-8}"
	unset _l ;;
esac
