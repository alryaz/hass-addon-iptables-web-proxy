#!/usr/bin/env bashio
set -e

DESTINATION=$(bashio::config 'destination')

if bashio::config.true 'cloudflare'; then
    sed -i "s|#include /data/cloudflare.conf;|include /data/cloudflare.conf;|" /etc/nginx.conf
    # Generate cloudflare.conf
    if ! bashio::fs.file_exists "${CLOUDFLARE_CONF}"; then
        bashio::log.info "Creating 'cloudflare.conf' for real visitor IP address..."
        echo "# Cloudflare IP addresses" > $CLOUDFLARE_CONF;
        echo "" >> $CLOUDFLARE_CONF;

        echo "# - IPv4" >> $CLOUDFLARE_CONF;
        for i in $(curl https://www.cloudflare.com/ips-v4); do
            echo "set_real_ip_from ${i};" >> $CLOUDFLARE_CONF;
        done

        echo "" >> $CLOUDFLARE_CONF;
        echo "# - IPv6" >> $CLOUDFLARE_CONF;
        for i in $(curl https://www.cloudflare.com/ips-v6); do
            echo "set_real_ip_from ${i};" >> $CLOUDFLARE_CONF;
        done

        echo "" >> $CLOUDFLARE_CONF;
        echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_CONF;
    fi
fi

# Prepare config file
sed -i "s#%%DESTINATION%%#$DESTINATION#g" /etc/nginx.conf

bashio::log.info "Running nginx..."
exec nginx -c /etc/nginx.conf < /dev/null