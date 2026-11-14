#!/bin/sh
# ediOS: Upstream-Teile, die (noch) nicht als Alpine-/ediOS-Paket kommen. Laeuft im Bau-Container. GPL-3.0-or-later
#   Yaru (nur GTK-Fensterstil, -Dicons=false), Dash to Dock, AppIndicator, Ubuntu- und
#   OpenDyslexic-Schrift, hyfetch (pipx unter /opt/pipx).
# Ergebnis: $CACHE/assets/root/ (Dateibaum, kommt ins Overlay). Wird nur neu gebaut, wenn sich die
# Versionen in config.sh aendern. Downloads werden gegen build/assets.sha256 geprueft (beim ersten
# Laden einer neuen Version wird die Pruefsumme dort eingetragen und muss committet werden).
set -eu
P=/edios
. "$P/config.sh"
CACHE="$P/cache"
A="$CACHE/assets"
DL="$CACHE/dl"
SUMS="$P/build/assets.sha256"
mkdir -p "$A" "$DL"
touch "$SUMS"

stamp="$(printf '%s\n' "$YARU_COMMIT" "$DASH_TO_DOCK_SHA256" "$APPINDICATOR_SHA256" "$OPENDYSLEXIC_TAG" \
	"$UBUNTU_FONT_COMMIT" "$HYFETCH_VERSION" "$(cat "$P/build/assets.sh")" | sha256sum | cut -c1-16)"
if [ -f "$A/stamp" ] && [ "$(cat "$A/stamp")" = "$stamp" ] && [ -d "$A/root" ]; then
	echo "assets: aktuell ($stamp)"; exit 0
fi

# fetch URL DATEI [SHA256]: laedt in den Cache und prueft die Pruefsumme
fetch() {
	_url="$1"; _out="$DL/$2"; _want="${3:-}"
	[ -s "$_out" ] || { curl -fsSL --retry 3 -o "$_out.part" "$_url" && mv "$_out.part" "$_out"; }
	_have="$(sha256sum "$_out" | cut -d' ' -f1)"
	[ -n "$_want" ] || _want="$(awk -v n="$2" '$2 == n {print $1}' "$SUMS")"
	if [ -z "$_want" ]; then
		echo "$_have  $2" >> "$SUMS"; echo "assets: neue Pruefsumme eingetragen: $2"
	elif [ "$_have" != "$_want" ]; then
		echo "assets: FEHLER Pruefsumme $2: $_have != $_want" >&2; rm -f "$_out"; exit 1
	fi
}

R="$A/root.new"
rm -rf "$R" "$A/build"
mkdir -p "$R" "$A/build"

# --- Yaru: nur GTK-Fensterstil (Icons und Cursor kommen von Adwaita) ---
fetch "https://github.com/ubuntu/yaru/archive/$YARU_COMMIT.tar.gz" "yaru-$YARU_COMMIT.tar.gz"
tar -C "$A/build" -xzf "$DL/yaru-$YARU_COMMIT.tar.gz"
(
	cd "$A/build/yaru-$YARU_COMMIT"
	meson setup _b --prefix=/usr -Dicons=false -Dgnome-shell=false -Dgtksourceview=false \
		-Dmetacity=false -Dsounds=false -Dsessions=false -Daccent-colors=[] >/dev/null
	meson compile -C _b >/dev/null
	DESTDIR="$R" meson install -C _b --no-rebuild >/dev/null
)
# nur die beiden Themes behalten, die ediOS nutzt
find "$R/usr/share/themes" -mindepth 1 -maxdepth 1 ! -name Yaru ! -name Yaru-dark -exec rm -rf {} +
rm -rf "$R/usr/share/icons" "$R/usr/share/sounds" "$R/usr/share/gnome-shell"
[ -d "$R/usr/share/themes/Yaru/gtk-3.0" ] && [ -d "$R/usr/share/themes/Yaru/gtk-4.0" ] || { echo "assets: Yaru GTK fehlt" >&2; exit 1; }

