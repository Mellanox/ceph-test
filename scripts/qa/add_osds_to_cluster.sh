#/bin/bash

if [ $# -lt 0 ] || [ "$1" == "-h" ]; then
	echo this script adds osds to hosts using ceph-deploy
	echo 'no arguments needed'
	exit
fi

if [ ! -f hosts.txt ]; then
    echo "hosts.txt file not found!"
    exit
fi

for HOST in $(cat hosts.txt); do
	echo "***********************"
	echo "Enter disks for $HOST"
	echo example: sdb sdc sdd sde
	read DISKS
	if [ -z "$DISKS" ]; then
		echo no OSDs for $HOST
	else
		for CDISK in $DISKS; do
			echo ceph-deploy --overwrite-conf disk zap $HOST:$CDISK 
			echo ceph-deploy --overwrite-conf osd create $HOST:$CDISK
			ceph-deploy --overwrite-conf disk zap $HOST:$CDISK
			echo ceph-deploy --overwrite-conf disk zap $HOST:$CDISK -Done!
			ceph-deploy --verbose --overwrite-conf osd prepare $HOST:$CDISK
			echo ceph-deploy --overwrite-conf osd prepare  $HOST:$CDISK -Done!
			ceph-deploy osd activate $HOST:"$CDISK"1
			echo ceph-deploy osd activate $HOST:$CDISK - Done!
		done
	fi
done
