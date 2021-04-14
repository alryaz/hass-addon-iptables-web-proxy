#!/usr/bin/env bashio
set -e

DESTINATION=$(bashio::config 'destination')
ADD_CONFIG=$(bashio::config 'add_config')

if bashio::config.true 'cloudflare'; then
    sed -i "s|#include /data/cloudflare.conf;|include /data/cloudflare.conf;|" /etc/nginx.conf
    # Generate cloudflare.conf
    if ! bashio::fs.file_exists "${CLOUDFLARE_CONF}"; then
        bashio::log.info "Creating 'cloudflare.conf' for real visitor IP address..."
        echo "# Cloudflare IP addresses" > "${CLOUDFLARE_CONF}";
        echo "" >> "${CLOUDFLARE_CONF}";

        echo "# - IPv4" >> "${CLOUDFLARE_CONF}";
        for i in $(curl https://www.cloudflare.com/ips-v4); do
            echo "set_real_ip_from ${i};" >> "${CLOUDFLARE_CONF}";
        done

        echo "" >> "${CLOUDFLARE_CONF}";
        echo "# - IPv6" >> "${CLOUDFLARE_CONF}";
        for i in $(curl https://www.cloudflare.com/ips-v6); do
            echo "set_real_ip_from ${i};" >> "${CLOUDFLARE_CONF}";
        done

        echo "" >> "${CLOUDFLARE_CONF}";
        echo "real_ip_header CF-Connecting-IP;" >> "${CLOUDFLARE_CONF}";
    fi
fi

if [ -n "$ADD_CONFIG" ]; then
    sed -i "s|#include /share/add_config.conf|include /share/$ADD_CONFIG;|" /etc/nginx.conf
fi

# Prepare config file
sed -i "s#%%DESTINATION%%#$DESTINATION#g" /etc/nginx.conf

bashio::log.info "Running nginx..."
exec nginx -c /etc/nginx.conf < /dev/null