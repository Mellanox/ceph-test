{
	id = "unknown"
	cmd = ""
	split("", cmd_arr, ":")

	# Find osd id
	if ( ! ($3 in pid_to_id) ) {
		proc_path="/proc/"$3"/cmdline"
		while ((getline cmd < proc_path) > 0);
		split(cmd,cmd_arr,"--");
		for (i in cmd_arr) {
			if (cmd_arr[i] ~ /id[0-9]*/) {
				sub("id","", cmd_arr[i])
				id=cmd_arr[i]

				gsub(/^[[:space:]]+|[[:space:]]+$/,"",id)
				if (! substr(id, 1, 1) ~ /[0-9]/)
					id = substr(id, 2)
				if (! substr(id, length(id), 1) ~ /[0-9]/)
					id = substr(id, 1, length(id) -1 )

				pid_to_id[$3] = id
			}
		}
	} else {
		id = pid_to_id[$3]
	}

	printf "ceph.%s.%s.%s.%s.cpu %s %s\n", setup, type, app, id , $7, $1
	#	printf "ceph.%s.%s.%s.%s.cpu.usr %.2f %s\n", setup, type, app, id , $4+0.0, $1
	#	printf "ceph.%s.%s.%s.%s.cpu.kernel %.2f %s\n", setup, type, app, id ,  $5+0.0, $1
	fflush();
}
