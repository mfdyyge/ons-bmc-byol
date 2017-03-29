#!/bin/bash

#  ons_cluster_compile.sh
#  Oracle NoSQL Database on Oracle Bare Metal Cloud
#
#  Created by Rick George 2016-2017
#  All rights reserved

DIR="${BASH_SOURCE%/*}"

if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/_incl_.sh"

USAGE="Usage: $0 –-zone <zoneid> --store <dbname> [-P <passphrase>] <ipaddrs>"

if [[ $# -lt 7 ]]; then
	echo "$USAGE"
	exit 1
fi

username="$"
passphrase="$" # Command-line passphrase
capacity="$"
partitions="$"

NODES=""

while [[ $# -gt 0 ]]; do
	case $1 in
	-c|--capacity)
		capacity="$2"; shift 2;;
	-p|--partitions)
		partitions="$2"; shift 2;;
	-z|--zone)
		ZONE="$2"; shift 2;;
	-s|--store)
		STORE="$2"; shift 2;;
	-u|--username)
		username="$2";
		require_username $username 
		shift 2;;		
	-P|--passphrase)
		passphrase="$2";
		require_passphrase $passphrase 
		shift 2;;		
	*)
		require_ipaddr $1
		[ -z "$NODES" ] && NODES=$1 || NODES="$NODES $1"
		shift;;
	esac
done

if [ -z "$ZONE" ] || [ -z "$STORE" ] || [ -z "$NODES" ]; then
	echo "$USAGE"
	exit 1
fi

if [ `echo "$NODES" | wc -w` -lt 3 ]; then
	echo "Must have at least 3 storage nodes (IP addresses)"
	exit 1
fi

adminport=5000
harange_lo=5010
harange_count=$((capacity + 1))
servicerange_lo=5030
servicerange_count=$((6 + capacity - 1))

for store in `echo $STORE | sed 's/,/ /g'`
do
	for node in $NODES
	do
		$ssh_ opc@$node "rm -f $ons_install_flag"
	done
	./ons_cluster_install.sh --zone $ZONE --store $store --capacity $capacity --partitions $partitions \
		--adminport $adminport --harange $harange_lo,$((harange_lo + harange_count - 1)) \
		--servicerange $servicerange_lo,$((servicerange_lo + servicerange_count - 1)) $NODES
	adminport=$((adminport + 1))
	harange_lo=$((harange_lo + harange_count))
	servicerange_lo=$((servicerange_lo + servicerange_count))
done

exit 0

