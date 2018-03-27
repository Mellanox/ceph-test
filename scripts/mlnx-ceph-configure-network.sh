#!/bin/bash

echo $HOSTNAME
ibdev2netdev
base=${HOSTNAME%%.*}
echo $base
id=${base##*0}
echo $id
interfaces=${interfaces:-"ens6f0"}

function set_persistent_configuration()
{
	local name=$1
	local ip=$2
	local prefix=$3

cat > /etc/sysconfig/network-scripts/ifcfg-${name} << EOF
	DEVICE=${name}
	BOOTPROTO=none
	ONBOOT=yes
	PREFIX=${prefix}
	IPADDR=${ip}
	USERCTL=n
EOF
}

function enable_pfc()
{
	local name=$1
	local ib=$(ibdev2netdev | grep $name | awk '{print $1}')

	mlnx_qos -i $name --trust dscp
	mlnx_qos -i $name --pfc 0,0,0,1,0,0,0,0
	echo 106 > /sys/class/infiniband/$ib/tc/1/traffic_class
}

echo $interfaces

n=$((1))

for interface in $interfaces; do

	ip="1.1.${id}.${n}"

	ifconfig $interface down
	ifconfig $interface ${ip}/16 up
	ifconfig $interface

	set_persistent_configuration $interface $ip 16
	enable_pfc $interface

	n=$(($n+1))
done


