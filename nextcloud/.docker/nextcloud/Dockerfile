FROM nextcloud:apache

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libbz2-dev libkrb5-dev libsmbclient-dev git ffmpeg ghostscript procps smbclient supervisor; \
#        libc-client-dev
#    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install bz2; # imap; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*




RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
;

COPY supervisord.conf /

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV NEXTCLOUD_UPDATE=1

COPY opcache.ini /usr/local/etc/php/conf.d/opcache_custom.ini

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
