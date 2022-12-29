#!/bin/sh

set -e

SPIDEROAK_ONE="/usr/bin/SpiderOakONE"

if [ "$#" -eq 0 ]; then
    "$SPIDEROAK_ONE" --selection
    wait
fi

if [ "$#" -eq 1 ] && [ "$1" = "--reset" ]; then
    "$SPIDEROAK_ONE" --reset-selection
fi

for arg in "$@"; do
    OP="$(echo "$arg" | cut -f 1 -d :)"
    ITEM="$(echo "$arg" | cut -f 2- -d :)"
    case "$OP" in
        Dir|IncludeDir)
            "$SPIDEROAK_ONE" --include-dir="$ITEM"
            echo "Added Dir: \"$ITEM\""
            ;;
        File|IncludeFile)
            "$SPIDEROAK_ONE" --include-file="$ITEM"
            echo "Added File: \"$ITEM\""
            ;;
        Exclude|ExcludeDir)
            "$SPIDEROAK_ONE" --exclude-dir="$ITEM"
            echo "Excluded Dir: \"$ITEM\""
            ;;
        ExcludeFile)
            "$SPIDEROAK_ONE" --exclude-file="$ITEM"
            echo "Excluded File: \"$ITEM\""
            ;;
        *)
            echo "Ignored: \"${arg}\""
            ;;
    esac
    wait
    sleep 1
done

