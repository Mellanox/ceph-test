#!/bin/sh

cpwd=$(pwd)

ceph_conf_rdma=${ceph_conf_rdma:-"$cpwd/ceph_rdma.conf"}
ceph_conf_tcp=${ceph_conf_tcp:-"$cpwd/ceph_tcp.conf"}
rdma_device=${rdma_device:-"mlx5_2"}
server=${server:-"dory04"}
server_port_tcp="4455"
server_port_rdma="4456"
server_app=
client_app=
common_so=
screen_session="ceph_server"
server_name="ceph_perf_msgr_server"

echo "CEPH rdma configuration file: $ceph_conf_rdma"
echo "CEPH tcp configuration file: $ceph_conf_tcp"
echo "RDMA device: $rdma_device"
echo "Server: $server"

function kill_server_app()
{
	if [ ! -z "$server" ]; then
		ssh ${server} "pkill -f -9 $server_name > /dev/null" || true
	fi
}

function kill_process_running_on_port()
{
	local host=$1
	local port=$2

	sudo ssh $host fuser -s  -k "$port/tcp" ||:
}

function finish {
	if [ ! -z "$server" ]; then
		kill_process_running_on_port $server $server_port_tcp
		kill_process_running_on_port $server $server_port_rdma
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

	echo ${device}

local ip=$(ssh $host << EOF
	ibdev2netdev | grep ${device} | awk '{print $5}' | xargs -I {} ifconfig {} | grep "inet " | awk -F'[: ]+' '{ print $3 }'
EOF
)
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
	server_app="${dir}/${server_name}"
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
	local address=$3

	shift 3

ssh $host << EOF
export LD_PRELOAD=${common_so}; export CEPH_CONF=${ceph_conf}; nohup ${server_app} $address $@ > ${cpwd}/server.nohup.out  2>&1 &
EOF
}

function run_client()
{
	local host=$1
	local ceph_conf=$2
	local address=$3

	shift 3

	LD_PRELOAD=${common_so} CEPH_CONF=${ceph_conf} ${client_app} ${address} $@ 2>&1 |grep Total  | awk '{print substr($6,1,length($6)-3)}'
	local ret=$(($?))

	#return $ret
}

create_ceph_rdma_conf_file $ceph_conf_rdma $rdma_device
create_ceph_tcp_conf_file $ceph_conf_tcp
#server_ip=$(find_server_ip $server $rdma_device)
server_ip="1.1.4.1"
set_exe_paths

echo "Server IP: $server_ip"
echo "Server app: ${server_app}"
echo "Client app: ${client_app}"
echo "Common so: ${common_so}"

function run_tests()
{
	local s=$((1024))
#	local f=$((1024))
	local f=$((5*1024*1024))
	local i=$((10*1024))
	local us_tcp=
	local us_rdma=
	local server_params="4 1"
	local client_params="4 16 1000 1"


	local server_address_tcp="$server_ip:$server_port_tcp"
	local server_address_rdma="$server_ip:$server_port_rdma"

	while (( s <= f )); do
		kill_process_running_on_port $server $server_port_tcp
		run_server ${server} ${ceph_conf_tcp} ${server_address_tcp} ${server_params}
		us_tcp=$(run_client ${server} ${ceph_conf_tcp}  ${server_address_tcp} "$client_params $s")

		kill_process_running_on_port $server $server_port_rdma
		run_server ${server} ${ceph_conf_rdma} ${server_address_rdma} ${server_params}
		us_rdma=$(run_client ${server} ${ceph_conf_rdma}  ${server_address_rdma} "$client_params $s")

		printf  "%s %s %s\n" "$s" "$us_tcp" "$us_rdma"
		s=$(($s+$i))
	done

}

run_tests
