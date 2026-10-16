#!/bin/sh
set -eu

prepare_cache=false
case "${1:-}" in
    apache2-foreground)
        prepare_cache=true
        ;;
    php)
        if [ "${2:-}" = artisan ]; then
            case "${3:-}" in
                migrate|queue:work|schedule:work|nightwatch:agent)
                    prepare_cache=true
                    ;;
            esac
        fi
        ;;
esac

if [ "${APP_ENV:-production}" = production ] && [ "$prepare_cache" = true ]; then
    php artisan config:cache --no-interaction
    php artisan route:cache --no-interaction
    php artisan event:cache --no-interaction
fi

exec docker-php-entrypoint "$@"
