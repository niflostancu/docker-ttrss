# TinyTinyRSS (nginx based) image for personal cloud
FROM niflostancu/server-base
MAINTAINER Florin Stancu <niflostancu@gmail.com>

ARG TTRSS_VERSION="master"

ENV WWW_UID=1000
RUN useradd -u $WWW_UID -s /bin/false nginx

# dependencies
RUN echo "**** installing dependencies ****" && \
	apk --update upgrade && \
    apk --update --no-cache add \
        nginx php7-fpm php7-cli php7 php7-curl php7-opcache php7-gd php7-json \
        php7-pcntl php7-fileinfo php7-xml php7-posix php7-session php7-pgsql \
        php7-mysqli php7-pdo php7-pdo_pgsql php7-pdo_mysql php7-mcrypt \
        php7-dom php7-mbstring php7-iconv php7-intl git ca-certificates && \
	apk add --no-cache --virtual .build-dependencies curl tar

ADD install_ttrss.sh /tmp/install_ttrss.sh
RUN echo "**** installing ttrss and plugins ****" && \
	/tmp/install_ttrss.sh && \
	echo "**** cleanup ****" && \
	apk del .build-dependencies && \
	rm -rf /tmp/*

# environments and their defaults
ENV SELF_URL_PATH http://localhost
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# expose nginx HTTP
EXPOSE 80

# add config and init scripts
ADD etc/ /etc/
ADD scripts /usr/local/bin

