#!/bin/bash

ceph_conf=${ceph_conf:="/etc/ceph/ceph.conf"}
script_name=$(basename "$0")
script_dir=$(dirname "$0")
ib_dev=${ib_dev:-"mlx5_2"}

function set_key_value()
{
	local key=$1
	local value=$2

	${script_dir}/mlnx-ceph-update-conf.awk -v section=global -v key=$key value=$value ${ceph_conf} > ${ceph_conf}.tmp
	mv ${ceph_conf}.tmp ${ceph_conf}
}

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
ms_type="async"

case $key in
	set)
		ms_type="async+rdma"
		;;
	unset)
		ms_type="async"
		;;
	*)
		echo "Unknown argument $key"
		exit 1
esac

net_dev=$(ibdev2netdev | grep ${ib_dev} | awk '{print $5}')
ip=$(ifconfig ${net_dev}  | awk '/inet /{print $2}')
gid=$(show_gids | grep ${ib_dev} | grep "$ip" | awk '{print $4}'|head -1)

echo "Config file: ${ceph_conf}"
echo "IB device: ${ib_dev}"
echo "Network device: ${net_dev}"
echo "IPv4: ${ip}"
echo "GID: $gid"

cp ${ceph_conf} ${ceph_conf}.bak

set_key_value "ms_type" ${ms_type}

if [[ "async+rdma" == ${ms_type} ]]; then
	set_key_value "sync_rdma_device_name" ${ib_dev}
	set_key_value "ms_async_rdma_local_gid" ${gid}
fi
