#! /usr/bin/awk -f

function print_record()
{
	printf "%*s ", cores_w, cores;

	for (i = 0; i < length(blocks); i++) {
		printf "%*s %*s ", cpu_w[blocks[i]], cpu[blocks[i]], bw_w[blocks[i]], bw[blocks[i]];

	};
	printf "\n"
}

BEGIN {
	cores=0

	blocks[0]=1;
	blocks[1]=4;
	blocks[2]=16;
	blocks[3]=128;
	blocks[4]=512;
	blocks[5]=1024;

	printf "cores ";
	cores_w = 5;

	for (i = 0; i < length(blocks); i++) {
		cpu_name = sprintf("%s_cpu[%]_%sK", prefix, blocks[i]);
		bw_name = sprintf("%s_bw[MB/s]_%sK", prefix, blocks[i]);

		printf "%s %s ", cpu_name, bw_name;

		cpu[blocks[i]]=0;
		bw[blocks[i]]=0;

		cpu_w[blocks[i]] = length(cpu_name);
		bw_w[blocks[i]] = length(bw_name);
	}
	printf "\n"
}

/cores=/{
	if (cores > 0)
		print_record();
	n = split($3,a,"="); cores=a[2]
}

/^  1               /{ cpu[$2]=$3; bw[$2]=$4;}

END {
	print_record();
}
