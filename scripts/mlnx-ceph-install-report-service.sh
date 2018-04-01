#!/bin/bash

dir=$( cd "$(dirname "$0")" ; pwd -P )
target=${target:-"/opt/mellanox/ceph/reporting-service"}
source=${source:-"$dir/reporting-service"}
name="mlnx-ceph-report"

mkdir -p ${target}
cp ${source}/mlnx-ceph-* ${target}

systemctl stop $name > /dev/null
cp ${source}/$name.service /etc/systemd/system
systemctl daemon-reload
systemctl start $name
systemctl enable $name
systemctl status $name

