#!/bin/bash

ceph_conf=${ceph_conf:="/etc/ceph/ceph.conf"}
script_name=$(basename "$0")
script_dir=$(dirname "$0")

mons=${mons:-$(sudo ceph -s | grep mon: | awk '{print $5}')}
osds=${osds:-$(sudo  ceph osd tree | grep host | awk '{print $4}' | xargs | tr " " ",") }

echo "Monitors: $mons"
echo "OSDs: $osds"

sudo pdsh -w $osds systemctl stop ceph-osd.target
sudo pdsh -w $mons systemctl restart ceph-mon.target
sudo pdsh -w $osds systemctl start ceph-osd.target
