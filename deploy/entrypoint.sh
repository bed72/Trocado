#!/bin/sh
set -eu

prepare_cache=false
case "${1:-}" in
    php-fpm)
        prepare_cache=true
        for setting in \
            "FPM_MAX_CHILDREN=${FPM_MAX_CHILDREN:-}" \
            "FPM_START_SERVERS=${FPM_START_SERVERS:-}" \
            "FPM_MIN_SPARE_SERVERS=${FPM_MIN_SPARE_SERVERS:-}" \
            "FPM_MAX_SPARE_SERVERS=${FPM_MAX_SPARE_SERVERS:-}" \
            "FPM_MAX_REQUESTS=${FPM_MAX_REQUESTS:-}" \
            "FPM_REQUEST_TERMINATE_TIMEOUT=${FPM_REQUEST_TERMINATE_TIMEOUT:-}"
        do
            name=${setting%%=*}
            value=${setting#*=}
            case "$value" in
                ''|*[!0-9]*)
                    printf '%s must be a positive integer.\n' "$name" >&2
                    exit 1
                    ;;
            esac
            if [ "${#value}" -gt 9 ] || [ "$value" -eq 0 ]; then
                printf '%s must be a positive integer of at most 9 digits.\n' "$name" >&2
                exit 1
            fi
        done
        if [ "$FPM_MIN_SPARE_SERVERS" -gt "$FPM_START_SERVERS" ] \
            || [ "$FPM_START_SERVERS" -gt "$FPM_MAX_SPARE_SERVERS" ] \
            || [ "$FPM_MAX_SPARE_SERVERS" -gt "$FPM_MAX_CHILDREN" ]; then
            printf 'FPM pool requires min_spare <= start <= max_spare <= max_children.\n' >&2
            exit 1
        fi
        if ! php-fpm -t >/dev/null 2>&1; then
            printf 'FPM configuration validation failed; server not started.\n' >&2
            exit 1
        fi
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
    case "${APP_DEBUG:-false}" in
        false|'(false)'|0) ;;
        *)
            printf 'Production startup requires APP_DEBUG=false.\n' >&2
            exit 1
            ;;
    esac
    if [ "${1:-}" = php-fpm ]; then
        case "${TRUSTED_PROXIES:-}" in
            ''|*'*'*)
                printf 'FPM production startup requires explicit TRUSTED_PROXIES without wildcard.\n' >&2
                exit 1
                ;;
        esac
    fi
    for cache in config:cache route:cache event:cache; do
        if ! php artisan "$cache" --no-interaction >/dev/null 2>&1; then
            printf 'Failed to prepare %s; process not started.\n' "$cache" >&2
            exit 1
        fi
    done
fi

exec docker-php-entrypoint "$@"
