ARG BUILD_FROM
FROM $BUILD_FROM

# Setup base
RUN apk add --no-cache iptables bind-tools

# Copy data
COPY data/run.sh /

CMD [ "/run.sh" ]
