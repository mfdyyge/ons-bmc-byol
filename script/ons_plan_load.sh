#!/bin/bash

#  ons_plan_load.sh
#  Oracle NoSQL Database on Oracle Bare Metal Cloud
#
#  Created by Rick George 2016-2017
#  All rights reserved

username="admin"
passphrase=""
adminport="5000"

while [[ $# -gt 1 ]]; do
	case $1 in
	--plan)
		plan="$2"; shift 2;;
	--security)
		security=$2; shift 2;;
	--username)
		username=$2; shift 2;;
	--passphrase)
		passphrase=$2; shift 2;;
	--adminport)
		adminport="$2"; shift 2;;
	--store)
		STORE="$2"; shift 2;;
	*)
		shift;;
	esac
done

cat $plan

runadmin="java -jar $KVHOME/lib/kvstore.jar runadmin -port $adminport -host `hostname`"

if [ "$security" == "off" ]; then
	echo "$runadmin"
	$runadmin load -file $plan
	java -jar $KVHOME/lib/kvstore.jar ping -host `hostname` -port $adminport
else
	runadmin_secure="$runadmin -security $KVROOT/$STORE/security/client.security"
	$runadmin_secure load -file $plan
	pswdconfig="change-policy -params passwordMinLength=6 passwordMinDigit=0 passwordMinLower=0 passwordMinSpecial=0 passwordMinUpper=0"
	echo -e "$pswdconfig\nexec \"create user $username IDENTIFIED BY '$passphrase' ADMIN\"" | $runadmin_secure > /dev/null 2>&1
fi

exit 0