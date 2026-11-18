FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-fpm \
    php-mysql \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

COPY tools/wordpress.sh /usr/local/bin/wordpress.sh
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN chmod +x /usr/local/bin/wordpress.sh

CMD ["/usr/local/bin/wordpress.sh"]
