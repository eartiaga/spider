#!/bin/sh

SPIDEROAK_ONE="/opt/SpiderOakONE/lib/SpiderOakONE"

RETRY=5
SPIDER_PID="$(pgrep -f -x "$SPIDEROAK_ONE")"
while [ -n "$SPIDER_PID" ] && [ "$RETRY" -ge 0 ]; do
    if [ "$RETRY" -eq 0 ]; then
        kill -9 "$SPIDER_PID"
    else
        kill "$SPIDER_PID"
    fi
    sleep 2
    SPIDER_PID="$(pgrep -f -x "$SPIDEROAK_ONE")"
    RETRY=$((RETRY - 1))
done

