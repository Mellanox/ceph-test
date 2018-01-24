#!/bin/sh

cpwd=$(pwd)

ceph_conf_rdma=${ceph_conf_rdma:-"$cpwd/ceph_rdma.conf"}
ceph_conf_tcp=${ceph_conf_tcp:-"$cpwd/ceph_tcp.conf"}
rdma_device=${rdma_device:-"mlx5_2"}
server=${server:-"dory04"}
server_port=${server_port:-"4455"}
server_app=
client_app=
common_so=
screen_session="ceph_server"

echo "CEPH rdma configuration file: $ceph_conf_rdma"
echo "CEPH tcp configuration file: $ceph_conf_tcp"
echo "RDMA device: $rdma_device"
echo "Server: $server"

function finish {
	if [ -z "$server" ]; then
echo "  " #		ssh screen -X -S ${screen_session} kill
	fi
}
trap finish EXIT

function log_err()
{
	local msg=$1
	local val=$2

	(>&2 echo "ERROR: ${2}")
	exit $1
}

function log_warn()
{
	local msg=$1
	(>&2 echo "WARNING: ${2}")
}

function log()
{
	local msg=$1

	echo ${1} > /dev/null
}

#
# Prepare ceph.conf for RDMA
#
function create_ceph_rdma_conf_file()
{
	local path=$1
	local device=$2

	if [ -f ${path} ]; then
		log_warn "${path} will be recreated"
		\rm -f ${path}
	fi

	echo "[global]" >> ${path}
	echo "ms_type = async+rdma" >> ${path}
	echo "ms_async_rdma_device_name = $device" >> ${path}
	echo "ms_async_rdma_polling_us = 0" >> ${path}
}

#
# Prepare ceph.conf (async_tcp)
#
function create_ceph_tcp_conf_file()
{
	local path=$1

	if [ -f ${path} ]; then
		log_warn "${path} will be recreated"
		\rm -f ${path}
	fi

	echo "[global]" >> ${path}
	echo "ms_type = async" >> ${path}
}

#
# Ger remote IP by RDMA device
#
function find_server_ip()
{
	local host=$1
	local device=$2

	local ip=$(ssh ${host} ibdev2netdev | grep mlx5_2 | awk '{print $5}' | xargs -I {} ifconfig {} | grep "inet " | awk -F'[: ]+' '{ print $3 }')
	if ping -q -c 1 -W 1 ${ip} >/dev/null; then
		log "${ip} is up"
	else
		log_err 1 "Can't access ${ip}"
	fi

	echo $ip
}

function set_exe_paths()
{
	local fs=$(df -P -T ${cpwd}  | tail -n +2 | awk '{print $2}')

	if [[ "nfs" != $fs ]]; then
		log_err 1 "Run this script from shared folder"

	fi

	local dir=$(readlink -f ${cpwd})
	server_app="${dir}/ceph_perf_msgr_server"
	client_app="${dir}/ceph_perf_msgr_client"
	common_so="${dir}/libceph-common.so.0"

	for path in ${server_app} ${client_app} ${common_so}; do
		if [ ! -f ${path} ]; then
			log_err 1 "file ${path} doesn't exist"
		fi
	done

}

function run_server()
{
	local host=$1
	local ceph_conf=$2

	shift 2

	ssh $host screen -S $screen_session -d -m "LD_PRELOAD=${common_so} CEPH_CONF=${ceph_conf} ${server_app} $@"
	local ret=$?


#	LD_PRELOAD=/hpc/local/work/sashakot/ceph_async_msg_bench/libceph-common.so.0   /hpc/local/work/sashakot/ceph_async_msg_bench/ceph_perf_msgr_server  1.1.3.1:4455 4 1
}

function run_client()
{
	local host=$1
	local ceph_conf=$2

	shift 2

	LD_PRELOAD=${common_so} CEPH_CONF=${ceph_conf} ${client_app} $@
	local ret=$?

#LD_PRELOAD=/hpc/local/work/sashakot/ceph_async_msg_bench/libceph-common.so.0   /hpc/local/work/sashakot/ceph_async_msg_bench/ceph_perf_msgr_server  1.1.3.1:4455 4 1
}

create_ceph_rdma_conf_file $ceph_conf_rdma $rdma_device
create_ceph_tcp_conf_file $ceph_conf_tcp
server_ip=$(find_server_ip $server $rdma_device)
set_exe_paths

echo "Server IP: $server_ip"
echo "Server port: $server_port"
echo "Server app: ${server_app}"
echo "Client app: ${client_app}"
echo "Common so: ${common_so}"
run_server ${server} ${ceph_conf_tcp} "$server_ip:$server_port 4 1"
run_client ${server} ${ceph_conf_tcp} "$server_ip:$server_port 4 4 500 1 2014"

