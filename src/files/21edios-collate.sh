# ediOS (GPL-3.0-or-later): Alpines 20locale.sh setzt LC_COLLATE=C. Zusammen mit LANG=de_DE.UTF-8 ergibt das eine
# gemischte Spracheinstellung, bei der C++-Programme (gtkmm, z. B. der Systemmonitor) unter musl ganz auf Englisch
# zurueckfallen. musl sortiert ohnehin immer wie "C", darum hier LC_COLLATE = LANG (gleiches Verhalten, deutsche Texte).
case "${LANG:-}" in
''|C|C.*|POSIX) ;;
*) [ "${LC_COLLATE:-C}" != C ] || export LC_COLLATE="$LANG" ;;
esac
