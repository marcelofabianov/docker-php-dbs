FROM marcelofabianov/php-base

## Oracle
ENV LD_LIBRARY_PATH='/usr/local/instantclient/' \
    ORACLE_HOME='/usr/local/instantclient/'

COPY ./instantclient_19_3.zip /tmp/instantclient.zip

RUN unzip /tmp/instantclient.zip -d /usr/local/ && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient && \
    echo 'instantclient,/usr/local/instantclient' | pecl install oci8 && \
    docker-php-ext-install pdo_oci && \
    docker-php-ext-enable oci8

## Firebird
RUN docker-php-ext-install \
    interbase \
    pdo_firebird

RUN docker-php-ext-enable \
    interbase

## MySQL
RUN docker-php-ext-install \
    mysqli \
    pdo_mysql

## Postgres
RUN docker-php-ext-configure pgsql --with-pgsql=/usr/local/pgsql && \
    docker-php-ext-install \
    pgsql \
    pdo_pgsql

RUN usermod -u 1000 www-data

COPY --chown=www-data:www-data . /var/www/
COPY --chown=www-data:www-data . /composer/

RUN chown -R www-data /composer/

USER www-data

EXPOSE 9000

CMD ["php-fpm"]