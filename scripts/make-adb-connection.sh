#!/bin/sh

set -e
set -x

LAVA=`which lava-test-case || true`

if [ -n "$LAVA" ]; then
    # FIXME: these need more work with suitable devices.
    IPADDR=`lava-target-ip || true`
    MACADR=`lava-target-mac || true`
fi

if [ -z "$IPADDR" -a -z "$MACADDR" ]; then
    which adb
    echo
    # start adb and stop the daemon start message from appearing in $result
    adb get-serialno || true # start daemon if not yet running.
    result=`adb get-serialno 2>&1 | tail -n1`
    if [ "$result" = "unknown" ]; then
        echo "ERROR: adb get-serialno returned" $result
        if [ -n "$LAVA" ]; then
            lava-test-case adb-serialno --result fail
        fi
        exit 1
    else
        if [ -n "$LAVA" ]; then
            lava-test-case adb-serialno --result pass
        fi
        echo "adb get-serialno returned" $result
        echo $result > adb-connection.txt
    fi
fi
