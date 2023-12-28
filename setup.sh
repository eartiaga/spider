#!/bin/sh

set -e

SETUP_CONF="${SPIDEROAK_STATEDIR}/setup.conf"
remove_setup_config() {
    rm -f "$SETUP_CONF"
}
trap remove_setup_config EXIT

SPIDEROAK_ONE="/usr/bin/SpiderOakONE"

if [ -z "$SPIDEROAK_USER" ] && [ -r "/docker/secrets/spideroak_user.conf" ]; then
    SPIDEROAK_USER="$(base64 -d < "/docker/secrets/spideroak_user.conf")"
fi
if [ -z "$SPIDEROAK_PASSWORD" ] && [ -r "/docker/secrets/spideroak_password.conf" ]; then
    SPIDEROAK_PASSWORD="$(base64 -d < "/docker/secrets/spideroak_password.conf")"
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
    {
        echo "{"
        echo "\"username\":\"${SPIDEROAK_USER}\","
        echo "\"password\":\"${SPIDEROAK_PASSWORD}\","
        echo "\"device_name\":\"${SPIDEROAK_DEVICE}\","
        echo "\"reinstall\":false"
        echo "}"
    } > "$SETUP_CONF"
    "$SPIDEROAK_ONE" --setup="$SETUP_CONF"
    remove_setup_config
else
    echo "Previous configuration exists; please remove before proceeding"
    exit 1
fi

