#!/bin/sh

set -e
set -x

# Find the right AEP device, and put it in the config file for our test
../testdefs/probe_device ../testdefs/aep-config

# ensure the command always exits but allow for non-zero.
timeout 20 arm-probe -C ../testdefs/aep-config -l 1000 -x 2>&1 | tee /tmp/aep-data.log || true
python ../testdefs/aep-parse-output.py
