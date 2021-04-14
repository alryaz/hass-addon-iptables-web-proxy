#!/usr/bin/env bashio
set -e

CONTAINER_SLUG=$(bashio::config 'container_slug')
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')
RESOLVE_INTERVAL=$(bashio::config 'resolve_interval')

RETRY_SECONDS=5

bashio::log.info "Starting iptables updater..."

LAST_CONTAINER_IP=""

# External updater loop
while true; do

    # Internal resolution loop
    while true; do
        bashio::log.info "Resolving NGINX proxy IP address..."
        CONTAINER_IP="$(dig +short "$CONTAINER_SLUG.local.hass.io")"
        
        if [ -z "$CONTAINER_IP" ]; then
            bashio::log.error "Could not resolve NGINX proxy IP address, retrying in $RETRY_SECONDS seconds..."
            sleep 5
        else
            bashio::log.info "Resolved IP address: $CONTAINER_IP"
            break
        fi
    done

    if [ -n "$LAST_CONTAINER_IP" ]; then
        iptables -t nat -D PREROUTING -p tcp --dport "$HTTP_PORT" -j DNAT --to-destination "$LAST_CONTAINER_IP"
        iptables -t nat -D PREROUTING -p tcp --dport "$HTTPS_PORT" -j DNAT --to-destination "$LAST_CONTAINER_IP"
    fi

    LAST_CONTAINER_IP="$CONTAINER_IP"

    iptables -t nat -A PREROUTING -p tcp --dport "$HTTP_PORT" -j DNAT --to-destination "$CONTAINER_IP"
    iptables -t nat -A PREROUTING -p tcp --dport "$HTTPS_PORT" -j DNAT --to-destination "$CONTAINER_IP"

    bashio::log.info "Added iptables rules, waiting $RESOLVE_INTERVAL seconds before next update..."

    sleep "$RESOLVE_INTERVAL"
done
