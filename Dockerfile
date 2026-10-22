# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS assets

WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked npm ci --no-audit --no-fund
COPY resources ./resources
COPY public ./public
COPY vite.config.js ./
RUN npm run build

FROM php:8.5.12-apache-bookworm AS php-base

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev libpq5 $PHPIZE_DEPS \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql pcntl \
    && curl --fail --show-error --silent --location --retry 5 --retry-all-errors --retry-delay 2 \
        https://pecl.php.net/get/redis-6.3.0.tgz --output /tmp/redis-6.3.0.tgz \
    && pecl install /tmp/redis-6.3.0.tgz \
    && docker-php-ext-enable redis \
    && apt-get purge -y --auto-remove libpq-dev $PHPIZE_DEPS \
    && rm -rf /var/lib/apt/lists/* /tmp/redis-6.3.0.tgz

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY deploy/php.ini /usr/local/etc/php/conf.d/trocado.ini

RUN php -r 'foreach (["dom", "pdo_pgsql", "pcntl", "redis", "Zend OPcache"] as $extension) { if (! extension_loaded($extension)) { fwrite(STDERR, "Missing required extension: $extension\n"); exit(1); } }'

FROM php-base AS dependencies

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/tmp/composer-cache,sharing=locked \
    COMPOSER_CACHE_DIR=/tmp/composer-cache composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction --no-progress

COPY . .
RUN mkdir -p storage/app/private storage/app/public storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && composer dump-autoload --no-dev --optimize --no-interaction

FROM php-base AS runtime

COPY --from=dependencies /var/www/html /var/www/html
COPY --from=assets /app/public/build ./public/build
COPY deploy/apache.conf /etc/apache2/sites-available/000-default.conf
COPY deploy/apache-global.conf /etc/apache2/conf-available/trocado.conf
COPY --chmod=755 deploy/entrypoint.sh /usr/local/bin/trocado-entrypoint

RUN a2enmod rewrite deflate filter headers \
    && a2enconf trocado \
    && apache2ctl -t \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

ENTRYPOINT ["trocado-entrypoint"]
CMD ["apache2-foreground"]

EXPOSE 80
