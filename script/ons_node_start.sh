#!/bin/bash

TMP=/tmp/ons
mkdir -p $TMP/log

while [[ $# -gt 1 ]]; do
	case $1 in
	-s|--store)
		STORE="$2"; shift 2;;
	*)
		shift;;
	esac
done

root="$KVROOT/$STORE"

nohup java -Xmx256m -Xms256m -jar $KVHOME/lib/kvstore.jar start -root $root >$TMP/log/kvstore.log 2>&1 </dev/null &

exit 0