#!/bin/sh

SPIDEROAK_ONE="/usr/bin/SpiderOakONE"

RETRY=5
SPIDER_PID="$(ps -fea \
    | grep -w -e '/opt/SpiderOakONE/lib/SpiderOakONE' \
    | grep -w -v 'grep' \
    | awk '{print $1}')"
while [ -n "$SPIDER_PID" ] && [ "$RETRY" -ge 0 ]; do
    if [ "$RETRY" -eq 0 ]; then
        kill -9 $SPIDER_PID
    else
        kill $SPIDER_PID
    fi
    sleep 2
    SPIDER_PID="$(ps -fea \
        | grep -w -e '/opt/SpiderOakONE/lib/SpiderOakONE' \
        | grep -w -v 'grep' \
        | awk '{print $1}')"
    RETRY=$(($RETRY - 1))
done

