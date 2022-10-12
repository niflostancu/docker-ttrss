#!/bin/bash
# Downloads and installs TinyTinyRSS and plugins
set -e

DEST=/var/www
PLUGINS=(
	# "https://github.com/dasmurphy/tinytinyrss-fever-plugin/archive/master.tar.gz;plugins;fever"
	"https://github.com/DigitalDJ/tinytinyrss-fever-plugin/archive/master.tar.gz;plugins;fever:nodir"
	"https://github.com/levito/tt-rss-feedly-theme/archive/master.tar.gz;themes;feedly"
)

rm -rf "$DEST"
git clone https://git.tt-rss.org/fox/tt-rss.git/ "$DEST"

for PLUGIN in "${PLUGINS[@]}"; do
	IFS=';' read -ra _PLUG <<< "$PLUGIN"
	URL="${_PLUG[0]}"; TYPE="${_PLUG[1]}"; _UNP_FLAGS="${_PLUG[2]}"
	IFS=":" read -ra _PLUG_FLAGS <<< "${_UNP_FLAGS}"
	NAME="${_PLUG_FLAGS[0]}"; FLAGS="${_PLUG_FLAGS[1]}"
	curl -sSL "${URL}" -o "/tmp/${NAME}.tar.gz"

	#[[ "${_PLUG[1]}" == "themes" ]] && FILES=("*/${_PLUG[2]}*") || true
	TARARGS=(--strip-components=1)
	_DEST="/var/www/${TYPE}/"
	if [[ "$FLAGS" = "nodir" ]]; then
		# plugin has no self-named dir, create it
		_DEST="/var/www/${TYPE}/$NAME/"
	else
		# only extract the plugin-named subdirectory and prefixed files (e.g.,
		# for themes: '$NAME.css')
		TARARGS+=(--wildcards "*/${NAME}*")
	fi
	echo "Installing ${TYPE} ${NAME}..."
	mkdir -p "$_DEST"
	echo "untar /tmp/${NAME}.tar.gz -C $_DEST ${TARARGS[@]}"
	tar xpf "/tmp/${NAME}.tar.gz" -C "$_DEST" "${TARARGS[@]}"
	ls -ld "/var/www/${TYPE}/$NAME"*
done

cd "$DEST"
cp -f config.php-dist config.php
chown nginx:nginx /var/www -R

