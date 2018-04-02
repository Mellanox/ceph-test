#!/bin/bash
for host in r-ceph-03  r-ceph-04 r-ceph-05
do
 ssh $host <<EOF
umount /dev/sdd1
dd if=/dev/zero of=/dev/sdd bs=1024k count=100
sgdisk -g --clear /dev/sdd
EOF
done
