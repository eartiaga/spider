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
if [ -r "/docker/configs/spideroak_anacron.conf" ]; then
    . "/docker/configs/spideroak_anacron.conf"
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
    wait
    sleep 1
fi

if [ "$SPIDEROAK_ANACRON" = "true" ]; then
    echo "Starting cron daemon for batch mode"
    {
        echo 'MAILTO=""'
        echo "RANDOM_DELAY=${SPIDEROAK_ANACRON_RANDOM_DELAY:-5}"
        [ -z "$SPIDEROAK_ANACRON_START_HOURS_RANGE" ] || echo "START_HOURS_RANGE=$SPIDEROAK_ANACRON_START_HOURS_RANGE"
        echo ''
        echo "${SPIDEROAK_ANACRON_PERIOD:-1} ${SPIDEROAK_ANACRON_DELAY:-60} cron.spideroak ${SPIDEROAK_ONE} --batchmode"
        echo ''
    } > "${HOME}/.local/etc/anacrontab"
    sudo -u root /usr/sbin/crond -f -s -m off
else
    echo "Starting headless mode"
    "$SPIDEROAK_ONE" --headless
fi
