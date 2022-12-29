#!/bin/sh

set -e

SETUP_CONF="${SPIDEROAK_STATEDIR}/setup.conf"
remove_setup_config() {
    rm -f "$SETUP_CONF"
}
trap remove_setup_config EXIT

SPIDEROAK_ONE="/usr/bin/SpiderOakONE"

if [ -z "$SPIDEROAK_USER" ] && [ -r "/docker/secrets/spideroak_user.conf" ]; then
    SPIDEROAK_USER="$(cat "/docker/secrets/spideroak_user.conf" | base64 -d)"
fi
if [ -z "$SPIDEROAK_PASSWORD" ] && [ -r "/docker/secrets/spideroak_password.conf" ]; then
    SPIDEROAK_PASSWORD="$(cat "/docker/secrets/spideroak_password.conf" | base64 -d)"
fi
if [ -z "$SPIDEROAK_DEVICE" ] && [ -r "/docker/configs/spideroak_device.conf" ]; then
    SPIDEROAK_DEVICE="$(cat "/docker/configs/spideroak_device.conf")"
fi

if [ -z "$SPIDEROAK_USER" ]; then
    echo "spideroak_user.conf not properly set-up and mounted"
    exit 1
fi
if [ -z "$SPIDEROAK_PASSWORD" ]; then
    echo "spideroak_password.conf not properly set-up and mounted"
    exit 1
fi
if [ -z "$SPIDEROAK_DEVICE" ]; then
    echo "spideroak_device.conf not properly set-up and mounted"
    exit 1
fi

echo "Backup mounts:"
mount | awk '{print $3}' | grep "^$SPIDEROAK_BACKUPDIR"

if [ ! -f "$SPIDEROAK_STATEDIR/local.dat" ]; then
    echo "{" > "$SETUP_CONF"
    echo "\"username\":\"${SPIDEROAK_USER}\"," >> "$SETUP_CONF"
    echo "\"password\":\"${SPIDEROAK_PASSWORD}\"," >> "$SETUP_CONF"
    echo "\"device_name\":\"${SPIDEROAK_DEVICE}\"," >> "$SETUP_CONF"
    echo "\"reinstall\":false" >> "$SETUP_CONF"
    echo "}" >> "$SETUP_CONF"
    "$SPIDEROAK_ONE" --setup="$SETUP_CONF"
    remove_setup_config
    wait
    sleep 1
fi

echo "Starting headless mode"
"$SPIDEROAK_ONE" --headless
