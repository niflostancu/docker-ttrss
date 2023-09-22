#!/bin/bash
# Downloads and installs TinyTinyRSS and plugins
set -e
shopt -s extglob

TTRSS_GIT_REPO=https://git.tt-rss.org/fox/tt-rss.git/
TTRSS_DEST=/var/www
PLUGINS=(
	# "https://github.com/dasmurphy/tinytinyrss-fever-plugin/archive/master.tar.gz;plugins;fever"
	"https://github.com/levito/tt-rss-feedly-theme.git#theme;name=feedly;branch=dist"
	"https://github.com/ltguillaume/feedmei.git#theme;name=feedmei;match=themes.local/*;branch=main"
	"https://github.com/ltguillaume/feedmei.git#plugin;name=feedmei;match=plugins.local/*/;branch=main"
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
	MATCH=
	FOLDER_NAME=
	CLONE_ARGS=()
	TEMP_CLONE=
	while IFS= read -r line; do
		case $line in
			plugin) TYPE=plugins; ;;
			theme) TYPE=themes; TEMP_CLONE=1; ;;
			name=*) NAME=${line#*=}; ;;
			foldername=*) FOLDER_NAME=${line#*=}; ;;
			match=*) MATCH=${line#*=}; TEMP_CLONE=1; ;;
			branch=*) CLONE_ARGS+=(-b "${line#*=}"); ;;
		esac
	done < <( parse_url_fragment "$plugin" )

	# Download the plugin's archive
	_DEST="${TTRSS_DEST}/${TYPE}"
	if [[ -n "$TEMP_CLONE" ]]; then
		# use a temporary subdir for cloning
		_CLONE_DEST="/tmp/ttrss__${NAME}.git"
	else
		[[ -n "$FOLDER_NAME" ]] || FOLDER_NAME="$NAME"
		_CLONE_DEST="$_DEST/${FOLDER_NAME}"
	fi
	echo "Cloning $NAME to ${_CLONE_DEST}..."
	mkdir -p "$(dirname "$_CLONE_DEST")"
	[[ -d "$_CLONE_DEST/.git" ]] || git clone "${CLONE_ARGS[@]}" "$REPO" "$_CLONE_DEST"
	# copy files from temporary clone dir
	if [[ -n "$TEMP_CLONE" ]]; then
		if [[ -n "$FOLDER_NAME" ]]; then
			_DEST="$_DEST/$FOLDER_NAME"
		fi
		mkdir -p "$_DEST"
		# match & copy files to destination dir
		[[ -n "$MATCH" ]] || MATCH="$NAME*"
		COPY_FILES=("$_CLONE_DEST/"$MATCH)
		cp -rf "${COPY_FILES[@]}" "$_DEST/"
	fi
	ls -lh "$_DEST"
done

cd "$TTRSS_DEST"
cp -f config.php-dist config.php
# change the default owner of www
chown "$CONT_USER:$CONT_USER" /var/www -R

