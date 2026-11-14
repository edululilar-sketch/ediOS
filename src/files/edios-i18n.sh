# ediOS: Sprache fuer Shell-Programme (Deutsch / English). GPL-3.0-or-later
# Benutzung:   . /usr/share/edios/i18n.sh
#              t "Deutscher Text" "English text"      -> gibt den Text in der aktuellen Sprache aus
# Sprache: EDIOS_LANG (de|en), sonst LC_ALL/LC_MESSAGES/LANG, sonst /etc/locale.conf. Alles ausser
# Deutsch ergibt Englisch.
# shellcheck shell=sh

edios_lang() {
	_l="${EDIOS_LANG:-}"
	[ -n "$_l" ] || _l="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
	case "$_l" in ''|C|C.*|POSIX)
		_l="$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null | tr -d '"' | head -n 1)" ;;
	esac
	case "$_l" in de*) echo de ;; *) echo en ;; esac
}

EDIOS_L="$(edios_lang)"

t() {
	if [ "$EDIOS_L" = de ]; then printf '%s' "$1"; else printf '%s' "$2"; fi
}
