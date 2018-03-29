#!/bin/bash

function show_usage()
{
	echo "Usage: $script_name <perf.data>"
}

function create_flame_graph()
{
	local perf_data=$1
	local folded_output=
	local svg_output=

	if [[ ! -f ${perf_data} ]]; then
		echo "Perf log is not found"
		exit 1
	fi

	folded_output="${perf_data}.out.perf-folded"
	svg_output="${perf_data}.svg"

	echo "Perf log: ${perf_data}"
	echo "Folded output: ${folded_output}"
	echo "SVG: ${svg_output}"

	sudo chown $USER ${perf_data}

	perf script -i ${perf_data}  | ./stackcollapse-perf.pl > "${folded_output}"
	./flamegraph.pl ${folded_output} > ${svg_output}
}


if [[ "$#" -eq 0 ]]; then
	create_flame_graph "./perf.data"
else
	for input_file in "$@"
	do
		create_flame_graph  "$input_file"
	done
fi
