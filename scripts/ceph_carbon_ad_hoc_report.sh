#!/bin/bash

dir=$( cd "$(dirname "$0")" ; pwd -P )
hostname=`hostname -s`
carbon_host=${carbon_host:-"dev-r-vrt-089"}
carbon_port=${carbon_port:-2003}
process_name=${process_name:-"ceph-osd"}
setup_name=${setup_name:-"dory"}

if cat /etc/ceph/ceph.conf | grep -v ";" | grep -q "async+rdma" ; then
	ms_type="rdma"
else
	ms_type="tcp"
fi

pidstat -h -d -u -C $process_name 1 | \
	grep --line-buffered -v '^$' | \
	grep --line-buffered -v '^#' | \
	grep --line-buffered -v '^Linux' | \
	awk --assign=hostname=${hostname} --assign=app=${process_name} \
	    --assign=type=${ms_type} --assign=setup=${setup_name}  \
             -f ${dir}/ceph_parse_pidstat.awk  > /dev/tcp/${carbon_host}/${carbon_port}
