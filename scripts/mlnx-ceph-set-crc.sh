#!/bin/bash

ceph_conf=${ceph_conf:="/etc/ceph/ceph.conf"}
script_name=$(basename "$0")
script_dir=$(dirname "$0")

function show_usage()
{
	echo "Usage: $script_name [set|unset]"
}

if [[ "$#" -ne 1 ]]; then
	echo "Illegal number of parameters"
	show_usage
	exit 1
fi

if [[ ! -f ${ceph_conf} ]]; then
	echo "Can't find  ${ceph_conf}"
	exit 1
fi

key=$1
value="true"

case $key in
	set)
		value="true"
		;;
	unset)
		value="false"
		;;
	*)
		echo "Unknown argument $key"
		exit 1
esac

cp ${ceph_conf} ${ceph_conf}.bak
${script_dir}/mlnx-ceph-update-conf.awk -v section=global -v key=ms_crc_data value=$value ${ceph_conf} > ${ceph_conf}.tmp
mv ${ceph_conf}.tmp ${ceph_conf}
${script_dir}/mlnx-ceph-update-conf.awk -v section=global -v key=ms_crc_header value=$value ${ceph_conf} > ${ceph_conf}.tmp
mv ${ceph_conf}.tmp ${ceph_conf}
