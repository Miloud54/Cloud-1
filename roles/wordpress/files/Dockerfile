FROM wordpress:7.1-php8.4-fpm-alpine

ARG WP_CLI_VERSION=2.12.0
ADD --chmod=0755 \
    https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar \
    /usr/local/bin/wp

COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini
