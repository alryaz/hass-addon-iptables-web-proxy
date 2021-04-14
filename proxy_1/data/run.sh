#!/usr/bin/env bashio
set -e

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

# Prepare substitutions
ingress_entry="$(bashio::addon.ingress_entry)"
ingress_entry_escaped="${ingress_entry//\//\\/}"

for conf_id in default additional external; do
    conf_file=$(bashio::config $conf_id'_conf')
    if [ -n "${conf_file}" ]; then
        conf_target="/tmp/${conf_id}"

        bashio::log.info "Copying \"${conf_file}\" to \"${conf_target}\"..."

        cp "/share/${conf_file}" "${conf_target}" \
        && sed -i "s|%%base_path%%|${ingress_entry}|g" $conf_target \
        && sed -i "s|%%base_path_escaped%%|${ingress_entry_escaped}|g" $conf_target \
        && sed -i "s|#include ${conf_target};|include ${conf_target};|" /etc/nginx.conf \
        || exit 1
    fi
done

# Prepare config file
sed -i "s#%%DESTINATION%%#$(bashio::config 'destination')#g" /etc/nginx.conf

bashio::log.info "Running nginx..."
exec nginx -c /etc/nginx.conf < /dev/null