# TinyTinyRSS (+ nginx) image based on alpine & s6 overlay
FROM niflostancu/server-base:s6lv3

ARG TTRSS_VERSION="master"
ARG TARGETPLATFORM

# alpine uses UID=82 for www-data
ENV CONT_USER=www-data CONT_UID=82 CONT_GID=82
RUN getent group "$CONT_USER" &>/dev/null || groupadd -g "$CONT_GID" "$CONT_USER" && \
	useradd -u "$CONT_UID" -g "$CONT_USER" "$CONT_USER"

# dependencies
RUN echo "**** installing dependencies ****" && apk --update upgrade && \
	apk --update --no-cache add \
		nginx php85 php85-fpm php85-cli \
		php85-pdo php85-gd php85-pgsql php85-pdo_pgsql php85-pdo_mysql \
		php85-mbstring php85-intl php85-xml php85-curl php85-session \
		php85-tokenizer php85-dom php85-fileinfo php85-ctype php85-json \
		php85-iconv php85-pcntl php85-posix php85-zip php85-exif \
		php85-openssl git ca-certificates && \
	ln -sf /usr/bin/php85 /usr/bin/php && \
	apk add --no-cache --virtual .build-dependencies curl tar

ADD install_ttrss.sh /tmp/install_ttrss.sh
RUN echo "**** installing ttrss and plugins ****" && \
	/tmp/install_ttrss.sh && \
	echo "**** cleanup ****" && \
	apk del .build-dependencies && \
	rm -rf /tmp/*

# environments and their defaults
ENV TTRSS_SELF_URL_PATH=http://localhost/ \
	TTRSS_DB_NAME=ttrss \
	TTRSS_DB_USER=ttrss \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

# expose nginx HTTP
EXPOSE 80

# add config and init scripts
ADD etc/ /etc/
ADD bin/ /usr/local/bin
ADD config.docker.php /usr/local/share/ttrss/

# Use ttrss-updated as main command
CMD [ "ttrss-updated" ]

