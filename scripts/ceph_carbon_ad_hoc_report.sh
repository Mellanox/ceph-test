#!/bin/bash

hostname=`hostname -s`
carbon_host=${carbon_host:-"dev-r-vrt-089"}
carbon_port=${carbon_port:-2003}
process_name=${process_name:-"ceph-osd"}

pidstat -h -d 1 -u -C $process_name | grep --line-buffered -v '^$' | grep --line-buffered -v '^#' | grep --line-buffered -v '^Linux' | awk --assign=hostname=${hostname} '{ printf "servers.%s.pidstat.%s.read %s %s\nservers.%s.pidstat.%s.write %s %s\n", hostname, $6, $3, $1, hostname, $6, $4, $1 ; fflush(); }' #> /dev/tcp/${carbon_host}/${carbon_port}