# --- GNOME-Shell-Erweiterungen (fertige Pakete von den Projekten, GNOME 45-51) ---
ext() {   # ZIP-URL UUID SHA256
	fetch "$1" "$2.zip" "$3"
	d="$R/usr/share/gnome-shell/extensions/$2"
	mkdir -p "$d"
	python3 -I -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$DL/$2.zip" "$d"
	mkdir -p "$R/usr/share/glib-2.0/schemas"
	cp "$d"/schemas/*.gschema.xml "$R/usr/share/glib-2.0/schemas/"
	glib-compile-schemas "$d/schemas"     # die Erweiterung laedt ihr eigenes gschemas.compiled
	find "$d" -type d -exec chmod 755 {} +; find "$d" -type f -exec chmod 644 {} +
}
ext "$DASH_TO_DOCK_URL" dash-to-dock@micxgx.gmail.com "$DASH_TO_DOCK_SHA256"
ext "$APPINDICATOR_URL" appindicatorsupport@rgcjonas.gmail.com "$APPINDICATOR_SHA256"

# --- Schriften ---
mkdir -p "$R/usr/share/fonts/opendyslexic" "$R/usr/share/licenses/opendyslexic" \
	"$R/usr/share/fonts/ubuntu" "$R/usr/share/licenses/ubuntu-font"
for f in OpenDyslexic-Regular OpenDyslexic-Bold OpenDyslexic-Italic OpenDyslexic-Bold-Italic; do
	fetch "https://raw.githubusercontent.com/antijingoist/opendyslexic/$OPENDYSLEXIC_TAG/compiled/$f.otf" "$f.otf"
	install -m644 "$DL/$f.otf" "$R/usr/share/fonts/opendyslexic/"
done
fetch "https://raw.githubusercontent.com/antijingoist/opendyslexic/$OPENDYSLEXIC_TAG/OFL.txt" opendyslexic-OFL.txt
install -m644 "$DL/opendyslexic-OFL.txt" "$R/usr/share/licenses/opendyslexic/OFL.txt"
for f in Ubuntu-Regular Ubuntu-Bold Ubuntu-Italic Ubuntu-BoldItalic Ubuntu-Light Ubuntu-LightItalic \
	Ubuntu-Medium Ubuntu-MediumItalic; do
	fetch "https://raw.githubusercontent.com/google/fonts/$UBUNTU_FONT_COMMIT/ufl/ubuntu/$f.ttf" "$f.ttf"
	install -m644 "$DL/$f.ttf" "$R/usr/share/fonts/ubuntu/"
done
fetch "https://raw.githubusercontent.com/google/fonts/$UBUNTU_FONT_COMMIT/ufl/ubuntu/UFL.txt" ubuntu-UFL.txt
install -m644 "$DL/ubuntu-UFL.txt" "$R/usr/share/licenses/ubuntu-font/UFL.txt"

# --- hyfetch (Python, per pipx nach /opt/pipx; absolute Pfade, darum direkt dort bauen) ---
doas rm -rf /opt/pipx; doas mkdir -p /opt/pipx; doas chown "$(id -u):$(id -g)" /opt/pipx
mkdir -p "$A/build/bin"
PIPX_HOME=/opt/pipx PIPX_BIN_DIR="$A/build/bin" PIPX_MAN_DIR="$A/build/man" \
	pipx install --quiet "hyfetch==$HYFETCH_VERSION" >/dev/null
mkdir -p "$R/opt" "$R/usr/local/bin" "$R/usr/bin"
cp -a /opt/pipx "$R/opt/"
for b in hyfetch hyfetch.rs hyfetch.v1 neowofetch; do
	[ -e "/opt/pipx/venvs/hyfetch/bin/$b" ] && ln -sf "/opt/pipx/venvs/hyfetch/bin/$b" "$R/usr/local/bin/$b"
done
ln -sf /opt/pipx/venvs/hyfetch/bin/hyfetch "$R/usr/bin/hyfetch"
/opt/pipx/venvs/hyfetch/bin/hyfetch --version >/dev/null 2>&1 || echo "assets: Warnung: hyfetch --version scheiterte" >&2

rm -rf "$A/root" "$A/build"
mv "$R" "$A/root"
echo "$stamp" > "$A/stamp"
echo "assets: fertig ($stamp), $(du -sh "$A/root" | cut -f1)"
