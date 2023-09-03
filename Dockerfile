# TinyTinyRSS (nginx based) image for personal cloud
FROM niflostancu/server-base:s6lv2

ARG TTRSS_VERSION="master"
ARG TARGETPLATFORM

ENV WWW_UID=1000
RUN useradd -u $WWW_UID -s /bin/false nginx

# dependencies
RUN echo "**** installing dependencies ****" && \
	apk --update upgrade && \
    apk --update --no-cache add \
		nginx php81 php81-fpm php81-cli \
		php81-pdo php81-gd php81-pgsql php81-pdo_pgsql php81-pdo_mysql \
		php81-mbstring php81-intl php81-xml php81-curl php81-session \
		php81-tokenizer php81-dom php81-fileinfo php81-ctype php81-json \
		php81-iconv php81-pcntl php81-posix php81-zip php81-exif \
		php81-openssl \
	git ca-certificates && \
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
ADD scripts /usr/local/bin
ADD config.docker.php /usr/local/share/ttrss/

