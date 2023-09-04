#!/bin/bash
# Downloads and installs TinyTinyRSS and plugins
set -e

TTRSS_GIT_REPO=https://git.tt-rss.org/fox/tt-rss.git/
TTRSS_DEST=/var/www
PLUGINS=(
	# "https://github.com/dasmurphy/tinytinyrss-fever-plugin/archive/master.tar.gz;plugins;fever"
	"https://github.com/levito/tt-rss-feedly-theme.git#theme;name=feedly;branch=dist"
	"https://github.com/DigitalDJ/tinytinyrss-fever-plugin.git#plugin;name=fever"
)

# workaround for arm/v7 OOM
echo "Building for $TARGETPLATFORM ..."
if [[ "$TARGETPLATFORM" == "linux/arm/v7" ]]; then
	git config --global pack.packSizeLimit 1g
	git config --global pack.deltaCacheSize 1g
	git config --global pack.windowMemory 1g
	git config --global core.packedGitLimit 1g
	git config --global core.packedGitWindowSize 1g
fi

# Parses an URL fragment and returns each pair on a newline
# (easy to iterate using `read -r line`)
# Accepted format: #key1=value;key2=value...
function parse_url_fragment() {
	local pair= PAIRS=()
	if [[ "$1" =~ ^[^#]*#(.+)$ ]]; then
		IFS=';' read -ra PAIRS <<< "${BASH_REMATCH[1]}"
		for pair in "${PAIRS[@]}"; do
			echo "$pair"
		done
	fi || true
}

# clone tt-rss
rm -rf "$TTRSS_DEST"
git clone "$TTRSS_GIT_REPO" "$TTRSS_DEST"

# install plugins
for plugin in "${PLUGINS[@]}"; do
	TYPE=
	REPO=${plugin%%#*}
	CLONE_ARGS=()
	while IFS= read -r line; do
		case $line in
			plugin) TYPE=plugins; ;;
			theme) TYPE=themes; ;;
			name=*) NAME=${line#*=}; ;;
			branch=*) CLONE_ARGS+=(-b "${line#*=}"); ;;
		esac
	done < <( parse_url_fragment "$plugin" )

	# Download the plugin's archive
	_DEST="${TTRSS_DEST}/${TYPE}"
	_CLONE_DEST="$_DEST/${NAME}"
	if [[ "$TYPE" == "themes" ]]; then
		# use a separate subdir for cloning themes
		_CLONE_DEST="${_DEST}/_${NAME}.git"
	fi
	echo "Cloning $NAME to ${_CLONE_DEST}..."
	mkdir -p "$(dirname "$_CLONE_DEST")"
	git clone "${CLONE_ARGS[@]}" "$REPO" "$_CLONE_DEST"

	if [[ "$TYPE" == "themes" ]]; then
		# copy the theme's files (everything prefixed by $NAME) to themes/ dir
		cp -rf "$_CLONE_DEST/$NAME"* "$_DEST/"
	fi
	ls -lh "$_DEST"
done

cd "$TTRSS_DEST"
cp -f config.php-dist config.php
# change the default owner of www
chown "$CONT_USER:$CONT_USER" /var/www -R

