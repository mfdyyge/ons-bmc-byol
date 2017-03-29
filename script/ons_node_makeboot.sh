#!/bin/bash

#  ons_node_makeboot.sh
#  Oracle NoSQL Database on Oracle Bare Metal Cloud
#
#  Created by Rick George 2016-2017
#  All rights reserved

TMP=/tmp/ons
mkdir -p $TMP

passphrase=""
store_security=""
security="off"

sudo fdisk -l >$TMP/fdisk 2>/dev/null

capacity=`cat $TMP/fdisk | grep nvme | wc -l`

if [ $((capacity)) -eq 0 ]; then
	capacity=`cat $TMP/fdisk | grep sd[a-e] | wc -l`
fi

adminport="5000"
harange="5010,5025"
servicerange="5030,5045"

while [[ $# -gt 1 ]]; do
	case $1 in
	-P)
		passphrase="$2"; shift 2;;
	--security)
		security=$2; shift 2;;
	-store-security)
		store_security=$2; shift 2;;
	--capacity)
		capacity=$2; shift 2;;
	--adminport)
		adminport="$2"; shift 2;;
	--harange)
		harange="$2"; shift 2;;
	--servicerange)
		servicerange="$2"; shift 2;;
	-s|--store)
		STORE="$2"; shift 2;;
	*)
		shift;;
	esac
done

# config nosql

KVHOST=`hostname`
KVCAP="$capacity"
KVDIRS=""

drives=`cat $TMP/fdisk | grep nvme | sort | cut -f 2 -d ' ' | sed 's/://g'`

if [ -z "$drives" ]; then
	drives=`cat $TMP/fdisk | grep 'sd[b-e]' | sort | cut -f 2 -d ' ' | sed 's/://g'`
fi

count=0

for drive in $drives
do
	mount_dir=`echo $drive | sed 's/dev/ons/g'`
	storage_dir="-storagedir $mount_dir"
    if [[ $count -lt $capacity ]]; then
		jdb=`sudo find $mount_dir -name *.jdb`
		if [ -z "$jdb" ]; then
			[ -z "$KVDIRS" ] && KVDIRS="$storage_dir" || KVDIRS="$KVDIRS $storage_dir"
			count=$((count + 1))
		fi
	fi
done

passphrase="$passphrase"
root="$KVROOT/$STORE"

mkdir -p $root

if [ "$security" == "off" ]; then
	cmd="java -jar $KVHOME/lib/kvstore.jar makebootconfig -root $root -port $adminport -host $KVHOST -harange $harange -servicerange $servicerange -store-security none -capacity $KVCAP $KVDIRS"
	echo $cmd
else
	cmd="java -jar $KVHOME/lib/kvstore.jar makebootconfig -root $root -port $adminport -host $KVHOST -harange $harange -servicerange $servicerange -store-security $store_security -kspwd $passphrase -capacity $KVCAP $KVDIRS"
fi

$cmd

exit 0