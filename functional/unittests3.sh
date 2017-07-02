#!/bin/sh

LAVA='echo # '
TEST=`which lava-test-case || true`
echo ${TEST}
if [ "${TEST}" != "" ]; then
   LAVA='lava-test-case'
fi
LC_ALL=C.UTF-8 python3 -m unittest discover -v lava_dispatcher.pipeline 2>&1 >/dev/null | tee ci.log
RET=`echo $?`
if [ "$RET" != "0" ]; then
	${LAVA} logfile --result fail
fi
results=`grep -E "Ran [0-9]{3} tests in " ci.log | sed -E 's/^Ran ([0-9]{3}) tests in ([0-9\.]+)s$/\1 \2/'`
count=`echo $results|cut -d' ' -f 1`
time=`echo $results|cut -d' ' -f 2`
for line in `grep '\.\.\. ' ci.log |grep test | grep ok | awk '{print $1"_"$2":"$4}'`; do
	NAME=`echo $line|cut -d: -f1| tr -d '()' `
	${LAVA} "${NAME}" --result pass
done
for line in `grep '\.\.\. ' ci.log | grep ERROR | awk '{print $1"_"$2":"$4}'`; do
	NAME=`echo $line|cut -d: -f1| tr -d '()' `
	${LAVA} "${NAME}" --result fail
done
for line in `grep 'FAIL: test' ci.log|cut -d' ' -f2-`; do
	${LAVA} ${line} --result fail
done
if [ $count > 0 ]; then
	${LAVA} total-count --result pass --measurement ${count} --units tests
else
	${LAVA} total-count --result fail
fi
if [ $time > 0 ]; then
	${LAVA} overall-speed --result pass --measurement ${time} --units seconds
else
	${LAVA} overall-speed --result fail
fi
${LAVA} logfile --result pass
rm ci.log
