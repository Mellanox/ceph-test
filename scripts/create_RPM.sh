#/bin/bash -ex

if [ $# -lt 2 ] || [ "$1" == "-h" ]; then
        echo this script creates RPM from local ceph directory
        echo you must provide:
        echo -e "\t1. user name from your email, e.g. moshe@mellanox.com"
        echo -e "\t2. latest version under http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/"
        echo 'USAGE:' $0 '"username" "v11.11.11"'
        echo 'example:' $0 '"moshe" "v11.2.0"'
        exit
fi

user="$1"
version="$2"

#user=saritz
set +e

RPMTOP=`rpm --eval "%{_topdir}"`
mv $RPMTOP $RPMTOP.prev
rm -rf $RPMTOP
rpmdev-setuptree
./make-dist
mv ceph*.tar.bz2 $RPMTOP/SOURCES
time CEPH_EXTRA_CMAKE_ARGS="-DWITH_RDMA=ON" rpmbuild -ba ceph.spec # this is what takes most time
#
BASE=`git describe --abbrev=0`   # example: v11.1.0
VER=`git describe`               # example: v11.1.0-6089-g7a3e505
TARGET=/mswg/release/storage/ceph/rpm-$VER
RPMTOP=`rpm --eval "%{_topdir}"`

mkdir -p $TARGET/noarch
chown -R $user $TARGET
#wget --directory-prefix=$TARGET/noarch http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/$BASE/noarch/ceph-release-1-0.el7.noarch.rpm #Note remark above
#wget --directory-prefix=$TARGET/noarch http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/v11.2.0/noarch/ceph-release-1-0.el7.noarch.rpm #Note remark above
wget --directory-prefix=$TARGET/noarch http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/$version/noarch/ceph-release-1-0.el7.noarch.rpm #Note remark above

createrepo $TARGET/noarch
gpg --detach-sign --armor $TARGET/noarch/repodata/repomd.xml # if this fails you probably don't have a gpg key, see prerequisites above
 
cp -r $RPMTOP/RPMS/x86_64 $RPMTOP/SRPMS/ $TARGET
createrepo $TARGET/SRPMS
rpm --addsign $TARGET/x86_64/*.rpm
createrepo $TARGET/x86_64
gpg --detach-sign --armor $TARGET/x86_64/repodata/repomd.xml

#gpg --armor --export $user@mellanox.com > $TARGET/release.asc
gpg --armor --export 'alexm <alexm@mellanox.com>' > $TARGET/release.asc

