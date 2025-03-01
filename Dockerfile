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
		nginx php83 php83-fpm php83-cli \
		php83-pdo php83-gd php83-pgsql php83-pdo_pgsql php83-pdo_mysql \
		php83-mbstring php83-intl php83-xml php83-curl php83-session \
		php83-tokenizer php83-dom php83-fileinfo php83-ctype php83-json \
		php83-iconv php83-pcntl php83-posix php83-zip php83-exif \
		php83-openssl git ca-certificates && \
	apk add --no-cache --virtual .build-dependencies curl tar

ADD install_ttrss.sh /tmp/install_ttrss.sh
RUN echo "**** installing ttrss and plugins ****" && \
	/tmp/install_ttrss.sh && \
	echo "**** cleanup ****" && \
	apk del .build-dependencies && \
	rm -rf /tmp/*

# environments and their defaults
ENV TTRSS_SELF_URL_PATH http://localhost/
ENV TTRSS_DB_NAME ttrss
ENV TTRSS_DB_USER ttrss

# expose nginx HTTP
EXPOSE 80

# add config and init scripts
ADD etc/ /etc/
ADD bin/ /usr/local/bin
ADD config.docker.php /usr/local/share/ttrss/

# Use ttrss-updated as main command
CMD [ "ttrss-updated" ]

