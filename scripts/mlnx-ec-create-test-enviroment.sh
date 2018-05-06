#!/bin/bash
pwd=$(dirname "$(readlink -f "$0")")

repos=( "http://lab.jerasure.org/jerasure/gf-complete.git" "http://lab.jerasure.org/jerasure/jerasure.git" "/.autodirect/mswg/git/storage_verification.git/" )

for repo in ${repos[@]};do
	echo "$repo"

#	git clone --depth 1 ${repo}
done

prefix="$pwd/install"
mkdir ${prefix}

cd gf-complete
./autogen.sh && ./configure --prefix="$prefix" --enable-avx && make -j install
cd ..

cd jerasure
autoreconf --force --install -I m4
./configure LDFLAGS="-L$prefix/lib" CPPFLAGS="-I$prefix/include" --prefix="$prefix"
make -j install
cd ..

#cd storage_verification/e2e_ver/vsa/scripts/ec_tests
CFLAGS="-I$prefix/include -I$prefix/include/jerasure" make -C storage_verification/e2e_ver/vsa/scripts/ec_tests 

echo $pwd
