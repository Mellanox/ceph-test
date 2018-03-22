#!/bin/bash

hostname=`hostname -s`
carbon_host=${carbon_host:-"dev-r-vrt-089"}
carbon_port=${carbon_port:-2003}
process_name=${process_name:-"ceph-osd"}

if cat /etc/ceph/ceph.conf | grep -v ";" | grep -q "async+rdma" ; then
	ms_type="rdma"
else
	ms_type="tcp"
fi

################################
# AWK scripts                  #
################################
read -d '' scriptVariable << 'EOF'
    {
	        print $6
    }
EOF

################################
# End of AWK Scripts           #
################################

pidstat -h -d 1 -u -C $process_name | \
	grep --line-buffered -v '^$' | \
	grep --line-buffered -v '^#' | \
	grep --line-buffered -v '^Linux' | \
	awk --assign=hostname=${hostname} --assign=app=${process_name} --assign=type=${ms_type} "$scriptVariable"
#	'{ printf "ceph.%s.pidstat.%s.read %s %s \n servers.%s.pidstat.%s.write %s %s\n", hostname, $6, $3, $1, hostname, $6, $4, $1 ; fflush(); }' \
#	awk "$scriptVariable"
	#> /dev/tcp/${carbon_host}/${carbon_port}
