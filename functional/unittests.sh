#!/bin/sh

./ci-run $@ 2>&1 | ../functional/unittests.py --lava | tee ci.log
RET=`echo $?`
if [ "$RET" != "0" ]; then
	lava-test-case logfile --result fail
fi
results=`grep -E "Ran [0-9]{3} tests in " ci.log | sed -E 's/^Ran ([0-9]{3}) tests in ([0-9\.]+)s$/\1 \2/'`
count=`echo $results|cut -d' ' -f 1`
time=`echo $results|cut -d' ' -f 2`

if [ $count > 0 ]; then
	lava-test-case total-count --result pass --measurement ${count} --units tests
else
	lava-test-case total-count --result fail
fi
if [ $time > 0 ]; then
	lava-test-case overall-speed --result pass --measurement ${time} --units seconds
else
	lava-test-case overall-speed --result fail
fi
lava-test-case logfile --result pass
