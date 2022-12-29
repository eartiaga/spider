#!/bin/sh

set -e

SPIDEROAK_ONE="/usr/bin/SpiderOakONE"

echo "Backup mounts:"
mount | awk '{print $3}' | grep "^$SPIDEROAK_BACKUPDIR"
echo "User info:"
"$SPIDEROAK_ONE" --userinfo
wait
sleep 1
echo "Space info:"
"$SPIDEROAK_ONE" --space
wait
sleep 1
echo "Backup selection:"
"$SPIDEROAK_ONE" --selection
wait
