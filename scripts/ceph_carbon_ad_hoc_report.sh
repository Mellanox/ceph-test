#!/bin/bash

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

################################
# AWK scripts                  #
################################
read -d '' scriptVariable << 'EOF'
    {
	id = "unknown"
# Find osd id
	proc_path="/proc/"$3"/cmdline"
	getline cmd < proc_path
	split(cmd,cmd_arr,"--");
	for (i in cmd_arr) {
		if (cmd_arr[i] ~ /id[0-9]*/) {
			sub("id","", cmd_arr[i])
			id=cmd_arr[i]
		}
	}

	printf "ceph.setup=%s.type=%s.app=%s.id=%s.cpu %s %.2f", setup, type, app, id , $1, $7+0.0
	print " "
	printf "ceph.setup=%s.type=%s.app=%s.id=%s.cpu.usr %s %.2f", setup, type, app, id , $1, $4+0.0
	print " "
	printf "ceph.setup=%s.type=%s.app=%s.id=%s.cpu.kernel %s %.2f", setup, type, app, id , $1, $5+0.0
	print " "
	fflush();
    }
EOF

################################
# End of AWK Scripts           #
################################

pidstat -h -d 1 -u -C $process_name | \
	grep --line-buffered -v '^$' | \
	grep --line-buffered -v '^#' | \
	grep --line-buffered -v '^Linux' | \
	awk --assign=hostname=${hostname} --assign=app=${process_name} --assign=type=${ms_type} --assign=setup=${setup_name} "$scriptVariable"  #  > /dev/tcp/${carbon_host}/${carbon_port}
#	'{ printf "ceph.%s.pidstat.%s.read %s %s \n servers.%s.pidstat.%s.write %s %s\n", hostname, $6, $3, $1, hostname, $6, $4, $1 ; fflush(); }' \
#	awk "$scriptVariable"
