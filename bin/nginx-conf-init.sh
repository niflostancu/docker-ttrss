#!/bin/bash
# Nginx server template initialization script
# Used to support custom web root paths
# (automatically derived from the TTRSS_SELF_URL_PATH env var).

# defaults to root
NGINX_SUBPATH=
NGINX_CONF_ROOT=/etc/nginx/server.root.conf.tpl
NGINX_CONF_TPL=/etc/nginx/server.subpath.conf.tpl
NGINX_CONF_DEST=/etc/nginx/server.conf

# try to parse the self url path
if [[ "$TTRSS_SELF_URL_PATH" =~ ^https?://[^/]+/([^/]+)(/|$) ]]; then
	NGINX_SUBPATH="/${BASH_REMATCH[1]}"
fi

# use the appropriate with subpath variable substitution
if [[ -z "$NGINX_SUBPATH" ]]; then
	cp -f "$NGINX_CONF_ROOT" "$NGINX_CONF_DEST"
else
	sed 's|{{NGINX_SUBPATH}}|'"$NGINX_SUBPATH"'|g' "$NGINX_CONF_TPL" > "$NGINX_CONF_DEST"
fi

