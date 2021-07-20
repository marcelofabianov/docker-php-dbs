FROM php:7.4-fpm

ENV TZ=America/Sao_Paulo \
    LD_LIBRARY_PATH='/usr/local/instantclient/' \
    ORACLE_HOME='/usr/local/instantclient/'

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# PHP Dependências
RUN rm /etc/apt/preferences.d/no-debian-php && \
    apt-get update -yqq && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    autoconf \
    autogen \
    apt-utils \
    build-essential \
    apt-transport-https \
    gnupg2 \
    curl \
    wget \
    unzip \
    software-properties-common \
    libaio1 \
    libaio-dev \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    libfbclient2 \
    php-soap \
    zlib1g-dev \
    libzip-dev \
    libicu-dev \
    unixodbc-dev \
    firebird-dev \
    openssl && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update  -yqq && \
    sed -i 's,^\(MinProtocol[ ]*=\).*,\1'TLSv1.0',g' /etc/ssl/openssl.cnf && \
    sed -i 's,^\(CipherString[ ]*=\).*,\1'DEFAULT@SECLEVEL=1',g' /etc/ssl/openssl.cnf && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools && \
    rm -rf /var/lib/apt/lists/*

# PHP Extensões
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure pgsql --with-pgsql=/usr/local/pgsql && \
    pecl install xdebug sqlsrv pdo_sqlsrv && \
    docker-php-ext-install \
    pdo_mysql \
    mysqli \
    pgsql \
    pdo_pgsql \
    gd \
    soap \
    bcmath \
    pcntl \
    intl \
    sockets \
    zip \
    ftp \
    pdo_firebird \
    pdo && \
    docker-php-ext-enable \
    xdebug \
    opcache \
    sqlsrv \
    pdo_sqlsrv

## Instantclient oracle
COPY ./instantclient_19_3.zip /tmp/instantclient.zip

RUN unzip /tmp/instantclient.zip -d /usr/local/ && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

# OCI
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient && \
    echo 'instantclient,/usr/local/instantclient' | pecl install oci8-2.2.0 && \
    docker-php-ext-install pdo_oci && \
    docker-php-ext-enable oci8

# Install / Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Config PHP
COPY ./php.ini /usr/local/etc/php/php.ini

RUN useradd -m devs

RUN usermod -u 1000 devs

COPY --chown=devs:www-data . /var/www

RUN chown -R www-data /var/www

USER devs

EXPOSE 9000

CMD ["php-fpm"]