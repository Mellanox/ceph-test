#/bin/bash -ex

if [ $# -lt 2 ] || [ "$1" == "-h" ]; then
        echo this script releases RPMs from local ceph directory
        echo you must provide:
        echo -e "\t1. user name from your email, e.g. moshe@mellanox.com"
        echo -e "\t2. latest version under http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/"
        echo 'USAGE:' $0 '"username" "v11.11.11"'
        echo 'example:' $0 '"moshe" "v11.2.0"'
        exit
fi

DESTINATION=${DESTINATION:-"/auto/mswg/release/storage/ceph"}
RPMTOP=${3:-`rpm --eval "%{_topdir}"`}
VER=`git describe`               # example: v11.1.0-6089-g7a3e505
TARGET=${DESTINATION}/rpm-$VER

echo "Source RPM top dir: $RPMTOP"
echo "Version: $VER"
echo "Destination: ${DESTINATION}"
echo "Target: ${TARGET}"


function create_release
{
	mkdir -p $TARGET/noarch
	wget --directory-prefix=$TARGET/noarch https://download.ceph.com/rpm-luminous/el7/noarch/ceph-release-1-0.el7.noarch.rpm

	createrepo $TARGET/noarch
	#gpg --detach-sign --armor $TARGET/noarch/repodata/repomd.xml # if this fails you probably don't have a gpg key, see prerequisites above

	cp -r $RPMTOP/RPMS/x86_64 $RPMTOP/SRPMS/ $TARGET
	createrepo $TARGET/SRPMS
	rpm --addsign $TARGET/x86_64/*.rpm
	createrepo $TARGET/x86_64
	#sudo -u ceph-release gpg --detach-sign --armor $TARGET/x86_64/repodata/repomd.xml

	#gpg --armor --export $user@mellanox.com > $TARGET/release.asc
	#sudo -u ceph-release gpg --armor --export 'sashakot <sashakot@mellanox.com>' > $TARGET/release.asc
}

create_release
