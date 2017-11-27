#!/bin/bash

echo $HOSTNAME
ibdev2netdev
base=${HOSTNAME%%.*}
echo $base
id=${base##*0}
echo $id
interface=${interface:-"ens6f0"}

echo $interface

ifconfig $interface down
ifconfig $interface 1.1.1.${id}/24 up
ifconfig

