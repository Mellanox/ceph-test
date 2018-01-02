#!/bin/sh -x
git submodule update --init --recursive
BUILD=/mnt/data/vasilyf/build
BASE=`pwd`
if test -e $BUILD; then
    echo 'build dir already exists; rm -rf build and re-run'
    exit 1
fi
mkdir $BUILD
cd $BUILD
cmake -DBOOST_J=$(nproc) "$@" $BASE
 
# minimal config to find plugins
cat <<EOF > ceph.conf
plugin dir = lib
erasure code dir = lib
EOF
 
# give vstart a (hopefully) unique mon port to start with
echo $(( RANDOM % 1000 + 40000 )) > .ceph_port

#export PATH="${CMAKE_INSTALL_PREFIX}/bin:$PATH"
#export LD_LIBRARY_PATH="${CMAKE_INSTALL_PREFIX}/lib64:${CMAKE_INSTALL_PREFIX}/lib64/ceph:$LD_LIBRARY_PATH"
 
echo done.
