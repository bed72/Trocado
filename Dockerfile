# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS assets

WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked npm ci --no-audit --no-fund
COPY resources ./resources
COPY public ./public
COPY vite.config.js ./
RUN npm run build

FROM php:8.5.12-fpm-bookworm@sha256:d3db5340c7ecfb1e3a26af5d3d9de8b4e160cdd75692a830b5cb74b0b85db2cf AS php-base

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

ENV FPM_MAX_CHILDREN=4 \
    FPM_START_SERVERS=2 \
    FPM_MIN_SPARE_SERVERS=1 \
    FPM_MAX_SPARE_SERVERS=2 \
    FPM_MAX_REQUESTS=500 \
    FPM_REQUEST_TERMINATE_TIMEOUT=60

COPY --from=dependencies /var/www/html /var/www/html
COPY --from=assets /app/public/build ./public/build
COPY deploy/php-fpm.conf /usr/local/etc/php-fpm.d/zzz-trocado.conf
COPY --chmod=755 deploy/entrypoint.sh /usr/local/bin/trocado-entrypoint

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

ENTRYPOINT ["trocado-entrypoint"]
CMD ["php-fpm"]

FROM nginx:1.30.6-trixie@sha256:a7675fcee220f59b4a99f7098c06a0d5d999c2c0ee37c0211efb780536e5cb20 AS web

RUN rm -rf /usr/share/nginx/html

WORKDIR /var/www/html
COPY --from=assets /app/public/build ./public/build
COPY --from=assets /app/public/favicon.ico /app/public/robots.txt ./public/
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
