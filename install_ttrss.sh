#!/bin/bash
# Downloads and installs TinyTinyRSS and plugins
set -e

DEST=/var/www
PLUGINS=(
	"https://github.com/dasmurphy/tinytinyrss-fever-plugin/archive/master.tar.gz;plugins;fever"
	"https://github.com/levito/tt-rss-feedly-theme/archive/master.tar.gz;themes;feedly"
)

curl -sSL https://git.tt-rss.org/git/tt-rss/archive/${TTRSS_VERSION}.tar.gz \
	-o "/tmp/ttrss.tar.gz"
tar xpf "/tmp/ttrss.tar.gz" --strip-components 1 -C "$DEST/"

for PLUGIN in "${PLUGINS[@]}"; do
	IFS=';' read -ra _PLUG <<< "$PLUGIN"
	curl -sSL "${_PLUG[0]}" -o "/tmp/${_PLUG[2]}.tar.gz"
	# only extract the plugin-named subdirectory
	FILES=("*/${_PLUG[2]}")
	[[ "${_PLUG[1]}" == "themes" ]] && FILES+=("${_PLUG[2]}.css") || true
	tar xpf "/tmp/${_PLUG[2]}.tar.gz" --strip-components=1 \
		-C /var/www/${_PLUG[1]}/ --wildcards "*/${_PLUG[2]}"
done

cd "$DEST"
cp config.php-dist config.php
chown nginx:nginx /var/www -R

