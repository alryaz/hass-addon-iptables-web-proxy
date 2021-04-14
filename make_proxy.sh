#!/bin/sh

PROXY_ID=1

while [ -d "proxy_$PROXY_ID" ]; do
    PROXY_ID=$(($PROXY_ID + 1));
done

TEMPLATE_DIR="template"
PROXY_DIR="proxy_$PROXY_ID"


for f in $(cd "$TEMPLATE_DIR" && find . -type d); do
    mkdir -p "$PROXY_DIR/$f"
done

for f in $(cd "$TEMPLATE_DIR" && find . -type f); do
    NEW_FILENAME=`echo $PROXY_DIR/$f | sed 's/.template//'`
    cp "$TEMPLATE_DIR/$f" "$NEW_FILENAME"
    sed -i 's/%ID%/'$PROXY_ID'/g' "$NEW_FILENAME"
done

echo "Created proxy with ID: $PROXY_ID"