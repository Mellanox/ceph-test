#!/bin/bash
pwd=$(dirname "$(readlink -f "$0")")
prefix="$pwd/install"

echo "This script prepares builds a tester application for erasure coding offload."
echo "The tester is part of storage verification system."
echo "It compares erasure coding offload versus software implementation (jerasure library)"
echo ""
echo "jerasure lib depends on gf-complete. Both libraries will be installed in $prefix/lib"

repos=( "http://lab.jerasure.org/jerasure/gf-complete.git" "http://lab.jerasure.org/jerasure/jerasure.git" "/.autodirect/mswg/git/storage_verification.git/" )

echo "Cloning source repositories ..."
for repo in ${repos[@]};do
	echo "$repo"

	git clone --depth 1 ${repo}
done

mkdir -p ${prefix}

echo "Buildin gf-complete ..."
cd gf-complete
./autogen.sh && ./configure --prefix="$prefix" --enable-avx && make -j install
cd ..

echo "Building jerasure ..."
cd jerasure
autoreconf --force --install -I m4
./configure LDFLAGS="-L$prefix/lib" CPPFLAGS="-I$prefix/include" --prefix="$prefix"
make -j install
cd ..

echo "Building erasure coding tester ..."
CFLAGS="-I$prefix/include -I$prefix/include/jerasure" LIBRARY_PATH="$prefix/lib" make -C "$pwd/storage_verification/e2e_ver/vsa/scripts/ec_tests"

echo "How to run:"
echo "   Provide a path to gf-complete and jerasure in command line using \$LD_LIBRARY_PATH."
echo "   If you run the tester not from a current folder, fix \$PATH ."
echo "   Run /$pwd/storage_verification/e2e_ver/vsa/scripts/ec_tests/run_ec_perf_encode.sh --help to see command line parameters."
echo "   Don't forget to provide valid IB and network interfaces."
echo ""
echo "Example:"
echo "LD_LIBRARY_PATH=$prefix/lib PATH=\$PATH:$pwd/storage_verification/e2e_ver/vsa/scripts/ec_tests/  $pwd/storage_verification/e2e_ver/vsa/scripts/ec_tests/run_ec_perf_encode.sh -d mlx5_4 -i ib0 -k 10 -m 2 -w 8 -c 1 -b 1024,1024 -q 1 -l 512 -r 180"

echo $pwd
